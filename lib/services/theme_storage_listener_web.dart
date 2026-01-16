import 'dart:async';
import 'dart:html' as html;

typedef StorageValueChanged = void Function(String? value);

StreamSubscription<html.StorageEvent>? _storageSubscription;

void registerStorageListenerImpl(String key, StorageValueChanged onValue) {
  _storageSubscription?.cancel();
  _storageSubscription = html.window.onStorage.listen((event) {
    if (event.key != key) {
      return;
    }
    onValue(event.newValue);
  });
}
