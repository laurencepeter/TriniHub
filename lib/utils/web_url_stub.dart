abstract class WebUrlHandler {
  void clearAuthRedirect(Uri uri);
}

WebUrlHandler createWebUrlHandler() => _NoopWebUrlHandler();

class _NoopWebUrlHandler implements WebUrlHandler {
  @override
  void clearAuthRedirect(Uri uri) {}
}
