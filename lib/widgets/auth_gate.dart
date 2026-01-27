import 'package:flutter/material.dart';
import 'package:local_app_tt/screens/auth/complete_profile_page.dart';
import 'package:local_app_tt/screens/auth/set_new_password_page.dart';
import 'package:local_app_tt/services/auth_service.dart';
import 'package:local_app_tt/services/owner_service.dart';
import 'package:local_app_tt/widgets/loginpage.dart';
import 'package:local_app_tt/widgets/role_gate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatefulWidget {
  final void Function(bool) onThemeToggle;

  const AuthGate({super.key, required this.onThemeToggle});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data?.session;
        final event = snapshot.data?.event;

        if (event == AuthChangeEvent.passwordRecovery) {
          return SetNewPasswordPage(onThemeToggle: widget.onThemeToggle);
        }

        if (session != null) {
          return _OwnerProfileGate(
            authService: _authService,
            onThemeToggle: widget.onThemeToggle,
          );
        }

        return LoginPage(
          key: ValueKey(Theme.of(context).brightness),
          onThemeToggle: widget.onThemeToggle,
        );
      },
    );
  }
}

class _OwnerProfileGate extends StatefulWidget {
  final AuthService authService;
  final void Function(bool) onThemeToggle;

  const _OwnerProfileGate({
    required this.authService,
    required this.onThemeToggle,
  });

  @override
  State<_OwnerProfileGate> createState() => _OwnerProfileGateState();
}

class _OwnerProfileGateState extends State<_OwnerProfileGate> {
  late Future<OwnerProfile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = widget.authService.ensureOwnerProfile();
  }

  void _retry() {
    setState(() {
      _profileFuture = widget.authService.ensureOwnerProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OwnerProfile>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'We could not load your profile. Please try again.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _retry,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final profile = snapshot.data;
        if (profile != null && profile.isIncomplete) {
          return CompleteProfilePage(
            ownerService: widget.authService.ownerService,
            onComplete: _retry,
          );
        }

        return const RoleGate();
      },
    );
  }
}
