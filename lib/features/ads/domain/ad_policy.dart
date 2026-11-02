import 'ad_segment.dart';

/// How aggressive the in-video advertisement skipping should be.
enum AdSkipMode {
  /// Never skip and never offer a skip action.
  disabled('关闭'),

  /// Show the skip action when a segment is reached; the user taps it.
  manual('手动跳过'),

  /// Jump over every segment whose confidence clears the threshold.
  automatic('自动跳过');

  const AdSkipMode(this.label);

  final String label;
}

/// User-facing policy for advertisement blocking.
///
/// Kept as a plain value object in the domain so controllers, the settings
/// repository and tests share one source of truth; persistence lives in the
/// settings layer like every other preference.
final class AdPolicy {
  const AdPolicy({
    this.blockFeedAds = true,
    this.skipMode = AdSkipMode.manual,
    this.minimumConfidence = 0.6,
    this.sources = const {
      AdSource.sponsorBlock,
      AdSource.danmakuAirstrike,
      AdSource.description,
    },
    this.blockDanmakuAds = true,
  });

  /// Removes advertising cards from the feed, search results and the dynamic
  /// list instead of only dimming them.
  final bool blockFeedAds;

  final AdSkipMode skipMode;

  /// Local inference below this confidence is reported but never auto-skipped.
  final double minimumConfidence;

  /// Evidence sources allowed to contribute segments.
  final Set<AdSource> sources;

  /// Hides danmaku that carry advertising timecodes or keywords.
  final bool blockDanmakuAds;

  bool allows(AdSegment segment) =>
      sources.contains(segment.source) &&
      segment.confidence >= minimumConfidence;

  /// Segments eligible for an automatic jump at [position].
  AdSegment? skipTargetAt(List<AdSegment> segments, Duration position) {
    if (skipMode == AdSkipMode.disabled) return null;
    for (final segment in segments) {
      if (!allows(segment) || !segment.contains(position)) continue;
      if (skipMode == AdSkipMode.automatic) return segment;
      // Manual mode offers the same action; the UI decides whether to show it.
      return segment;
    }
    return null;
  }

  AdPolicy copyWith({
    bool? blockFeedAds,
    AdSkipMode? skipMode,
    double? minimumConfidence,
    Set<AdSource>? sources,
    bool? blockDanmakuAds,
  }) => AdPolicy(
    blockFeedAds: blockFeedAds ?? this.blockFeedAds,
    skipMode: skipMode ?? this.skipMode,
    minimumConfidence: minimumConfidence ?? this.minimumConfidence,
    sources: sources ?? this.sources,
    blockDanmakuAds: blockDanmakuAds ?? this.blockDanmakuAds,
  );
}
