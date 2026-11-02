/// Where a detected in-video advertisement came from.
///
/// Sources are ranked so a merge can prefer the strongest evidence when two
/// sources disagree about the same span. Crowd-sourced data wins over local
/// inference, and local inference never shortens a crowd-sourced segment.
enum AdSource {
  /// BilibiliSponsorBlock (bsbsb.top) crowd-sourced skip segments.
  sponsorBlock(4, '社区标记'),

  /// Danmaku「空降」coordinates posted by viewers, which mark the end of a
  /// in-video advertisement or the start of the real content.
  danmakuAirstrike(3, '弹幕空降'),

  /// Keywords in the video description or the creator's own disclaimer.
  description(2, '简介线索'),

  /// An on-device model (Cangjie classifier or the platform vision pipeline).
  onDeviceModel(1, '本地识别');

  const AdSource(this.priority, this.label);

  /// Higher wins when merging overlapping spans.
  final int priority;
  final String label;
}

/// One detected advertising span inside a video.
final class AdSegment {
  const AdSegment({
    required this.start,
    required this.end,
    required this.source,
    required this.confidence,
    this.label,
  }) : assert(start >= Duration.zero, 'segment start must not be negative'),
       assert(end > start, 'segment end must be after its start');

  final Duration start;
  final Duration end;

  final AdSource source;

  /// 0..1. Crowd-sourced segments start at 1.0; local inference must reach the
  /// configured threshold before it is offered as a skip action.
  final double confidence;

  /// Human-readable category shown on the skip button, e.g.「赞助广告」.
  final String? label;

  Duration get length => end - start;

  bool contains(Duration position) => position >= start && position < end;

  /// Whether this span and [other] overlap at all.
  bool overlaps(AdSegment other) => start < other.end && other.start < end;

  @override
  String toString() =>
      'AdSegment(${source.name} ${start.inSeconds}-${end.inSeconds}s '
      'conf=${confidence.toStringAsFixed(2)})';
}

/// A merge of overlapping or adjacent spans.
///
/// Returns spans ordered by start. Two spans merge when they overlap or when the
/// gap between them is at most [mergeGap]; the merged span keeps the highest
/// priority source and the highest confidence of its members.
List<AdSegment> mergeAdSegments(
  Iterable<AdSegment> segments, {
  Duration mergeGap = const Duration(seconds: 2),
}) {
  final ordered = segments.toList()..sort((a, b) => a.start.compareTo(b.start));
  final merged = <AdSegment>[];
  for (final segment in ordered) {
    if (merged.isEmpty) {
      merged.add(segment);
      continue;
    }
    final previous = merged.last;
    final adjacent = segment.start <= previous.end + mergeGap;
    if (!adjacent) {
      merged.add(segment);
      continue;
    }
    final strongest = segment.source.priority > previous.source.priority
        ? segment
        : previous;
    merged[merged.length - 1] = AdSegment(
      start: previous.start,
      end: segment.end > previous.end ? segment.end : previous.end,
      source: strongest.source,
      confidence: segment.confidence > previous.confidence
          ? segment.confidence
          : previous.confidence,
      label: strongest.label ?? previous.label ?? segment.label,
    );
  }
  return List.unmodifiable(merged);
}

/// The span covering [position], if any.
///
/// Prefers the span with the highest confidence when two merged ranges overlap,
/// which cannot happen after [mergeAdSegments] but can for hand-built lists.
AdSegment? adSegmentAt(List<AdSegment> segments, Duration position) {
  AdSegment? best;
  for (final segment in segments) {
    if (!segment.contains(position)) continue;
    if (best == null || segment.confidence > best.confidence) best = segment;
  }
  return best;
}
