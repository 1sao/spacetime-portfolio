// Builds the performance tour (`bench/tour.dart`), runs it in Chrome (with
// the frame rate unlocked, unless --vsync), and prints the start-up times
// and the frame times of each segment.
//
// The setups take turns, so a busy moment of the machine hits each of them
// alike. Each tour runs in a new Chrome, so nothing is cached.
//
// Usage: dart run tool/measure_performance.dart [--runs 3] [--no-build]
//          [--compiler wasm|js] [--isolated] [--vsync] [--pixel-ratio 2]
//          [--download <Mbit/s>] [--latency <ms>] [--setup <query>]...
//          [--segments <names>] [--settle <s>] [--dwell <s>] [--headed]
//          [--chrome <path>] [--update-baseline]

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:args/args.dart';
import 'package:puppeteer/protocol/network.dart' show NetworkConditions;
import 'package:puppeteer/puppeteer.dart';
import 'package:shelf/shelf.dart' show Handler;
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

const _tourTimeout = Duration(minutes: 3);

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('runs', defaultsTo: '3', help: 'How many tours to run.')
    ..addFlag('build', defaultsTo: true, help: 'Build the tour first.')
    ..addOption(
      'compiler',
      allowed: ['wasm', 'js'],
      defaultsTo: 'wasm',
      help: 'The build that Chrome runs.',
    )
    ..addFlag(
      'isolated',
      help:
          'Send the headers that make the page cross-origin isolated, so '
          'that the wasm build draws on a thread of its own. Needs --vsync: '
          "the tour cannot unlock that thread's frame rate.",
    )
    ..addFlag(
      'vsync',
      help:
          "Keep Chrome's usual frame rate, and do not wait for the GPU after "
          'each frame, as for a visitor.',
    )
    ..addOption(
      'pixel-ratio',
      defaultsTo: '2',
      help: 'The device pixel ratio of the 1280x800 window.',
    )
    ..addOption(
      'download',
      help: 'The download speed, in Mbit/s. Not limited by default.',
    )
    ..addOption(
      'latency',
      defaultsTo: '0',
      help: 'The time added to each request, in ms.',
    )
    ..addMultiOption(
      'setup',
      splitCommas: false,
      help: 'A URL query for the app, such as lensing=12. One table each.',
    )
    ..addOption(
      'segments',
      help: 'The segments to measure, separated by commas. All by default.',
    )
    ..addOption('settle', help: 'Seconds from a change to its segment.')
    ..addOption('dwell', help: 'Seconds that each segment measures.')
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
  final compiler = options.option('compiler')!;
  final isIsolated = options.flag('isolated');
  final isVsyncOn = options.flag('vsync');
  final buildDir = '$_buildDir/$compiler';
  final runs = int.tryParse(options.option('runs')!);
  final pixelRatio = double.tryParse(options.option('pixel-ratio')!);
  final download = options.option('download');
  final downloadMbps = download == null ? null : double.tryParse(download);
  final latencyMs = double.tryParse(options.option('latency')!);
  final setups = [...options.multiOption('setup')];
  if (setups.isEmpty) setups.add('');
  if (options.flag('help') ||
      runs == null ||
      runs < 1 ||
      !(pixelRatio != null && pixelRatio.isFinite && pixelRatio > 0) ||
      (download != null &&
          !(downloadMbps != null &&
              downloadMbps.isFinite &&
              downloadMbps > 0)) ||
      !(latencyMs != null && latencyMs.isFinite && latencyMs >= 0) ||
      (isIsolated && !isVsyncOn) ||
      (options.flag('update-baseline') && setups.length > 1)) {
    stdout.writeln(parser.usage);
    if (!options.flag('help')) exitCode = _usageError;
    return;
  }

  Directory.current = File.fromUri(Platform.script).parent.parent;

  if (options.flag('build')) await _build(compiler, buildDir);

  final tourQuery = [
    for (final name in ['segments', 'settle', 'dwell'])
      if (options.option(name) case final value?)
        '$name=${Uri.encodeQueryComponent(value)}',
    if (isVsyncOn) 'wait=0',
  ];
  final network = downloadMbps != null || latencyMs > 0
      ? NetworkConditions(
          urlPattern: '',
          latency: latencyMs,
          downloadThroughput: downloadMbps == null
              ? -1
              : downloadMbps * 1e6 / 8,
          uploadThroughput: -1,
        )
      : null;

  Future<Browser> launchChrome() => puppeteer.launch(
    executablePath: options.option('chrome'),
    headless: !options.flag('headed'),
    defaultViewport: DeviceViewport(
      width: 1280,
      height: 800,
      deviceScaleFactor: pixelRatio,
    ),
    args: [
      if (!isVsyncOn) ...['--disable-gpu-vsync', '--disable-frame-rate-limit'],
    ],
  );

  final String renderer;
  final String chrome;
  final probe = await launchChrome();
  try {
    renderer = await probe.renderer;
    chrome = await probe.version;
  } finally {
    await probe.close();
  }
  if (renderer.contains('SwiftShader')) {
    throw StateError('Chrome draws without the GPU: $renderer');
  }

  final handler = _gzipHandler(buildDir);
  final server = await shelf_io.serve(
    isIsolated ? handler.isolated : handler,
    InternetAddress.loopbackIPv4,
    0,
  );
  final tours = [for (final _ in setups) <Map<String, Object?>>[]];
  try {
    final url = 'http://${server.address.host}:${server.port}/';
    for (var run = 1; run <= runs; run++) {
      for (final (index, setup) in setups.indexed) {
        stdout.writeln(
          'Tour $run of $runs${setup.isEmpty ? '' : ', $setup'}...',
        );
        final query = [if (setup.isNotEmpty) setup, ...tourQuery].join('&');
        final browser = await launchChrome();
        try {
          final tour = await browser.runTour(
            query.isEmpty ? url : '$url?$query',
            network: network,
          );
          if (tour['isWasm'] case final bool isWasm
              when isWasm != (compiler == 'wasm')) {
            (tour['problems']! as List<Object?>).add(
              'It ran the ${isWasm ? 'wasm' : 'js'} build.',
            );
          }
          tours[index].add(tour);
        } finally {
          await browser.close();
        }
      }
    }
  } finally {
    await server.close();
  }
  final date = DateTime.now().toIso8601String();
  final allResults = [
    for (final (index, setup) in setups.indexed)
      {
        'date': date,
        'setup': setup,
        'compiler': compiler,
        'isolated': isIsolated,
        'vsync': isVsyncOn,
        'pixelRatio': pixelRatio,
        'downloadMbps': downloadMbps,
        'latencyMs': latencyMs,
        'chrome': chrome,
        'renderer': renderer,
        'tours': tours[index],
      },
  ];

  final baselineFile = File(_baselinePath);
  final baseline = await baselineFile.exists()
      ? jsonDecode(await baselineFile.readAsString()) as Map<String, Object?>
      : null;
  var hasProblems = false;
  for (final (index, results) in allResults.indexed) {
    final setup = results['setup']! as String;
    final resultsFile = File(
      '$_resultsDir/${results['date']}-$index.json'.replaceAll(':', '-'),
    );
    await resultsFile.create(recursive: true);
    await resultsFile.writeAsString(results.prettyJson);
    stdout
      ..writeln()
      ..writeln('=== ${setup.isEmpty ? 'default' : setup}')
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
      hasProblems = true;
    }
  }
  if (hasProblems) {
    exitCode = 1;
    return;
  }

  if (options.flag('update-baseline')) {
    final results = allResults.single;
    await baselineFile.writeAsString(results.prettyJson);
    stdout.writeln('Baseline updated: $_baselinePath');
  }
}

