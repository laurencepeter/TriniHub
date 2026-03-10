/// Conditional export: picks the dart:html implementation on web and a
/// no-op stub on every other platform.
export 'web_camera_stub.dart' if (dart.library.html) 'web_camera_web.dart';
