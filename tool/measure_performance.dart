// Builds the performance tour (`bench/tour.dart`), runs it in Chrome with
// the frame rate unlocked, and prints the frame times of each segment.
//
// Usage: dart run tool/measure_performance.dart [--runs 3] [--no-build]
//          [--headed] [--chrome <path>] [--update-baseline]

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:args/args.dart';
import 'package:puppeteer/puppeteer.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';

import '../bench/src/frame_stats.dart';

const _buildDir = 'build/perf_web';
const _resultsDir = 'build/perf';
const _baselinePath = 'bench/baseline.json';

/// The exit code for wrong arguments (`EX_USAGE` in `sysexits.h`).
const _usageError = 64;
const _macChrome =
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';

/// The longest time that one tour can take. A tour takes about 10 s.
const _tourTimeout = Duration(minutes: 3);

const _viewport = DeviceViewport(
  width: 1280,
  height: 800,
  deviceScaleFactor: 2,
);

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('runs', defaultsTo: '3', help: 'How many tours to run.')
    ..addFlag('build', defaultsTo: true, help: 'Build the tour first.')
    ..addFlag('headed', help: 'Show the Chrome window.')
    ..addOption(
      'chrome',
      defaultsTo: _macChrome,
      help: 'The Chrome binary. The default is the path on macOS.',
    )
    ..addFlag(
      'update-baseline',
      negatable: false,
      help: 'Write the results to $_baselinePath.',
    )
    ..addFlag('help', abbr: 'h', negatable: false);
  final options = parser.parse(arguments);
  final runs = int.tryParse(options.option('runs')!);
  if (options.flag('help') || runs == null || runs < 1) {
    stdout.writeln(parser.usage);
    if (!options.flag('help')) exitCode = _usageError;
    return;
  }

  Directory.current = File.fromUri(Platform.script).parent.parent;

  if (options.flag('build')) await _build();

  final server = await shelf_io.serve(
    createStaticHandler(_buildDir, defaultDocument: 'index.html'),
    InternetAddress.loopbackIPv4,
    0,
  );
  final Map<String, Object?> results;
  try {
    final browser = await puppeteer.launch(
      executablePath: options.option('chrome'),
      headless: !options.flag('headed'),
      defaultViewport: _viewport,
      args: ['--disable-gpu-vsync', '--disable-frame-rate-limit'],
    );
    try {
      final renderer = await browser.renderer;
      if (renderer.contains('SwiftShader')) {
        throw StateError('Chrome draws without the GPU: $renderer');
      }
      final url = 'http://${server.address.host}:${server.port}/';
      final tours = <Map<String, Object?>>[];
      for (var run = 1; run <= runs; run++) {
        stdout.writeln('Tour $run of $runs...');
        tours.add(await browser.runTour(url));
      }
      results = {
        'date': DateTime.now().toIso8601String(),
        'chrome': await browser.version,
        'renderer': renderer,
        'tours': tours,
      };
    } finally {
      await browser.close();
    }
  } finally {
    await server.close();
  }

  final resultsFile = File(
    '$_resultsDir/${results['date']}.json'.replaceAll(':', '-'),
  );
  await resultsFile.create(recursive: true);
  await resultsFile.writeAsString(results.prettyJson);

  final baselineFile = File(_baselinePath);
  final baseline = await baselineFile.exists()
      ? jsonDecode(await baselineFile.readAsString()) as Map<String, Object?>
      : null;
  stdout
    ..writeln()
    ..writeln(_report(results, baseline))
    ..writeln('Results: ${resultsFile.path}');

  final problems = [
    for (final (index, tour) in results.tours.indexed)
      for (final problem in tour['problems']! as List<Object?>)
        'Tour ${index + 1}: $problem',
  ];
  if (problems.isNotEmpty) {
    stderr.writeln(
      'Not valid, left out of the table:\n  ${problems.join('\n  ')}',
    );
    exitCode = 1;
    return;
  }

  if (options.flag('update-baseline')) {
    await baselineFile.writeAsString(results.prettyJson);
    stdout.writeln('Baseline updated: $_baselinePath');
  }
}

Future<void> _build() async {
  stdout.writeln('Building the tour...');
  final build = await Process.start('flutter', [
    'build',
    'web',
    '--release',
    '--target',
    'bench/tour.dart',
    '--output',
    Directory(_buildDir).absolute.path,
    '--no-web-resources-cdn',
  ], mode: ProcessStartMode.inheritStdio);
  if (await build.exitCode != 0) {
    throw StateError('The build failed.');
  }
}

