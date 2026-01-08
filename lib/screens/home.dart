import 'package:flutter/material.dart';
import 'package:local_app_tt/screens/externalservices.dart';
import 'package:local_app_tt/screens/internalservices.dart';

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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..forward();
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                          'Service Directory',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Choose a service type to continue',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Services',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _AnimatedServiceCard(
                  controller: _controller,
                  delay: 0,
                  title: 'Internal Services',
                  subtitle: 'Team tools and resources',
                  icon: Icons.apartment_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => InternalServices()),
                    );
                  },
                ),
                const SizedBox(height: 14),
                _AnimatedServiceCard(
                  controller: _controller,
                  delay: 0.15,
                  title: 'External Services',
                  subtitle: 'Public-facing utilities',
                  icon: Icons.public,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ExternalServices()),
                    );
                  },
                ),
                const Spacer(),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Need to register a dog? Find it under External Services.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                  ),
                ),
              ],
            ),
          ),
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
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(color: Colors.black.withOpacity(0.06)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                    child: Icon(icon, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: TextStyle(color: Theme.of(context).hintColor),
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
