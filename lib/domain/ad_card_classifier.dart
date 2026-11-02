/// Decides whether a feed/search card is an advertisement.
///
/// Bilibili mixes commercial cards into recommendations, search results and the
/// dynamic list. The API already drops some of them, but the ones that survive
/// as ordinary video cards are recognisable from a small set of stable signals.
/// Keeping the rule here — in the shared domain layer — lets the recommendation
/// filter and any future surface share one definition without the domain layer
/// depending on a feature package.
///
/// The classifier is deliberately conservative: it only needs to catch cards
/// whose *primary purpose* is advertising. Ordinary product reviews and
/// unboxing videos must survive, so a single brand word is never enough.
final class AdCardClassifier {
  const AdCardClassifier();

  /// Phrases that mark a card as commerce rather than content. Each one is
  /// long enough that a normal review title will not contain it.
  static const List<String> _commerceMarkers = [
    '限时折扣',
    '点击领券',
    '优惠券领取',
    '加微信',
    '扫码进群',
    '代理招募',
    '一键返利',
    '购物返现',
    '推广合作',
    '商务合作请私信',
    '广告位招租',
    '免费领取',
    '0元购',
    '私信领取',
  ];

  /// Author names used by commerce accounts. Matched as a whole token so a
  /// creator called「优惠券测评」的 still passes.
  static const List<String> _commerceAuthors = [
    '旗舰店',
    '官方旗舰',
    '好物推荐官',
    '优惠券小助手',
    '省钱小助手',
    '福利官',
  ];

  /// Longer than this and a card is almost certainly a programme episode or a
  /// livestream replay, never a 15-second commerce clip.
  static const Duration _commerceMaximumDuration = Duration(seconds: 90);

  /// Returns true when [title]/[author] carry enough commerce signals that the
  /// card should be removed from a recommendation list.
  ///
  /// [reason] is the API's own recommendation reason (「因为你关注了…」),
  /// which sometimes spells out「广告」or「推广」directly.
  bool isAdvertisement({
    required String title,
    required String author,
    String? categoryName,
    String? reason,
    Duration duration = Duration.zero,
  }) {
    final lowerTitle = title.toLowerCase();
    final lowerAuthor = author.toLowerCase();
    if (_containsAny(lowerTitle, _commerceMarkers)) return true;
    if (_containsAny(lowerAuthor, _commerceAuthors)) return true;
    final lowerReason = reason?.toLowerCase();
    if (lowerReason != null &&
        (lowerReason.contains('广告') || lowerReason.contains('推广'))) {
      return true;
    }
    // Short clips from a category the API marks as commerce.
    final lowerCategory = categoryName?.toLowerCase();
    if (lowerCategory != null &&
        (lowerCategory.contains('广告') || lowerCategory.contains('推广'))) {
      return true;
    }
    return duration > Duration.zero &&
        duration <= _commerceMaximumDuration &&
        (lowerTitle.contains('秒杀') || lowerTitle.contains('抢购')) &&
        _containsAny(lowerTitle, const ['包邮', '到手价', '原价']);
  }

  /// Returns true for a danmaku line that is itself advertising.
  ///
  /// Manual-tap ads in the danmaku field are short and link out; the timing is
  /// irrelevant, so this only looks at the text.
  bool isAdvertisingDanmaku(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('淘宝') || lower.contains('拼多多') || lower.contains('京东')) {
      return _containsAny(lower, const ['搜', '买', '优惠', '券']);
    }
    return _containsAny(lower, const ['加群', '代刷', '代练', '引流', '广告位']);
  }

  static bool _containsAny(String haystack, List<String> needles) {
    for (final needle in needles) {
      if (haystack.contains(needle)) return true;
    }
    return false;
  }
}
