import '../api_client.dart';
import '../models.dart';

/// What the server returned for a creation submission.
final class ApiCreationResult {
  const ApiCreationResult({required this.id, required this.state});

  /// Opaque server identity: `aid` for a video, `cvid` for an article.
  final String id;

  /// Raw server state string; the caller maps it through its own enum.
  final String state;
}

/// Upload port for the media backing a video draft.
///
/// The submission below only carries metadata: a real投稿 must first push the
/// media through Bilibili's pre-upload/chunk protocol, which is intentionally
/// **not** implemented here. Keeping it behind a port means the rest of the
/// client is testable and the missing capability is explicit instead of being
/// faked.
abstract interface class ApiCreationMediaUploader {
  /// Uploads [path] and returns the server-side asset identifier.
  Future<String> upload(String path, {ApiCancellation? cancellation});
}

/// Creation endpoints (web Cookie + CSRF).
///
/// **Not verified online.** The paths follow the web 创作中心 contract used by
/// the browser client; the response validation is written against the shapes
/// that contract documents, and anything unexpected is reported as a protocol
/// failure rather than silently accepted.
final class CreationClient {
  const CreationClient(this.api, {ApiCreationMediaUploader? uploader})
    : _uploader = uploader;

  final BiliApiClient api;
  final ApiCreationMediaUploader? _uploader;

  /// Submits a 专栏图文. Text only, so this is the one creation flow that does
  /// not need the media upload port.
  Future<ApiCreationResult> submitArticle({
    required String title,
    required String content,
    bool original = false,
    int articleCategory = 21,
    ApiRequestContext? context,
  }) async {
    const endpoint = 'creation_article';
    if (title.trim().isEmpty || content.trim().isEmpty) {
      throw ApiFailure(ApiFailureCategory.protocol, endpoint);
    }
    final result = await api.submitForm(
      '/x/article/creative/article/submit',
      endpoint,
      {
        'title': title,
        'content': content,
        'template_id': '4',
        // 实测（2026-11-02）：分类参数名是 `category`（不是 tid），缺它返回
        // 20022「分类错误」；补上后错误推进到 20023「转载类型错误」，说明
        // `original` 的取值域也要按原创/转载的既有枚举给。
        'category': '$articleCategory',
        'original': original ? '1' : '2',
      },
      context: context,
    );
    return _result(result, endpoint, const ['cvid', 'id']);
  }

  /// Submits a 投稿稿件 once every media file already has an asset id.
  Future<ApiCreationResult> submitVideo({
    required String title,
    required String description,
    required String coverAssetId,
    required List<String> mediaAssetIds,
    int tid = 21,
    bool original = false,
    ApiRequestContext? context,
  }) async {
    const endpoint = 'creation_video';
    if (title.trim().isEmpty ||
        coverAssetId.isEmpty ||
        mediaAssetIds.isEmpty ||
        mediaAssetIds.length > 10) {
      throw ApiFailure(ApiFailureCategory.protocol, endpoint);
    }
    // 2026-11-02 实测：只有 member.bilibili.com 的这个路径存在（api 的 /x/vu/web/add、
    // /v3、/client/add 全部 404）。完整参数集需一次真实投稿才能确认，见 docs。
    final result = await api.submitMemberForm(
      '/x/vu/web/add',
      endpoint,
      {
        'title': title,
        'desc': description,
        'cover': coverAssetId,
        'tid': '$tid',
        'copyright': original ? '1' : '2',
        'videos': mediaAssetIds.length.toString(),
        'source': 'web',
      },
      context: context,
    );
    return _result(result, endpoint, const ['aid', 'id']);
  }

  /// Whether this build can upload media at all.
  bool get canUpload => _uploader != null;

  /// Uploads one media file, or reports that the capability is missing.
  Future<String> uploadMedia(String path, {ApiCancellation? cancellation}) {
    final uploader = _uploader;
    if (uploader == null) {
      throw const ApiFailure(
        ApiFailureCategory.unavailable,
        'creation_upload',
      );
    }
    return uploader.upload(path, cancellation: cancellation);
  }

  /// The server answers with `{code:0,data:{aid|cvid:…}}`; anything else is a
  /// protocol failure. Unknown outcomes are **not** retried here.
  static ApiCreationResult _result(
    Object? body,
    String endpoint,
    List<String> idKeys,
  ) {
    if (body is! Map<String, Object?>) {
      throw ApiFailure(ApiFailureCategory.protocol, endpoint);
    }
    final data = body['data'];
    for (final key in idKeys) {
      final direct = body[key] ?? (data is Map<String, Object?> ? data[key] : null);
      final id = switch (direct) {
        final int number when number > 0 => number.toString(),
        final String text when text.isNotEmpty => text,
        _ => null,
      };
      if (id != null) {
        return ApiCreationResult(
          id: id,
          state: body['state'] is String ? body['state'] as String : 'queued',
        );
      }
    }
    throw ApiFailure(ApiFailureCategory.protocol, endpoint);
  }
}