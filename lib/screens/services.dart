import 'package:flutter/material.dart';

class ServicesPage extends StatelessWidget {
  final String device;

  const ServicesPage({
    super.key,
    required this.device,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.secondary.withOpacity(0.06),
              theme.colorScheme.surface,
              theme.colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              Text(
                'Services',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Browse available service lanes and launch tools from your $device workspace.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 0,
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: const ListTile(
                  leading: Icon(Icons.apartment_rounded),
                  title: Text('Internal services'),
                  subtitle: Text('Operations, compliance, and internal requests.'),
                  trailing: Icon(Icons.chevron_right),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: const ListTile(
                  leading: Icon(Icons.public),
                  title: Text('External services'),
                  subtitle: Text('Community-facing submissions and permits.'),
                  trailing: Icon(Icons.chevron_right),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: const ListTile(
                  leading: Icon(Icons.qr_code_scanner),
                  title: Text('Internal QR scanning'),
                  subtitle: Text('Record assets as they move through departments.'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
