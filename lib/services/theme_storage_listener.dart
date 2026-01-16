import 'theme_storage_listener_stub.dart'
    if (dart.library.html) 'theme_storage_listener_web.dart';

typedef StorageValueChanged = void Function(String? value);

void registerStorageListener(String key, StorageValueChanged onValue) {
  registerStorageListenerImpl(key, onValue);
}
