/// Platform-port for choosing the files a draft needs.
///
/// The create flow never touches file_selector directly: desktop, Android and
/// HarmonyOS expose different pickers, and a capability that is missing simply
/// reports an empty selection instead of failing the form.
abstract interface class CreateMediaPicker {
  /// Returns the chosen cover path, or null when the user cancelled.
  Future<String?> pickCover();

  /// Returns the chosen media paths. An empty list means the user cancelled.
  Future<List<String>> pickMedia({required bool imagesOnly});

  /// Whether this platform can pick files at all.
  bool get isAvailable;
}

/// Used on platforms that ship no picker; the form hides its add buttons.
final class UnsupportedCreateMediaPicker implements CreateMediaPicker {
  const UnsupportedCreateMediaPicker();

  @override
  bool get isAvailable => false;

  @override
  Future<String?> pickCover() async => null;

  @override
  Future<List<String>> pickMedia({required bool imagesOnly}) async => const [];
}
