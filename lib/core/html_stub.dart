// Stub for non-web platforms (mobile / desktop).
// Mirrors the dart:html API surface used by receipt_screen.dart
// so the file compiles on all platforms.

// ignore_for_file: avoid_classes_with_only_static_members

class AnchorElement {
  AnchorElement({String? href}) : _href = href;
  final String? _href;
  String download = '';

  // ignore: unused_element
  void setAttribute(String name, String value) {
    if (name == 'download') download = value;
  }

  void click() {}
}

class Url {
  static String createObjectUrlFromBlob(Blob blob) => '';
  static void revokeObjectUrl(String url) {}
}

class Blob {
  Blob(List<dynamic> parts, [String? type]);
}
