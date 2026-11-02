import 'package:bili_api/bili_api.dart';

import '../../../core/network/api_requests.dart';
import '../../../domain/request_cancellation.dart';
import '../../../domain/video.dart';
import '../domain/ad_signal_source.dart';

/// Reads danmaku segments through the existing `bili_api` client.
///
/// The scan is bounded by [segmentCount] because the advertisement detector only
/// needs the opening minutes of a video: in-video sponsorships and「空降」
/// boundaries cluster near the start, and downloading a whole two-hour stream of
/// danmaku to find a 30-second clip would be wasteful.
final class ApiAdSignalSource implements AdSignalSource {
  ApiAdSignalSource(this.api, this.requests);

  final BiliApiClient api;
  final ApiRequests requests;

  @override
  Future<List<AdDanmakuSignal>> danmaku(
    VideoId video,
    String cid, {
    required int segmentCount,
    required RequestCancellation cancellation,
  }) => requests.run((context) async {
    final signals = <AdDanmakuSignal>[];
    for (var index = 1; index <= segmentCount; index++) {
      if (context.cancellation.isCancelled) break;
      final items = await api.getDanmakuSegment(cid, index, context: context);
      for (final item in items) {
        // Only moving/scrolling chatter can mark a boundary; the detector
        // re-checks the text anyway, so no filtering is needed here.
        signals.add(
          AdDanmakuSignal(position: item.progress, text: item.content),
        );
      }
      // An empty segment means the video has no more danmaku past this point.
      if (items.isEmpty) break;
    }
    return signals;
  }, cancellation: cancellation);
}
