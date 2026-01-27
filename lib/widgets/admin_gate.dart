import 'package:flutter/material.dart';
import 'package:local_app_tt/services/user_role_service.dart';

class AdminGate extends StatefulWidget {
  final Widget child;

  const AdminGate({super.key, required this.child});

  @override
  State<AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<AdminGate> {
  final UserRoleService _roleService = UserRoleService();
  late Future<AppRole> _roleFuture;

  @override
  void initState() {
    super.initState();
    _roleFuture = _roleService.fetchCurrentRole();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<AppRole>(
      future: _roleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final role = snapshot.data ?? AppRole.public;
        if (role == AppRole.admin) {
          return widget.child;
        }
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: 48, color: theme.colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    'Admin access required',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your account does not have permission to view this area.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/public',
                        (route) => false,
                      );
                    },
                    child: const Text('Return to home'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
