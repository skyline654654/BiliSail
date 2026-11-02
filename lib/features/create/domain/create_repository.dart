import '../../../domain/app_failure.dart';
import 'create_draft.dart';
import 'create_entry.dart';

/// The pipeline stages the server dictates for one submission.
enum CreateStage {
  /// 占位，尚未开始。
  preparing,

  /// 申请上传凭证并让用户文件就位。
  uploading,

  /// 已上传素材，正在提交稿件。
  submitting,

  /// 服务器已受理。
  done,
}

/// One submission attempt as the UI observes it.
final class CreateProgress {
  const CreateProgress({
    required this.stage,
    this.uploadedFraction = 0,
    this.reason,
  });

  final CreateStage stage;

  /// 0..1 for [CreateStage.uploading] and [CreateStage.submitting]; other
  /// stages carry 0 so the indicator does not jump around.
  final double uploadedFraction;

  /// Optional human-readable reason for the current stage.
  final String? reason;
}

/// Where a submitted draft is in review.
enum CreateReviewState {
  queued('排队审核'),
  reviewing('审核中'),
  published('已发布'),
  rejected('未通过');

  const CreateReviewState(this.label);

  final String label;

  /// Maps the wire value; unknown values stay [queued] because the server may
  /// add states without notice.
  static CreateReviewState fromWire(String? value) => switch (value) {
    'published' || 'passed' || 'success' => CreateReviewState.published,
    'rejected' || 'failed' || 'blocked' => CreateReviewState.rejected,
    'reviewing' || 'checking' => CreateReviewState.reviewing,
    _ => CreateReviewState.queued,
  };
}

/// The server's verdict for one submission.
final class CreateSubmission {
  const CreateSubmission({
    required this.entry,
    required this.id,
    required this.reviewState,
  });

  final CreateEntry entry;

  /// Server-side identity (aid for video, cvid for article). Opaque string.
  final String id;
  final CreateReviewState reviewState;
}

/// Creation port.
///
/// Implementations own the upload transport and the account scope. Signed
/// upload URLs are single-use and must never be persisted, logged or written
/// into settings.
abstract interface class CreateRepository {
  /// Runs the full pipeline for [draft] and reports progress along the way.
  ///
  /// Implementations must honour [onProgress] ordering and must not emit
  /// progress after the future completes.
  Future<CreateSubmission> publish(
    CreateDraft draft, {
    void Function(CreateProgress progress)? onProgress,
  });
}

/// Used until the composition root supplies a real transport.
///
/// Keeps the tree runnable on platforms that cannot publish yet instead of
/// throwing a bare UnimplementedError from a button press.
final class UnsupportedCreateRepository implements CreateRepository {
  const UnsupportedCreateRepository(this.reason);

  final String reason;

  @override
  Future<CreateSubmission> publish(
    CreateDraft draft, {
    void Function(CreateProgress progress)? onProgress,
  }) async => throw AppFailure(AppFailureKind.protocol, reason);
}
