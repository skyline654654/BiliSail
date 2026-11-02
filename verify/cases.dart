import 'dart:io';

import '../lib/features/ads/domain/airstrike_detector.dart';

const _cases = <({String name, int durationMs, List<int> boundariesMs})>[
  (name: 'typical_short_ad', durationMs: 600000, boundariesMs: [180000, 180000, 180000]),
  (name: 'below_vote_threshold', durationMs: 600000, boundariesMs: [180000]),
  (name: 'clustered_votes', durationMs: 900000, boundariesMs: [60000, 63000, 66000, 420000, 422000]),
  (name: 'too_short_segment', durationMs: 600000, boundariesMs: [1000, 1000]),
  (name: 'merged_close_boundaries', durationMs: 1200000, boundariesMs: [200000, 200000, 205000, 205000]),
  (name: 'beyond_duration', durationMs: 300000, boundariesMs: [900000, 900000]),
  (name: 'two_ads', durationMs: 1500000, boundariesMs: [300000, 300000, 900000, 900000]),
  (name: 'empty', durationMs: 600000, boundariesMs: []),
];

void main() {
  const detector = AirstrikeDetector();
  for (final item in _cases) {
    final duration = Duration(milliseconds: item.durationMs);
    final boundaries = detector.clusterBoundaries(
      [for (final ms in item.boundariesMs) Duration(milliseconds: ms)],
      videoDuration: duration,
    );
    final segments = detector.segmentsFromBoundaries(
      boundaries,
      videoDuration: duration,
    );
    stdout.writeln('${item.name} | ${segments.map((s) => '${s.start.inMilliseconds}-${s.end.inMilliseconds}@${(s.confidence * 1000).round()}').join(',')}');
  }
}