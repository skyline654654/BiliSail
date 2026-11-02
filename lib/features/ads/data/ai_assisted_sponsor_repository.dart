import '../../../domain/request_cancellation.dart';
import '../../../domain/video.dart';
import '../../playback/domain/sponsor_repository.dart';
import '../domain/ad_policy.dart';
import '../domain/ad_segment.dart';
import '../domain/ad_signal_source.dart';
import '../domain/airstrike_detector.dart';

/// Adds on-device advertisement detection on top of the crowd-sourced data.
///
/// The existing playback chain keeps sole ownership of skip state: this class is
/// a decorator, so AI-detected spans simply arrive as additional
/// [SponsorSegment]s and reuse the already-shipped manual/automatic skip UI.
///
/// Crowd data wins. An AI span that overlaps a crowd-sourced one is dropped
/// instead of being merged, because the community segment has a human-verified
/// range and the AI range is only an inference from viewer chatter.
final class AiAssistedSponsorRepository implements SponsorRepository {
  const AiAssistedSponsorRepository({
    required this.inner,
    required this.signalSource,
    this.policy = const AdPolicy(),
    this.detector = const AirstrikeDetector(),
  });

  final SponsorRepository inner;
  final AdSignalSource signalSource;
  final AdPolicy policy;
  final AirstrikeDetector detector;

  /// 6 minutes per danmaku segment; four segments cover the opening 24 minutes,
  /// which is where in-video advertisements actually live.
  static const int scannedSegments = 4;

  static const String _category = 'sponsor';

  @override
  Future<List<SponsorSegment>> segments(
    VideoId video,
    String cid, {
    required List<String> categories,
    required RequestCancellation cancellation,
  }) async {
    final base = await inner.segments(
      video,
      cid,
      categories: categories,
      cancellation: cancellation,
    );
    if (!_enabled(categories) || cancellation.isCancelled) return base;
    final signals = await signalSource.danmaku(
      video,
      cid,
      segmentCount: scannedSegments,
      cancellation: cancellation,
    );
    if (cancellation.isCancelled || signals.isEmpty) return base;

    final duration = _evidenceDuration(signals);
    if (duration <= Duration.zero) return base;

    final detected = detector.detect(
      [for (final signal in signals) (position: signal.position, text: signal.text)],
      videoDuration: duration,
    );
    if (detected.isEmpty) return base;

    final added = <SponsorSegment>[];
    for (final segment in detected) {
      if (!policy.allows(segment)) continue;
      if (base.any((item) => _overlaps(item, segment))) continue;
      added.add(_toSponsorSegment(segment, duration, base));
    }
    if (added.isEmpty) return base;
    return List.unmodifiable([...base, ...added]);
  }

  bool _enabled(List<String> categories) =>
      policy.skipMode != AdSkipMode.disabled &&
      policy.sources.contains(AdSource.danmakuAirstrike) &&
      // The categories list is what the playback settings ask the community API
      // for; the AI span reuses the「赞助广告」slot, so it is only offered when
      // that slot is enabled.
      (categories.isEmpty || categories.contains(_category));

  /// The detector needs a bounded timeline. The furthest danmaku position is a
  /// cheap, honest upper bound: it can only make detected spans shorter, never
  /// longer than the real video.
  static Duration _evidenceDuration(List<AdDanmakuSignal> signals) {
    var furthest = Duration.zero;
    for (final signal in signals) {
      if (signal.position > furthest) furthest = signal.position;
    }
    // One segment is 6 minutes; allow a span to reach the end of the last
    // segment we actually scanned.
    final window = Duration(minutes: 6 * scannedSegments);
    return furthest < window ? furthest : window;
  }

  static bool _overlaps(SponsorSegment item, AdSegment segment) =>
      item.start < segment.end && segment.start < item.end;

  static SponsorSegment _toSponsorSegment(
    AdSegment segment,
    Duration duration,
    List<SponsorSegment> base,
  ) => SponsorSegment(
    id: 'ai-${segment.start.inMilliseconds}-${segment.end.inMilliseconds}',
    category: _category,
    start: segment.start,
    end: segment.end,
    // Keep the crowd-sourced duration when the video already carries one, so
    // `SponsorSegment.matches` does not reject the AI span for a stale length.
    videoDuration: base.isEmpty ? duration : base.first.videoDuration,
  );
}
