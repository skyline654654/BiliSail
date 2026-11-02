import 'package:bili_api/bili_api.dart';

import '../../../core/network/api_requests.dart';
import '../../../domain/app_failure.dart';
import '../domain/create_draft.dart';
import '../domain/create_entry.dart';
import '../domain/create_repository.dart';

/// Maps the creation port onto the Web Cookie/CSRF endpoints.
///
/// The client never retries a submission: an unknown outcome must be reconciled
/// by the user (the draft stays in the form) rather than replayed.
final class ApiCreateRepository implements CreateRepository {
  ApiCreateRepository(this.client, this.requests);

  final CreationClient client;
  final ApiRequests requests;

  @override
  Future<CreateSubmission> publish(
    CreateDraft draft, {
    void Function(CreateProgress progress)? onProgress,
  }) => requests.run((context) async {
    final issue = draft.validate();
    if (issue != null) {
      throw AppFailure(AppFailureKind.protocol, issue.message);
    }
    switch (draft.entry) {
      case CreateEntry.article:
        return _publishArticle(draft, onProgress, context);
      case CreateEntry.video:
        return _publishVideo(draft, onProgress, context);
    }
  });

  Future<CreateSubmission> _publishArticle(
    CreateDraft draft,
    void Function(CreateProgress progress)? onProgress,
    ApiRequestContext context,
  ) async {
    onProgress?.call(const CreateProgress(stage: CreateStage.submitting));
    try {
      final result = await client.submitArticle(
        title: draft.title.trim(),
        content: draft.summary,
        original: draft.declaresOriginal,
        context: context,
      );
      return CreateSubmission(
        entry: draft.entry,
        id: result.id,
        reviewState: CreateReviewState.fromWire(result.state),
      );
    } on ApiFailure catch (failure) {
      throw _map(failure, '图文投稿失败');
    }
  }

  Future<CreateSubmission> _publishVideo(
    CreateDraft draft,
    void Function(CreateProgress progress)? onProgress,
    ApiRequestContext context,
  ) async {
    if (!client.canUpload) {
      throw const AppFailure(
        AppFailureKind.protocol,
        '当前版本未接入媒体上传通道，视频投稿暂不可用',
      );
    }
    final cover = draft.coverPath;
    if (cover == null) {
      throw const AppFailure(AppFailureKind.protocol, '视频投稿需要一张封面');
    }
    final total = draft.mediaPaths.length + 1;
    var uploaded = 0;
    onProgress?.call(
      const CreateProgress(stage: CreateStage.uploading, uploadedFraction: 0),
    );
    final coverId = await _upload(cover, context);
    uploaded++;
    onProgress?.call(
      CreateProgress(
        stage: CreateStage.uploading,
        uploadedFraction: uploaded / total,
      ),
    );
    final mediaIds = <String>[];
    for (final path in draft.mediaPaths) {
      mediaIds.add(await _upload(path, context));
      uploaded++;
      onProgress?.call(
        CreateProgress(
          stage: CreateStage.uploading,
          uploadedFraction: uploaded / total,
        ),
      );
    }
    onProgress?.call(const CreateProgress(stage: CreateStage.submitting));
    try {
      final result = await client.submitVideo(
        title: draft.title.trim(),
        description: draft.summary,
        coverAssetId: coverId,
        mediaAssetIds: mediaIds,
        original: draft.declaresOriginal,
        context: context,
      );
      return CreateSubmission(
        entry: draft.entry,
        id: result.id,
        reviewState: CreateReviewState.fromWire(result.state),
      );
    } on ApiFailure catch (failure) {
      throw _map(failure, '视频投稿失败');
    }
  }

  Future<String> _upload(String path, ApiRequestContext context) async {
    try {
      return await client.uploadMedia(
        path,
        cancellation: context.cancellation,
      );
    } on ApiFailure catch (failure) {
      throw _map(failure, '媒体上传失败');
    }
  }

  /// Keeps the domain layer free of the protocol failure taxonomy: the UI only
  /// needs a kind it can render and a message it can show.
  static AppFailure _map(ApiFailure failure, String prefix) => switch (failure
      .category) {
    ApiFailureCategory.cancelled => const AppFailure(
      AppFailureKind.cancelled,
      '已取消',
    ),
    ApiFailureCategory.timeout => AppFailure(
      AppFailureKind.timeout,
      '$prefix：请求超时',
    ),
    ApiFailureCategory.authentication || ApiFailureCategory.permission =>
      AppFailure(AppFailureKind.authentication, '$prefix：请先登录'),
    ApiFailureCategory.rateLimited => AppFailure(
      AppFailureKind.rateLimited,
      '$prefix：操作太频繁，请稍后再试',
    ),
    ApiFailureCategory.unavailable => AppFailure(
      AppFailureKind.protocol,
      '$prefix：当前版本不支持该操作',
    ),
    _ => AppFailure(AppFailureKind.unknown, '$prefix：服务端未受理'),
  };
}