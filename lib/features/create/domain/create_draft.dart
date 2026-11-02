import 'create_entry.dart';

/// One submission draft.
///
/// Immutable so the controller can keep prior versions for undo and so
/// validation has a stable input. Paths stay as opaque strings here: the data
/// layer owns their meaning and never trusts them for identity.
final class CreateDraft {
  const CreateDraft({
    required this.entry,
    this.title = '',
    this.summary = '',
    this.coverPath,
    this.mediaPaths = const <String>[],
    this.tags = const <String>[],
    this.declaresOriginal = false,
  });

  /// A draft for [entry] with every field empty.
  factory CreateDraft.empty(CreateEntry entry) => CreateDraft(entry: entry);

  static const int maxTitleLength = 80;
  static const int maxSummaryLength = 2000;
  static const int maxTags = 10;
  static const int maxVideoParts = 10;

  final CreateEntry entry;
  final String title;
  final String summary;
  final String? coverPath;
  final List<String> mediaPaths;
  final List<String> tags;
  final bool declaresOriginal;

  bool get isEmpty =>
      title.isEmpty &&
      summary.isEmpty &&
      coverPath == null &&
      mediaPaths.isEmpty &&
      tags.isEmpty &&
      !declaresOriginal;

  CreateDraft copyWith({
    String? title,
    String? summary,
    String? coverPath,
    List<String>? mediaPaths,
    List<String>? tags,
    bool? declaresOriginal,
    bool clearCover = false,
  }) => CreateDraft(
    entry: entry,
    title: title ?? this.title,
    summary: summary ?? this.summary,
    coverPath: clearCover ? null : coverPath ?? this.coverPath,
    mediaPaths: mediaPaths ?? this.mediaPaths,
    tags: tags ?? this.tags,
    declaresOriginal: declaresOriginal ?? this.declaresOriginal,
  );

  /// Returns the first blocking issue, or null when the draft can be sent.
  ///
  /// The server stays authoritative; this only stops obviously invalid
  /// submissions before they consume an upload ticket.
  CreateDraftIssue? validate() {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) return CreateDraftIssue.titleRequired;
    if (trimmedTitle.runes.length > maxTitleLength) {
      return CreateDraftIssue.titleTooLong;
    }
    if (summary.runes.length > maxSummaryLength) {
      return CreateDraftIssue.summaryTooLong;
    }
    if (tags.length > maxTags) return CreateDraftIssue.tooManyTags;
    if (mediaPaths.length > maxVideoParts) {
      return CreateDraftIssue.tooManyVideoParts;
    }
    switch (entry) {
      case CreateEntry.video:
        if (mediaPaths.isEmpty) return CreateDraftIssue.mediaRequired;
        final cover = coverPath;
        if (cover == null || cover.isEmpty) {
          return CreateDraftIssue.coverRequired;
        }
      case CreateEntry.article:
        // 图文以正文为主，封面与文件均可省略。
        break;
    }
    return null;
  }
}

/// Blocking draft problems, in the order [CreateDraft.validate] reports them.
enum CreateDraftIssue {
  titleRequired('请填写标题'),
  titleTooLong('标题不能超过 80 个字'),
  summaryTooLong('简介不能超过 2000 个字'),
  tooManyTags('标签不能超过 10 个'),
  tooManyVideoParts('单个稿件不能超过 10 个文件'),
  mediaRequired('请选择要投稿的文件'),
  coverRequired('视频投稿需要一张封面');

  const CreateDraftIssue(this.message);

  final String message;
}