Future<void> _build(String compiler, String buildDir) async {
  stdout.writeln('Building the tour ($compiler)...');
  final build = await Process.start('flutter', [
    'build',
    'web',
    '--release',
    if (compiler == 'wasm') '--wasm',
    '--target',
    'bench/tour.dart',
    '--output',
    Directory(buildDir).absolute.path,
    '--no-web-resources-cdn',
  ], mode: ProcessStartMode.inheritStdio);
  if (await build.exitCode != 0) {
    throw StateError('The build failed.');
  }
}

String _report(Map<String, Object?> results, Map<String, Object?>? baseline) {
  final lines = <String>[];
  if (baseline != null) {
    for (final key in [
      'compiler',
      'isolated',
      'vsync',
      'pixelRatio',
      'chrome',
      'renderer',
    ]) {
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
      'mean ms',
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
        tours.map((stats) => stats.meanMs).spread(),
        tours.map((stats) => stats.medianMs).spread(),
        tours.map((stats) => stats.p90Ms).spread(),
        tours.map((stats) => stats.worstMs).spread(),
        tours.map((stats) => stats.slowFrames).spread(digits: 0),
        if (baseline != null)
          tours.changeFrom(baselineSegments[segment] ?? const []),
      ],
  ];
  lines.addAll(rows.tableLines);

  final startups = results.startups;
  if (startups.isNotEmpty) {
    String spreadOf(double? Function(StartupStats startup) step) {
      final values = startups.map(step).nonNulls;
      return values.isEmpty ? '-' : values.spread(digits: 0);
    }

    lines
      ..add('')
      ..addAll(
        [
          ['start-up', 'ms'],
          ['Dart starts', spreadOf((startup) => startup.dartMs)],
          ['first frame', spreadOf((startup) => startup.firstFrameMs)],
          ['scene drawn', spreadOf((startup) => startup.sceneMs)],
          [
            'downloaded, MB',
            startups.map((startup) => startup.downloadedBytes / 1e6).spread(),
          ],
        ].tableLines,
      );
  }
  return lines.join('\n');
}