/// A table of each segment's statistics over the valid tours: the median
/// over the tours, and the smallest and largest value in brackets. With a
/// [baseline], the change of the median and the p90 against it.
String _report(Map<String, Object?> results, Map<String, Object?>? baseline) {
  final lines = <String>[];
  if (baseline != null) {
    for (final key in ['chrome', 'renderer']) {
      if (baseline[key] != results[key]) {
        lines.add(
          'Warning: the baseline has $key "${baseline[key]}", '
          'not "${results[key]}".',
        );
      }
    }
  }

  final segments = results.segments;
  if (segments.isEmpty) return [...lines, 'No valid tours.'].join('\n');
  final baselineSegments = baseline?.segments ?? const {};
  final rows = [
    [
      'segment',
      'frames',
      'median ms',
      'p90 ms',
      'worst ms',
      'slow frames',
      if (baseline != null) 'vs baseline',
    ],
    for (final MapEntry(key: segment, value: tours) in segments.entries)
      [
        segment,
        tours.map((stats) => stats.frames).spread(digits: 0),
        tours.map((stats) => stats.medianMs).spread(),
        tours.map((stats) => stats.p90Ms).spread(),
        tours.map((stats) => stats.worstMs).spread(),
        tours.map((stats) => stats.slowFrames).spread(digits: 0),
        if (baseline != null)
          tours.changeFrom(baselineSegments[segment] ?? const []),
      ],
  ];
  final widths = [
    for (var column = 0; column < rows.first.length; column++)
      rows.map((row) => row[column].length).reduce(math.max),
  ];
  for (final row in rows) {
    lines.add(
      [
        for (final (column, cell) in row.indexed)
          column == 0
              ? cell.padRight(widths[column])
              : cell.padLeft(widths[column]),
      ].join('  '),
    );
  }
  return lines.join('\n');
}

extension on Browser {
  /// The name of the GPU that WebGL draws with, such as
  /// "ANGLE (Apple, ANGLE Metal Renderer: Apple M3 Pro, ...)".
  Future<String> get renderer async {
    final page = await newPage();
    try {
      return await page.evaluate<String>('''() => {
        const gl = document.createElement('canvas').getContext('webgl2');
        if (!gl) return 'no WebGL2';
        const info = gl.getExtension('WEBGL_debug_renderer_info');
        return gl.getParameter(info ? info.UNMASKED_RENDERER_WEBGL : gl.RENDERER);
      }''');
    } finally {
      await page.close();
    }
  }

  /// Runs the tour at [url] in a new page. A tour that does not finish in
  /// time gives a result with a problem.
  Future<Map<String, Object?>> runTour(String url) async {
    final page = await newPage();
    try {
      // Listens before the page loads, so the result line cannot come first.
      // ignore(): if goto throws, the page closes and this future fails
      // unawaited.
      final result = page.tourResult..ignore();
      await page.goto(url);
      return await result;
    } on TimeoutException {
      return {
        'problems': ['It did not finish within $_tourTimeout.'],
      };
    } finally {
      await page.close();
    }
  }
}

extension on Page {
  /// The result that the tour in this page prints to the console.
  Future<Map<String, Object?>> get tourResult => onConsole
      .map((message) => message.text ?? '')
      .firstWhere((text) => text.startsWith(resultPrefix))
      .then(
        (text) =>
            jsonDecode(text.substring(resultPrefix.length))
                as Map<String, Object?>,
      )
      .timeout(_tourTimeout);
}

extension on Iterable<num> {
  /// The median, with the smallest and the largest value in brackets.
  String spread({int digits = 2}) {
    final sorted = map((value) => value.toDouble()).toList()..sort();
    String show(double value) => value.toStringAsFixed(digits);
    if (sorted.length == 1) return show(sorted.single);
    return '${show(sorted.median)} '
        '(${show(sorted.first)}-${show(sorted.last)})';
  }
}

extension on List<SegmentStats> {
  /// The change of the median frame time and of the p90 from [baseline], in
  /// percent of the baseline. Each is the median over the tours.
  String changeFrom(List<SegmentStats> baseline) {
    if (baseline.isEmpty) return 'new';
    String percent(double Function(SegmentStats stats) stat) {
      double medianOf(List<SegmentStats> tours) =>
          (tours.map(stat).toList()..sort()).median;
      final change = (medianOf(this) / medianOf(baseline) - 1) * 100;
      return '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)} %';
    }

    return '${percent((stats) => stats.medianMs)}, '
        '${percent((stats) => stats.p90Ms)}';
  }
}

extension on Map<String, Object?> {
  String get prettyJson =>
      '${const JsonEncoder.withIndent('  ').convert(this)}\n';

  List<Map<String, Object?>> get tours => [
    for (final tour in this['tours']! as List<Object?>)
      tour! as Map<String, Object?>,
  ];

  /// The statistics of each segment, one for each valid tour, in the order
  /// of the first valid tour.
  Map<String, List<SegmentStats>> get segments {
    final segments = <String, List<SegmentStats>>{};
    for (final tour in tours) {
      if ((tour['problems']! as List<Object?>).isNotEmpty) continue;
      final tourSegments = tour['segments']! as Map<String, Object?>;
      for (final MapEntry(key: segment, value: stats) in tourSegments.entries) {
        segments
            .putIfAbsent(segment, () => [])
            .add(SegmentStats.fromJson(stats! as Map<String, Object?>));
      }
    }
    return segments;
  }
}
