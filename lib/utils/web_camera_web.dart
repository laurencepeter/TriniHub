import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:image_picker/image_picker.dart';

/// Opens the device camera (or webcam on desktop) via a hidden
/// `<input type="file" accept="image/*" capture="environment">` element.
///
/// Using the `capture` attribute is what tells the browser to launch the
/// camera directly rather than showing the generic file-browser.  Without it
/// Flutter's `image_picker_for_web` plugin falls back to a regular file-picker.
Future<XFile?> captureFromWebCamera() {
  final completer = Completer<XFile?>();

  final input = html.InputElement(type: 'file')
    ..accept = 'image/*'
    ..setAttribute('capture', 'environment')
    ..style.display = 'none';

  html.document.body!.append(input);

  StreamSubscription<html.Event>? changeSub;
  StreamSubscription<html.Event>? cancelSub;

  void cleanup() {
    changeSub?.cancel();
    cancelSub?.cancel();
    input.remove();
  }

  void complete(XFile? result) {
    if (!completer.isCompleted) {
      cleanup();
      completer.complete(result);
    }
  }

  changeSub = input.onChange.listen((_) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      complete(null);
      return;
    }
    final file = files[0];
    complete(
      XFile(
        html.Url.createObjectUrl(file),
        name: file.name,
        mimeType: file.type,
        length: file.size,
      ),
    );
  });

  // `cancel` event fires in Chrome 113+, Firefox 91+, Safari 16+.
  cancelSub = input.on['cancel'].listen((_) => complete(null));

  // Fallback cancel detection: when the browser dialog closes without a
  // selection the window regains focus.  A short delay lets `onChange` fire
  // first if the user did pick a file.
  late final StreamSubscription<html.Event> focusSub;
  focusSub = html.window.onFocus.listen((_) {
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (!completer.isCompleted) {
        focusSub.cancel();
        complete(null);
      }
    });
  });

  input.click();
  return completer.future;
}