/// Sends each file gzipped, as a web host does. The files are compressed
/// before the tours, so compression does not add to the start-up times.
Handler _gzipHandler(String dir) {
  final staticHandler = createStaticHandler(dir, defaultDocument: 'index.html');
  final compressed = {
    for (final file in Directory(
      dir,
    ).listSync(recursive: true).whereType<File>())
      file.path.substring(dir.length + 1): gzip.encode(file.readAsBytesSync()),
  };
  return (request) async {
    final response = await staticHandler(request);
    final path = request.url.pathSegments.join('/');
    final body = compressed[path.isEmpty ? 'index.html' : path];
    if (response.statusCode != HttpStatus.ok || body == null) return response;
    return response.change(body: body, headers: {'content-encoding': 'gzip'});
  };
}

extension on List<List<String>> {
  List<String> get tableLines {
    final widths = [
      for (var column = 0; column < first.length; column++)
        map((row) => row[column].length).reduce(math.max),
    ];
    return [
      for (final row in this)
        [
          for (final (column, cell) in row.indexed)
            column == 0
                ? cell.padRight(widths[column])
                : cell.padLeft(widths[column]),
        ].join('  '),
    ];
  }
}

extension on Handler {
  /// Only a cross-origin isolated page can share memory between threads.
  Handler get isolated =>
      (request) async => (await this(request)).change(
        headers: {
          'Cross-Origin-Opener-Policy': 'same-origin',
          'Cross-Origin-Embedder-Policy': 'require-corp',
        },
      );
}

extension on Browser {
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

  Future<Map<String, Object?>> runTour(
    String url, {
    required NetworkConditions? network,
  }) async {
    final page = await newPage();
    try {
      if (network != null) {
        await page.devTools.network.emulateNetworkConditionsByRule([network]);
      }
      // Listens before the page loads, so the result line cannot come first.
      // ignore() stops an unhandled error if goto throws and the page closes.
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
  String spread({int digits = 2}) {
    final sorted = map((value) => value.toDouble()).toList()..sort();
    String show(double value) => value.toStringAsFixed(digits);
    if (sorted.length == 1) return show(sorted.single);
    return '${show(sorted.median)} '
        '(${show(sorted.first)}-${show(sorted.last)})';
  }
}

extension on List<SegmentStats> {
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

  List<Map<String, Object?>> get validTours => [
    for (final tour in tours)
      if ((tour['problems']! as List<Object?>).isEmpty) tour,
  ];

  List<StartupStats> get startups => [
    for (final tour in validTours)
      StartupStats.fromJson(tour['startup']! as Map<String, Object?>),
  ];

  Map<String, List<SegmentStats>> get segments {
    final segments = <String, List<SegmentStats>>{};
    for (final tour in validTours) {
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
