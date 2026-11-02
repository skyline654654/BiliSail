import '../../../domain/request_cancellation.dart';
import '../../../domain/video.dart';

/// One danmaku line placed on the video timeline.
final class AdDanmakuSignal {
  const AdDanmakuSignal({required this.position, required this.text});

  final Duration position;
  final String text;
}

/// Where the on-device advertisement detector reads its evidence from.
///
/// Kept as a port so the detector stays pure: tests feed fixtures, and the data
/// layer decides how much of the danmaku stream is worth downloading.
abstract interface class AdSignalSource {
  /// Reads up to [segmentCount] danmaku segments (6 minutes each) for [cid].
  ///
  /// Implementations must stop early when [cancellation] fires and must never
  /// download more than [segmentCount] segments regardless of video length.
  Future<List<AdDanmakuSignal>> danmaku(
    VideoId video,
    String cid, {
    required int segmentCount,
    required RequestCancellation cancellation,
  });
}
