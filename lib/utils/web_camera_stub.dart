import 'dart:async';

import 'package:image_picker/image_picker.dart';

/// Non-web stub — camera capture is handled by [ImagePicker] on native platforms.
Future<XFile?> captureFromWebCamera() {
  throw UnsupportedError('captureFromWebCamera is only available on web.');
}
