// 弹幕广告判据：正例必须命中，正常观影弹幕必须放过。
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/domain/ad_card_classifier.dart';

void main() {
  const classifier = AdCardClassifier();

  test('引流与代练类命中', () {
    expect(classifier.isAdvertisingDanmaku('加群领福利'), isTrue);
    expect(classifier.isAdvertisingDanmaku('代练上分私我'), isTrue);
    expect(classifier.isAdvertisingDanmaku('广告位招租'), isTrue);
    expect(classifier.isAdvertisingDanmaku('代刷播放量'), isTrue);
  });

  test('电商导流命中（需同时出现平台与动作）', () {
    expect(classifier.isAdvertisingDanmaku('淘宝搜同款'), isTrue);
    expect(classifier.isAdvertisingDanmaku('拼多多领券'), isTrue);
    expect(classifier.isAdvertisingDanmaku('京东买显卡'), isTrue);
    // 只提平台不算广告：观众讨论也很常见。
    expect(classifier.isAdvertisingDanmaku('这个淘宝上好像有'), isFalse);
    expect(classifier.isAdvertisingDanmaku('京东物流真快'), isFalse);
  });

  test('正常弹幕不被误杀', () {
    expect(classifier.isAdvertisingDanmaku('哈哈哈哈'), isFalse);
    expect(classifier.isAdvertisingDanmaku('前方高能'), isFalse);
    expect(
      classifier.isAdvertisingDanmaku('这期讲得挺清楚，学到了'),
      isFalse,
    );
  });
}
