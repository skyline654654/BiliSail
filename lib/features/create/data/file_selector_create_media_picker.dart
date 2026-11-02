import 'package:file_selector/file_selector.dart';

import '../domain/create_media_picker.dart';

/// Desktop/mobile picker backed by the platform file dialog.
///
/// HarmonyOS keeps this implementation too: the ArkUI shell hosts the file
/// chooser through the same plugin channel, so no second picker is needed.
final class FileSelectorCreateMediaPicker implements CreateMediaPicker {
  const FileSelectorCreateMediaPicker();

  static const _imageGroup = XTypeGroup(
    label: '图片',
    extensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp'],
  );

  static const _videoGroup = XTypeGroup(
    label: '视频与图片',
    extensions: ['mp4', 'mov', 'mkv', 'flv', 'webm', 'jpg', 'png'],
  );

  @override
  bool get isAvailable => true;

  @override
  Future<String?> pickCover() async {
    final file = await openFile(acceptedTypeGroups: const [_imageGroup]);
    return file?.path;
  }

  @override
  Future<List<String>> pickMedia({required bool imagesOnly}) async {
    final files = await openFiles(
      acceptedTypeGroups: [imagesOnly ? _imageGroup : _videoGroup],
    );
    return [
      for (final file in files)
        if (file.path.isNotEmpty) file.path,
    ];
  }
}
