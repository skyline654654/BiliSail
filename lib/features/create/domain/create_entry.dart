/// The two creation flows behind the Bilibili-style centre action.
///
/// Both flows share [CreateDraft] and [CreateRepository]; only the required
/// fields and the upload channel differ. Keeping one enum lets the entry sheet,
/// the draft store and the submit form agree on a single identity.
enum CreateEntry {
  /// 视频投稿：走稿件上传，需要封面与稿件文件。
  video('视频', '投稿稿件，可选择封面与稿件文件'),

  /// 专栏图文：走图文投稿，正文即内容，封面可省略。
  article('图文', '专栏图文，支持图文混排');

  const CreateEntry(this.label, this.description);

  final String label;
  final String description;

  /// Parses a persisted or routed name; unknown values return null so callers
  /// can fall back instead of guessing an entry.
  static CreateEntry? fromName(String? name) {
    if (name == null) return null;
    for (final entry in values) {
      if (entry.name == name) return entry;
    }
    return null;
  }
}
