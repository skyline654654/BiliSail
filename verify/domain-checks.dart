// Domain-level behaviour checks for the adaptation.
//
// Deliberately plain Dart: no flutter_test and no package resolution, so any
// machine with a Dart SDK can run it. Flutter-only layers are covered by the
// app's own test suite once Flutter is available.
//
// Usage: dart run verify/domain-checks.dart
import 'dart:io';

import '../lib/domain/ad_card_classifier.dart';
import '../lib/domain/recommendation_settings.dart';
import '../lib/domain/video.dart';
import '../lib/features/ads/domain/ad_policy.dart';
import '../lib/features/ads/domain/ad_segment.dart';
import '../lib/features/ads/domain/airstrike_detector.dart';
import '../lib/features/create/domain/create_draft.dart';
import '../lib/features/create/domain/create_entry.dart';

var _failures = 0;
var _checks = 0;

void check(String name, bool condition, [String detail = '']) {
  _checks++;
  if (condition) return;
  _failures++;
  stderr.writeln('FAIL  ' + name + (detail.isEmpty ? '' : ' — ' + detail));
}

VideoSummary _video({required String title, required String author}) =>
    VideoSummary(
      id: VideoId('BV1xx411c7mD'),
      title: title,
      coverUrl: '',
      author: author,
      duration: const Duration(minutes: 3),
    );

void main() {
  const classifier = AdCardClassifier();

  // ---- feed/search advertisement classification ------------------------
  check(
    'commerce phrase is an ad',
    classifier.isAdvertisement(
      title: '春季上新 点击领券立减100',
      author: '某测评频道',
    ),
  );
  check(
    'commerce author is an ad',
    classifier.isAdvertisement(title: '今天聊聊这个', author: '好物推荐官'),
  );
  check(
    'advertorial reason is an ad',
    classifier.isAdvertisement(
      title: '周末vlog',
      author: '普通UP',
      reason: '广告推广',
    ),
  );
  check(
    'plain review is NOT an ad',
    !classifier.isAdvertisement(
      title: '这款耳机我用了三个月 真实体验',
      author: '普通UP',
      duration: const Duration(minutes: 8),
    ),
  );
  check(
    'unboxing is NOT an ad',
    !classifier.isAdvertisement(
      title: '开箱 某品牌新品上手',
      author: '科技区UP',
      duration: const Duration(minutes: 12),
    ),
  );
  check(
    'commerce danmaku is detected',
    classifier.isAdvertisingDanmaku('淘宝搜同款 优惠券'),
  );
  check(
    'normal danmaku is kept',
    !classifier.isAdvertisingDanmaku('这段太好了，反复看'),
  );

  // ---- feed filter honours blockAds ------------------------------------
  final withAds = RecommendationSettings(blockAds: true);
  final withoutAds = RecommendationSettings(blockAds: false);
  final filterOn = RecommendationFilter(withAds);
  check(
    'filter drops ads when blockAds is on',
    !filterOn.allows(
      _video(title: '限时折扣 抢购到手价', author: '某店'),
      RecommendationSurface.recommended,
    ),
  );
  final filterOff = RecommendationFilter(withoutAds);
  check(
    'filter keeps them when blockAds is off',
    !filterOff.enabledFor(RecommendationSurface.recommended) ||
        filterOff.allows(
          _video(title: '限时折扣 抢购到手价', author: '某店'),
          RecommendationSurface.recommended,
        ),
  );
  check(
    'blockAds survives a JSON round trip',
    RecommendationSettings.fromJson(withAds.toJson()).blockAds,
  );
  check(
    'blockAds defaults to on',
    const RecommendationSettings.defaults().blockAds,
  );

  // ---- ad segment merging ----------------------------------------------
  final merged = mergeAdSegments([
    const AdSegment(
      start: Duration(seconds: 10),
      end: Duration(seconds: 20),
      source: AdSource.onDeviceModel,
      confidence: 0.7,
    ),
    const AdSegment(
      start: Duration(seconds: 18),
      end: Duration(seconds: 30),
      source: AdSource.sponsorBlock,
      confidence: 1,
    ),
  ]);
  check('overlapping segments merge', merged.length == 1, merged.length.toString());
  check(
    'merge keeps the strongest source',
    merged.length == 1 && merged.first.source == AdSource.sponsorBlock,
  );
  check(
    'merge keeps the union of the ranges',
    merged.length == 1 &&
        merged.first.start == const Duration(seconds: 10) &&
        merged.first.end == const Duration(seconds: 30),
  );

  // ---- policy gating ---------------------------------------------------
  const segment = AdSegment(
    start: Duration(seconds: 5),
    end: Duration(seconds: 15),
    source: AdSource.danmakuAirstrike,
    confidence: 0.5,
  );
  const strict = AdPolicy(minimumConfidence: 0.6);
  check(
    'low confidence is filtered by policy',
    strict.skipTargetAt([segment], const Duration(seconds: 10)) == null,
  );
  const lenient = AdPolicy(minimumConfidence: 0.4);
  check(
    'policy allows above threshold',
    lenient.skipTargetAt([segment], const Duration(seconds: 10)) != null,
  );
  const disabled = AdPolicy(skipMode: AdSkipMode.disabled);
  check(
    'disabled mode never skips',
    disabled.skipTargetAt([segment], const Duration(seconds: 10)) == null,
  );
  check(
    'position outside the segment is not skipped',
    lenient.skipTargetAt([segment], const Duration(seconds: 20)) == null,
  );

  // ---- airstrike detection ---------------------------------------------
  const detector = AirstrikeDetector();
  final detected = detector.detect(
    [
      (position: const Duration(seconds: 10), text: '空降 00:12'),
      (position: const Duration(seconds: 11), text: '空降成功 0:13'),
    ],
    videoDuration: const Duration(minutes: 10),
  );
  check('two agreeing airstrikes produce a segment', detected.length == 1);
  final single = detector.detect(
    [(position: const Duration(seconds: 10), text: '空降 00:12')],
    videoDuration: const Duration(minutes: 10),
  );
  check('one airstrike is not enough', single.isEmpty);

  // ---- create draft validation -----------------------------------------
  const videoDraft = CreateDraft(
    entry: CreateEntry.video,
    title: '我的视频',
    mediaPaths: ['a.mp4'],
  );
  check(
    'video draft needs a cover',
    videoDraft.validate() == CreateDraftIssue.coverRequired,
  );
  check(
    'video draft is valid with cover + media',
    videoDraft.copyWith(coverPath: 'c.png').validate() == null,
  );
  const articleDraft = CreateDraft(
    entry: CreateEntry.article,
    title: '我的文章',
    summary: '正文内容',
  );
  check('article draft needs no cover', articleDraft.validate() == null);
  check(
    'empty title is rejected',
    const CreateDraft(entry: CreateEntry.article).validate() ==
        CreateDraftIssue.titleRequired,
  );

  stdout.writeln('domain checks: ' + _checks.toString() + ' run, ' + _failures.toString() + ' failed');
  exit(_failures == 0 ? 0 : 1);
}
