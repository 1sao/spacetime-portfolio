import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../bench/src/frame_recorder.dart';
import '../../bench/src/frame_stats.dart';

void main() {
  test('the median and the p90 are frame times at their nearest rank', () {
    // 1 to 10 ms, shuffled.
    final stats = SegmentStats.of([7, 3, 10, 1, 9, 2, 8, 4, 6, 5]);
    expect(stats.frames, 10);
    expect(stats.medianMs, 5);
    expect(stats.p90Ms, 9);
    expect(stats.worstMs, 10);
    // 9 and 10 ms are over 8.33 ms.
    expect(stats.slowFrames, 2);
  });

  test('one frame is its own median, p90 and worst', () {
    final stats = SegmentStats.of([4]);
    expect([stats.medianMs, stats.p90Ms, stats.worstMs], [4, 4, 4]);
  });

  test('the statistics survive JSON, with whole numbers written as ints', () {
    final stats = SegmentStats.of([1, 2, 12]);
    final json = jsonDecode(jsonEncode(stats.toJson())) as Map<String, Object?>;
    // dart2js writes a whole double without a fraction, as here.
    json['medianMs'] = 2;
    final copy = SegmentStats.fromJson(json);
    expect(copy.toJson(), stats.toJson());
  });

  group('FrameRecorder', () {
    Duration ms(int milliseconds) => Duration(milliseconds: milliseconds);

    test('gives a frame time to the segment of the frame that ends it, and '
        'pools a segment that starts again', () {
      final recorder = FrameRecorder()
        // Not measured: no segment yet.
        ..recordFrame(ms(0))
        ..recordFrame(ms(5))
        ..startSegment('rest /')
        ..recordFrame(ms(7))
        ..recordFrame(ms(10))
        ..startSegment('fly / -> /a')
        ..recordFrame(ms(14))
        ..startSegment('rest /')
        ..recordFrame(ms(20))
        ..stop()
        ..recordFrame(ms(100));
      final stats = recorder.stats;
      expect(stats.keys, ['rest /', 'fly / -> /a']);
      expect(stats['rest /']!.frames, 3);
      expect(stats['rest /']!.worstMs, 6);
      expect(stats['fly / -> /a']!.medianMs, 4);
      expect(recorder.problems, isEmpty);
    });

    test('finds a segment with no frames', () {
      final recorder = FrameRecorder()..startSegment('rest /');
      expect(recorder.problems, ['No frames in "rest /".']);
    });

    test('finds the signs of frames queued ahead of the GPU', () {
      final recorder = FrameRecorder()..startSegment('rest /');
      var time = Duration.zero;
      for (var frame = 0; frame < 10; frame++) {
        recorder.recordFrame(time);
        time += const Duration(microseconds: 100);
      }
      recorder.recordFrame(time + const Duration(seconds: 2));
      expect(recorder.problems, hasLength(2));
    });
  });
}
