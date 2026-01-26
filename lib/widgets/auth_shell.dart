import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:local_app_tt/widgets/auth_callback_page.dart';
import 'package:local_app_tt/widgets/auth_gate.dart';

class AuthShell extends StatelessWidget {
  final void Function(bool) onThemeToggle;

  const AuthShell({super.key, required this.onThemeToggle});

  bool _shouldHandleAuthCallback(Uri uri) {
    if (!kIsWeb) {
      return false;
    }
    final query = uri.queryParameters;
    final hasQueryParams = query.containsKey('code') ||
        query.containsKey('access_token') ||
        query['type'] == 'signup' ||
        query['type'] == 'recovery';
    final fragment = uri.fragment;
    final hasFragmentParams = fragment.contains('access_token=') ||
        fragment.contains('refresh_token=') ||
        fragment.contains('type=signup') ||
        fragment.contains('type=recovery') ||
        fragment.contains('code=');
    return hasQueryParams || hasFragmentParams;
  }

  @override
  Widget build(BuildContext context) {
    if (_shouldHandleAuthCallback(Uri.base)) {
      return AuthCallbackPage(onThemeToggle: onThemeToggle);
    }
    return AuthGate(
      key: ValueKey(Theme.of(context).brightness),
      onThemeToggle: onThemeToggle,
    );
  }
}
