import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RoleGate extends StatefulWidget {
  const RoleGate({super.key});

  @override
  State<RoleGate> createState() => _RoleGateState();
}

class _RoleGateState extends State<RoleGate> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _resolveRoleAndNavigate();
  }

  Future<void> _resolveRoleAndNavigate() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final client = Supabase.instance.client;
    try {
      await client.auth.refreshSession();

      final session = client.auth.currentSession;
      final appMetadata = session?.user.appMetadata ?? <String, dynamic>{};
      final hasRoleClaim = appMetadata.containsKey('app_role');
      String? role = appMetadata['app_role']?.toString();
      String? corporationId = appMetadata['corporation_id']?.toString();

      if (!hasRoleClaim || role == null || role.isEmpty) {
        final profile = await client
            .from('my_profile')
            .select('role, corporation_id')
            .maybeSingle();
        if (profile is Map<String, dynamic>) {
          role = profile['role']?.toString();
          corporationId = profile['corporation_id']?.toString();
        }
      }

      if (!mounted) {
        return;
      }

      final targetRoute = _routeForRole(role);
      Navigator.of(context).pushReplacementNamed(
        targetRoute,
        arguments: {
          'role': role ?? 'public_user',
          'corporation_id': corporationId,
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Unable to load your access level. Please try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
      );
    } finally {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
    }
  }

  String _routeForRole(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return '/admin';
      case 'corp_staff':
      case 'corp':
      case 'corporation':
        return '/corp';
      default:
        return '/public';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage ?? 'Preparing your workspace...',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _resolveRoleAndNavigate,
                    child: const Text('Retry'),
                  ),
                ],
              ),
      ),
    );
  }
}
