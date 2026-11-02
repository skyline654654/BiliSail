import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/create_controller.dart';
import '../domain/create_draft.dart';
import '../domain/create_entry.dart';
import '../domain/create_repository.dart';

/// The form behind the centre action.
///
/// Pushed as a modal route so the workspace tab strip and the bottom bar keep
/// their state: 创作 is a temporary flow, not a retained page.
class CreateScreen extends ConsumerStatefulWidget {
  const CreateScreen({super.key, required this.entry});

  final CreateEntry entry;

  /// Opens the form for [entry] above the current workspace.
  static Future<void> open(BuildContext context, CreateEntry entry) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => CreateScreen(entry: entry),
      ),
    );
  }

  @override
  ConsumerState<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends ConsumerState<CreateScreen> {
  late final TextEditingController _title = TextEditingController();
  late final TextEditingController _summary = TextEditingController();
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(createControllerProvider.notifier).selectEntry(widget.entry);
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _summary.dispose();
    super.dispose();
  }

  /// Copies the draft into the text fields once, so a route rebuild does not
  /// fight the user's cursor.
  void _seedTextFields(CreateState state) {
    if (_seeded) return;
    _seeded = true;
    _title.text = state.draft.title;
    _summary.text = state.draft.summary;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createControllerProvider);
    final controller = ref.read(createControllerProvider.notifier);
    final picker = ref.watch(createMediaPickerProvider);
    _seedTextFields(state);
    final submission = state.submission;
    return Scaffold(
      appBar: AppBar(
        title: Text('${state.entry.label}创作'),
        leading: IconButton(
          key: const ValueKey('create-close'),
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: submission == null
          ? ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                TextField(
                  key: const ValueKey('create-title'),
                  controller: _title,
                  enabled: !state.busy,
                  maxLength: CreateDraft.maxTitleLength,
                  decoration: const InputDecoration(
                    labelText: '标题',
                    hintText: '一句话说清这条内容',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: controller.updateTitle,
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const ValueKey('create-summary'),
                  controller: _summary,
                  enabled: !state.busy,
                  minLines: 4,
                  maxLines: 12,
                  decoration: InputDecoration(
                    labelText: state.entry == CreateEntry.article ? '正文' : '简介',
                    hintText: '向观众介绍这条内容',
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: controller.updateSummary,
                ),
                const SizedBox(height: 16),
                if (state.entry == CreateEntry.video)
                  _MediaSection(
                    state: state,
                    pickerAvailable: picker.isAvailable,
                    onPickCover: () async {
                      final path = await picker.pickCover();
                      if (path != null) controller.setCover(path);
                    },
                    onPickMedia: () async {
                      final paths = await picker.pickMedia(imagesOnly: false);
                      controller.addMedia(paths);
                    },
                    onRemoveMedia: controller.removeMedia,
                  ),
                const SizedBox(height: 8),
                SwitchListTile(
                  key: const ValueKey('create-original'),
                  value: state.draft.declaresOriginal,
                  onChanged: state.busy ? null : controller.setDeclaresOriginal,
                  title: const Text('声明原创'),
                  subtitle: const Text('原创内容会进入原创审核流程'),
                  contentPadding: EdgeInsets.zero,
                ),
                if (state.failure case final failure?)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      failure.message,
                      key: const ValueKey('create-failure'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            )
          : _SubmittedView(submission: submission),
      bottomNavigationBar: submission == null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton(
                  key: const ValueKey('create-submit'),
                  onPressed: state.busy ? null : controller.publish,
                  child: state.busy
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${_stageLabel(state.stage)} '
                              '${(state.uploadedFraction * 100).round()}%',
                            ),
                          ],
                        )
                      : const Text('发布'),
                ),
              ),
            )
          : null,
    );
  }

  String _stageLabel(CreateStage stage) => switch (stage) {
    CreateStage.preparing => '准备中',
    CreateStage.uploading => '上传中',
    CreateStage.submitting => '提交中',
    CreateStage.done => '已完成',
  };
}

class _MediaSection extends StatelessWidget {
  const _MediaSection({
    required this.state,
    required this.pickerAvailable,
    required this.onPickCover,
    required this.onPickMedia,
    required this.onRemoveMedia,
  });

  final CreateState state;
  final bool pickerAvailable;
  final Future<void> Function() onPickCover;
  final Future<void> Function() onPickMedia;
  final void Function(String path) onRemoveMedia;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final cover = state.draft.coverPath;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          key: const ValueKey('create-cover'),
          onPressed: state.busy || !pickerAvailable ? null : onPickCover,
          icon: const Icon(Icons.image_outlined),
          label: Text(cover == null ? '选择封面' : '更换封面'),
        ),
        if (cover != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              cover.split(RegExp(r'[\\/]')).last,
              key: const ValueKey('create-cover-name'),
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const ValueKey('create-media'),
          onPressed: state.busy || !pickerAvailable ? null : onPickMedia,
          icon: const Icon(Icons.video_file_outlined),
          label: const Text('选择稿件文件'),
        ),
        for (final path in state.draft.mediaPaths)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.movie_outlined),
            title: Text(path.split(RegExp(r'[\\/]')).last),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: state.busy ? null : () => onRemoveMedia(path),
            ),
          ),
      ],
    );
  }
}

class _SubmittedView extends StatelessWidget {
  const _SubmittedView({required this.submission});

  final CreateSubmission submission;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('已提交', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '${submission.entry.label} · ${submission.reviewState.label}',
              key: const ValueKey('create-result'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
