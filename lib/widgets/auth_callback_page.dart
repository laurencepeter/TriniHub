import 'package:flutter/material.dart';
import 'package:local_app_tt/widgets/auth_gate.dart';
import 'package:local_app_tt/utils/web_url.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthCallbackPage extends StatefulWidget {
  final void Function(bool) onThemeToggle;

  const AuthCallbackPage({super.key, required this.onThemeToggle});

  @override
  State<AuthCallbackPage> createState() => _AuthCallbackPageState();
}

class _AuthCallbackPageState extends State<AuthCallbackPage> {
  String _statusMessage = 'Finishing your sign-in...';
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _handleRedirect();
  }

  Future<void> _handleRedirect() async {
    final authClient = Supabase.instance.client.auth;
    try {
      await authClient.getSessionFromUrl(Uri.base);
      webUrlHandler.clearAuthRedirect(Uri.base);
      final session = authClient.currentSession;
      if (!mounted) return;
      if (session != null) {
        setState(() {
          _statusMessage = 'You have been authenticated. Redirecting you to the app...';
          _completed = true;
        });
        await Future.delayed(const Duration(milliseconds: 900));
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => AuthGate(onThemeToggle: widget.onThemeToggle),
          ),
        );
      } else {
        setState(() {
          _statusMessage = 'You have been authenticated. Refresh the app to continue.';
          _completed = true;
        });
      }
    } on AuthException {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'We could not finish signing you in. Please refresh and try again.';
        _completed = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'We could not finish signing you in. Please refresh and try again.';
        _completed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _completed ? Icons.verified_user_outlined : Icons.mark_email_unread_outlined,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'You can close this tab once you return to the app.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
