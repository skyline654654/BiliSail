import 'ad_segment.dart';

/// Parses「空降」danmaku into advertisement boundaries.
///
/// Viewers mark the end of an in-video advertisement by posting coordinates
/// (「空降 03:45」,「空降成功 1:02」,「广告结束 02:10」). A cluster of those
/// coordinates inside a short window is strong evidence that the advertisement
/// ends there, so the detector turns each cluster into a span that starts at the
/// beginning of the video or at the previous cluster's end.
///
/// Only text that carries an explicit timecode can mark a boundary; plain
/// chatter is ignored, which keeps false positives low. All parsing is pure and
/// bounded so it is safe to run for every loaded danmaku batch.
final class AirstrikeDetector {
  const AirstrikeDetector({
    this.minimumVotes = 2,
    this.clusterWindow = const Duration(seconds: 12),
    this.minimumSegment = const Duration(seconds: 3),
    this.maximumSegment = const Duration(minutes: 6),
    this.maximumCandidates = 4000,
  });

  /// How many distinct timecodes must agree before a boundary is accepted.
  final int minimumVotes;

  /// Boundaries closer than this are treated as one cluster.
  final Duration clusterWindow;

  /// Spans shorter than this are noise; longer than [maximumSegment] suggests
  /// the cluster marked the end of a whole section instead of an advertisement.
  final Duration minimumSegment;
  final Duration maximumSegment;

  /// Hard cap so a hostile or huge danmaku batch cannot blow up the analyser.
  final int maximumCandidates;

  /// Recognises the handful of phrasings viewers actually use.
  static final RegExp _keyword = RegExp(r'空降|广告|恰饭|跳过|正片开始|前方高能');

  /// Accepts `mm:ss`, `m:ss`, `hh:mm:ss` and optional half/full width colons.
  static final RegExp _timecode = RegExp(r'(?:\d{1,2}[:：])?\d{1,2}[:：]\d{1,2}');

  /// Returns detected spans for one video, ordered by start.
  ///
  /// [danmaku] is `(videoPosition, text)`; callers pass the resolved position
  /// rather than the wall-clock send time so the analyser never needs a clock.
  List<AdSegment> detect(
    Iterable<({Duration position, String text})> danmaku, {
    required Duration videoDuration,
  }) {
    if (videoDuration <= Duration.zero) return const [];
    final votes = <Duration, int>{};
    var inspected = 0;
    for (final item in danmaku) {
      if (inspected >= maximumCandidates) break;
      inspected++;
      if (!_keyword.hasMatch(item.text)) continue;
      final match = _timecode.firstMatch(item.text);
      if (match == null) continue;
      final parsed = _parseTimecode(match.group(0)!);
      if (parsed == null || parsed >= videoDuration) continue;
      votes.update(parsed, (count) => count + 1, ifAbsent: () => 1);
    }
    if (votes.isEmpty) return const [];

    // Collapse votes that land within the cluster window of each other.
    final ordered = votes.keys.toList()..sort();
    final clusters = <({Duration at, int votes})>[];
    for (final at in ordered) {
      final previous = clusters.isEmpty ? null : clusters.last;
      if (previous != null && at - previous.at <= clusterWindow) {
        clusters[clusters.length - 1] = (
          at: previous.at,
          votes: previous.votes + votes[at]!,
        );
      } else {
        clusters.add((at: at, votes: votes[at]!));
      }
    }

    final boundaries = [
      for (final cluster in clusters)
        if (cluster.votes >= minimumVotes) cluster.at,
    ];
    if (boundaries.isEmpty) return const [];

    // The advertisement runs from the previous boundary (or the video start)
    // to the cluster that says "the real content starts here".
    final segments = <AdSegment>[];
    var cursor = Duration.zero;
    for (final boundary in boundaries) {
      final length = boundary - cursor;
      if (length >= minimumSegment && length <= maximumSegment) {
        segments.add(
          AdSegment(
            start: cursor,
            end: boundary,
            source: AdSource.danmakuAirstrike,
            confidence: _confidenceFor(length),
            label: '视频内广告',
          ),
        );
      }
      cursor = boundary;
    }
    return mergeAdSegments(segments);
  }

  /// Longer agreements are more trustworthy: a single timecode can be a joke,
  /// but thousands of viewers posting the same coordinate is a real boundary.
  double _confidenceFor(Duration length) {
    final seconds = length.inSeconds.clamp(minimumSegment.inSeconds, 600);
    // 0.55 at the shortest accepted span, approaching 0.95 at ten minutes.
    return (0.55 + seconds / 600 * 0.4).clamp(0.0, 0.95);
  }

  static Duration? _parseTimecode(String raw) {
    final parts = raw.split(RegExp(r'[:：]'));
    if (parts.length < 2 || parts.length > 3) return null;
    final numbers = <int>[];
    for (final part in parts) {
      final value = int.tryParse(part);
      if (value == null || value < 0) return null;
      numbers.add(value);
    }
    final seconds = numbers.removeLast();
    final minutes = numbers.removeLast();
    final hours = numbers.isEmpty ? 0 : numbers.removeLast();
    if (seconds >= 60 || minutes >= 60) return null;
    return Duration(hours: hours, minutes: minutes, seconds: seconds);
  }
}
