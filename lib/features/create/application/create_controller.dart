import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/app_failure.dart';
import '../domain/create_draft.dart';
import '../domain/create_entry.dart';
import '../domain/create_media_picker.dart';
import '../domain/create_repository.dart';

/// Provided by the composition root; the create feature never builds its own
/// transport.
final createRepositoryProvider = Provider<CreateRepository>(
  (ref) => const UnsupportedCreateRepository('当前平台暂未接入投稿通道'),
);

/// Same contract for the file picker: unsupported platforms get the no-op.
final createMediaPickerProvider = Provider<CreateMediaPicker>(
  (ref) => const UnsupportedCreateMediaPicker(),
);

final createControllerProvider =
    NotifierProvider<CreateController, CreateState>(CreateController.new);

/// Everything the 创作 page renders.
final class CreateState {
  const CreateState({
    required this.entry,
    required this.draft,
    this.busy = false,
    this.stage = CreateStage.preparing,
    this.uploadedFraction = 0,
    this.failure,
    this.submission,
  });

  factory CreateState.forEntry(CreateEntry entry) =>
      CreateState(entry: entry, draft: CreateDraft.empty(entry));

  final CreateEntry entry;
  final CreateDraft draft;
  final bool busy;
  final CreateStage stage;
  final double uploadedFraction;
  final AppFailure? failure;
  final CreateSubmission? submission;

  /// True once the server accepted the draft; the page switches to its
  /// success state and stops accepting edits.
  bool get submitted => submission != null;

  CreateState copyWith({
    CreateEntry? entry,
    CreateDraft? draft,
    bool? busy,
    CreateStage? stage,
    double? uploadedFraction,
    AppFailure? failure,
    CreateSubmission? submission,
    bool clearFailure = false,
    bool clearSubmission = false,
  }) => CreateState(
    entry: entry ?? this.entry,
    draft: draft ?? this.draft,
    busy: busy ?? this.busy,
    stage: stage ?? this.stage,
    uploadedFraction: uploadedFraction ?? this.uploadedFraction,
    failure: clearFailure ? null : failure ?? this.failure,
    submission: clearSubmission ? null : submission ?? this.submission,
  );
}

final class CreateController extends Notifier<CreateState> {
  int _generation = 0;

  @override
  CreateState build() {
    ref.onDispose(() => _generation++);
    return CreateState.forEntry(CreateEntry.video);
  }

  /// Switches the active flow. Editing is refused while a submit is running.
  void selectEntry(CreateEntry entry) {
    if (state.busy || entry == state.entry) return;
    state = CreateState.forEntry(entry);
  }

  void updateTitle(String value) =>
      _edit((draft) => draft.copyWith(title: value));

  void updateSummary(String value) =>
      _edit((draft) => draft.copyWith(summary: value));

  void setCover(String? path) => _edit(
    (draft) => path == null
        ? draft.copyWith(clearCover: true)
        : draft.copyWith(coverPath: path),
  );

  void addMedia(List<String> paths) {
    if (paths.isEmpty) return;
    _edit((draft) {
      final merged = <String>[
        ...draft.mediaPaths,
        for (final path in paths)
          if (!draft.mediaPaths.contains(path)) path,
      ];
      return draft.copyWith(
        mediaPaths: merged.take(CreateDraft.maxVideoParts).toList(),
      );
    });
  }

  void removeMedia(String path) => _edit(
    (draft) => draft.copyWith(
      mediaPaths: [
        for (final candidate in draft.mediaPaths)
          if (candidate != path) candidate,
      ],
    ),
  );

  void setDeclaresOriginal(bool value) =>
      _edit((draft) => draft.copyWith(declaresOriginal: value));

  /// Replaces the draft wholesale; used by tests and by "恢复草稿" flows.
  void restore(CreateDraft draft) {
    if (state.busy) return;
    state = state.copyWith(
      entry: draft.entry,
      draft: draft,
      clearFailure: true,
      clearSubmission: true,
    );
  }

  Future<void> publish() async {
    if (state.busy) return;
    final issue = state.draft.validate();
    if (issue != null) {
      state = state.copyWith(
        failure: AppFailure(AppFailureKind.protocol, issue.message),
      );
      return;
    }
    final generation = ++_generation;
    state = state.copyWith(
      busy: true,
      stage: CreateStage.preparing,
      uploadedFraction: 0,
      clearFailure: true,
    );
    try {
      final submission = await ref
          .read(createRepositoryProvider)
          .publish(
            state.draft,
            onProgress: (progress) {
              if (generation != _generation) return;
              state = state.copyWith(
                stage: progress.stage,
                uploadedFraction: progress.uploadedFraction.clamp(0, 1),
              );
            },
          );
      if (generation != _generation) return;
      state = state.copyWith(
        busy: false,
        stage: CreateStage.done,
        uploadedFraction: 1,
        submission: submission,
      );
    } on AppFailure catch (failure) {
      if (generation != _generation) return;
      // 取消不是错误：保留草稿，回到可编辑状态。
      if (failure.kind == AppFailureKind.cancelled) {
        state = state.copyWith(busy: false, stage: CreateStage.preparing);
        return;
      }
      state = state.copyWith(busy: false, failure: failure);
    } catch (error) {
      if (generation != _generation) return;
      state = state.copyWith(
        busy: false,
        failure: AppFailure(AppFailureKind.unknown, '投稿失败：$error'),
      );
    }
  }

  void _edit(CreateDraft Function(CreateDraft draft) change) {
    if (state.busy || state.submitted) return;
    state = state.copyWith(draft: change(state.draft), clearFailure: true);
  }
}
