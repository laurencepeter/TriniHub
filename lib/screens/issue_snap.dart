import 'package:flutter/material.dart';
import 'package:local_app_tt/widgets/responsive_scaffold.dart';

class IssueSnapScreen extends StatefulWidget {
  const IssueSnapScreen({super.key});

  static Route<void> route() {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (context, animation, secondaryAnimation) => ResponsiveScaffold(
        childBuilder: (device) => const IssueSnapScreen(),
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<IssueSnapScreen> createState() => _IssueSnapScreenState();
}

class _IssueSnapScreenState extends State<IssueSnapScreen> {
  bool _photoMismatch = false;
  bool _voted = false;

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
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _HeroHeader(
                  onClose: () => Navigator.popUntil(context, (route) => route.isFirst),
                  onBack: () => Navigator.pop(context),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      _CaptureCard(),
                      const SizedBox(height: 16),
                      _GeoTagCard(),
                      const SizedBox(height: 16),
                      _DuplicateAlert(
                        photoMismatch: _photoMismatch,
                        voted: _voted,
                        onMismatchChanged: (value) {
                          setState(() {
                            _photoMismatch = value;
                          });
                        },
                        onVote: () {
                          setState(() {
                            _voted = true;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _NextStepsPanel(photoMismatch: _photoMismatch, voted: _voted),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onClose;

  const _HeroHeader({required this.onBack, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withOpacity(0.7),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.3),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    'External Service',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'CivSnap',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Snap a photo, auto-geotag, and check if the issue is already logged within 5 meters.',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _HeroChip(label: 'Camera ready'),
                const SizedBox(width: 8),
                _HeroChip(label: 'Auto-match enabled'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final String label;

  const _HeroChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white),
      ),
    );
  }
}

class _CaptureCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.camera_alt_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Capture evidence',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_camera, size: 40, color: theme.colorScheme.primary),
                  const SizedBox(height: 8),
                  Text('Tap to snap a photo', style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text('Enhance photo'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Open camera'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GeoTagCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.surface,
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Geotag details',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: theme.colorScheme.primary.withOpacity(0.08),
            ),
            child: Column(
              children: [
                _DetailRow(label: 'Latitude', value: '10.6629° N'),
                const SizedBox(height: 8),
                _DetailRow(label: 'Longitude', value: '61.5123° W'),
                const SizedBox(height: 8),
                _DetailRow(label: 'Accuracy', value: '± 3.9 m'),
                const SizedBox(height: 8),
                _DetailRow(label: 'Nearby landmark', value: 'Queen St & Charlotte'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.my_location),
            label: const Text('Refresh location'),
          ),
        ],
      ),
    );
  }
}

class _DuplicateAlert extends StatelessWidget {
  final bool photoMismatch;
  final bool voted;
  final ValueChanged<bool> onMismatchChanged;
  final VoidCallback onVote;

  const _DuplicateAlert({
    required this.photoMismatch,
    required this.voted,
    required this.onMismatchChanged,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.near_me, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Nearby issue detected',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'We found an issue already logged within 4.6 meters. Compare the photo before submitting a new report.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.image_outlined, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pothole - lane 2', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Text('Reported 35 min ago · 2 community votes', style: theme.textTheme.bodySmall),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.place, size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 4),
                          Text('4.6 m away', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: photoMismatch,
            onChanged: (value) => onMismatchChanged(value ?? false),
            contentPadding: EdgeInsets.zero,
            title: const Text('Photo does not match my issue'),
            subtitle: const Text('Submit a new report if the issue is different.'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: voted ? null : onVote,
                  icon: Icon(voted ? Icons.check_circle : Icons.how_to_vote),
                  label: Text(voted ? 'Voted' : 'Vote for this issue'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: photoMismatch ? () {} : null,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Submit new issue'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NextStepsPanel extends StatelessWidget {
  final bool photoMismatch;
  final bool voted;

  const _NextStepsPanel({required this.photoMismatch, required this.voted});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String message;
    if (photoMismatch) {
      message = 'A new report can be created because the photo does not match. We will notify you if a duplicate appears later.';
    } else if (voted) {
      message = 'Thanks for voting. We will keep you updated on the existing issue and add your confirmation.';
    } else {
      message = 'Review the matched issue. Vote to confirm it or flag that your issue is different.';
    }
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.surface,
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next steps',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(message, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
        ),
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
