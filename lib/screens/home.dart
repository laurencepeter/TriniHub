import 'package:flutter/material.dart';
import 'package:local_app_tt/screens/dog_submissions.dart';
import 'package:local_app_tt/screens/externalservices.dart';
import 'package:local_app_tt/screens/internalservices.dart';
import 'package:local_app_tt/screens/services.dart';
import 'package:local_app_tt/screens/settings.dart';
import 'package:local_app_tt/services/dog_registration_service.dart';
import 'package:local_app_tt/widgets/bottom_tab_nav.dart';
import 'package:local_app_tt/widgets/breadcrumbs.dart';
import 'package:local_app_tt/widgets/responsive_scaffold.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  final String device;

  const HomePage({
    super.key,
    required this.device,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  final DogRegistrationService _registrationService = DogRegistrationService.instance;
  late final Future<List<DogSubmission>> _submissionsFuture;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..forward();
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _submissionsFuture = _registrationService.fetchSubmissions();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleBottomNavTap(BuildContext context, int index) {
    if (index == 0) {
      return;
    }
    Widget destination;
    switch (index) {
      case 1:
        destination = ResponsiveScaffold(
          childBuilder: (device) => ServicesPage(device: device),
        );
        break;
      case 2:
        destination = ResponsiveScaffold(
          childBuilder: (device) => InternalServices(),
        );
        break;
      case 3:
        destination = ResponsiveScaffold(
          childBuilder: (device) => ExternalServices(),
        );
        break;
      case 4:
        destination = ResponsiveScaffold(
          childBuilder: (device) => SettingsPage(device: device),
        );
        break;
      default:
        destination = ResponsiveScaffold(
          childBuilder: (device) => HomePage(device: device),
        );
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  String _resolveUserName() {
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata;
    final rawName = metadata?['full_name'] ??
        metadata?['name'] ??
        metadata?['display_name'] ??
        user?.email;
    if (rawName == null) {
      return 'there';
    }
    final trimmed = rawName.toString().trim();
    if (trimmed.isEmpty) {
      return 'there';
    }
    if (trimmed.contains('@')) {
      final handle = trimmed.split('@').first;
      return handle.isEmpty ? 'there' : handle;
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showBottomNav = MediaQuery.of(context).size.width < 1200;
    final userName = _resolveUserName();
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.12),
              theme.colorScheme.surface,
              theme.colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Breadcrumbs(items: [BreadcrumbItem('Home')]),
                const SizedBox(height: 10),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                      child: Image.asset(
                        'lib/assets/images/TriniHub.png',
                        width: 26,
                        height: 26,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trini Hub',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Service command center',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: theme.colorScheme.surfaceVariant,
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, $userName',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Your services, streamlined',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Pick a service lane to launch forms, track requests, and keep every workflow moving.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: const [
                            _HighlightPill(label: '24/7 service access'),
                            _HighlightPill(label: 'Real-time status updates'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Services',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _AnimatedServiceCard(
                  controller: _controller,
                  delay: 0,
                  title: 'Internal Services',
                  subtitle: 'Team tools and operational workflows',
                  icon: Icons.apartment_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ResponsiveScaffold(
                          childBuilder: (device) => InternalServices(),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _AnimatedServiceCard(
                  controller: _controller,
                  delay: 0.15,
                  title: 'External Services',
                  subtitle: 'Public-facing utilities and citizen support',
                  icon: Icons.public,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ResponsiveScaffold(
                          childBuilder: (device) => ExternalServices(),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'Pending submissions',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _SubmissionOverviewCard(submissionsFuture: _submissionsFuture),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: showBottomNav
          ? BottomNavBar(
              currentIndex: 0,
              onTap: (index) => _handleBottomNavTap(context, index),
            )
          : null,
    );
  }
}

class _HighlightPill extends StatelessWidget {
  final String label;

  const _HighlightPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _AnimatedServiceCard extends StatelessWidget {
  final AnimationController controller;
  final double delay;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _AnimatedServiceCard({
    required this.controller,
    required this.delay,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(delay, 1, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(animation),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(color: Colors.black.withOpacity(0.06)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                    child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SubmissionOverviewCard extends StatelessWidget {
  final Future<List<DogSubmission>> submissionsFuture;

  const _SubmissionOverviewCard({required this.submissionsFuture});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<DogSubmission>>(
      future: submissionsFuture,
      builder: (context, snapshot) {
        final submissions = snapshot.data ?? [];
        final pendingCount = submissions.where((item) => item.status == 'pending').length;
        final statusLabel = pendingCount > 0
            ? '$pendingCount pending approval'
            : submissions.isEmpty
                ? 'No submissions yet'
                : 'All submissions approved';
        final statusColor = pendingCount > 0
            ? Colors.orange
            : submissions.isEmpty
                ? theme.hintColor
                : Colors.green;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                    child: Icon(Icons.pets, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dog Registration',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          statusLabel,
                          style: theme.textTheme.bodySmall?.copyWith(color: statusColor),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      pendingCount > 0 ? 'Pending' : 'Up to date',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting)
                Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Loading status...',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                    ),
                  ],
                )
              else if (snapshot.hasError)
                Text(
                  'Unable to load submissions.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                )
              else if (submissions.isEmpty)
                Text(
                  'Start a new submission to track its status from here.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                )
              else
                Text(
                  '${submissions.length} submission${submissions.length == 1 ? '' : 's'} total.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ResponsiveScaffold(
                          childBuilder: (device) => const DogSubmissionsScreen(),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('View submissions'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
