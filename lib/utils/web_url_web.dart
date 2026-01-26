import 'dart:html' as html;

abstract class WebUrlHandler {
  void clearAuthRedirect(Uri uri);
}

WebUrlHandler createWebUrlHandler() => _WebUrlHandler();

class _WebUrlHandler implements WebUrlHandler {
  @override
  void clearAuthRedirect(Uri uri) {
    final cleaned = uri.replace(fragment: '');
    html.window.history.replaceState(null, '', cleaned.toString());
  }
}
