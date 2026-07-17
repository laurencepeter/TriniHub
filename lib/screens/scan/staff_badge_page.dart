import 'dart:async';

import 'package:flutter/material.dart';
import 'package:local_app_tt/navigation/app_navigation.dart';
import 'package:local_app_tt/services/staff_badge_token.dart';
import 'package:local_app_tt/widgets/breadcrumbs.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shows the signed-in staff member's personal, auto-rotating badge QR.
///
/// A colleague scans this from the Scan File flow to hand a file over to this
/// person. The QR carries a token that expires after 60 seconds and reissues
/// itself, so a screenshot goes stale quickly.
class StaffBadgePage extends StatefulWidget {
  const StaffBadgePage({super.key});

  static const Duration _ttl = Duration(seconds: 60);

  @override
  State<StaffBadgePage> createState() => _StaffBadgePageState();
}

class _StaffBadgePageState extends State<StaffBadgePage> {
  Timer? _ticker;
  StaffBadgeToken? _token;

  @override
  void initState() {
    super.initState();
    _token = _createToken();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final token = _token;
      if (token == null || token.isExpired) {
        setState(() => _token = _createToken());
      } else {
        setState(() {}); // refresh the countdown
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  StaffBadgeToken? _createToken() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;
    final metadata = user.userMetadata;
    final rawName = metadata?['full_name'] ??
        metadata?['name'] ??
        metadata?['display_name'] ??
        user.email;
    final label = (rawName?.toString().trim().isNotEmpty ?? false)
        ? rawName.toString().trim()
        : 'Staff member';
    return StaffBadgeToken.issue(
      userId: user.id,
      label: label,
      ttl: StaffBadgePage._ttl,
    );
  }

  void _issue() => setState(() => _token = _createToken());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final token = _token;
    final signedIn = Supabase.instance.client.auth.currentUser != null;
    final remaining = token?.remaining.inSeconds ?? 0;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            Breadcrumbs(
              items: [
                BreadcrumbItem('Home', onTap: () => AppNavigation.goHome(context)),
                BreadcrumbItem('Scan File', onTap: () => AppNavigation.backOrHome(context)),
                const BreadcrumbItem('My Badge'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  tooltip: 'Back',
                  onPressed: () => AppNavigation.backOrHome(context),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'My Staff Badge',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!signedIn)
              _InfoCard(
                icon: Icons.lock_outline,
                text: 'Sign in to display your staff badge.',
              )
            else if (token != null) ...[
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.black.withOpacity(0.06)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: QrImageView(
                          data: token.encode(),
                          version: QrVersions.auto,
                          size: 220,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        token.label,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Show this to a colleague to receive a file',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Refreshes in $remaining s',
                    style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _issue,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refresh now'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: (remaining / StaffBadgePage._ttl.inSeconds).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.surfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              _InfoCard(
                icon: Icons.privacy_tip_outlined,
                text: 'Your badge is valid for 60 seconds at a time so a screenshot '
                    'can\'t be reused later.',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.hintColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            ),
          ),
        ],
      ),
    );
  }
}
