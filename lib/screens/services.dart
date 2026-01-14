import 'package:flutter/material.dart';
import 'package:local_app_tt/data/service_catalog.dart';
import 'package:local_app_tt/screens/externalservices.dart';
import 'package:local_app_tt/screens/home.dart';
import 'package:local_app_tt/screens/internalservices.dart';
import 'package:local_app_tt/screens/settings.dart';
import 'package:local_app_tt/widgets/bottom_tab_nav.dart';
import 'package:local_app_tt/widgets/breadcrumbs.dart';
import 'package:local_app_tt/widgets/responsive_scaffold.dart';

class ServicesPage extends StatefulWidget {
  final String device;

  const ServicesPage({
    super.key,
    required this.device,
  });

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> with TickerProviderStateMixin {
  bool _showInternal = false;
  bool _showExternal = false;

  void _handleBottomNavTap(BuildContext context, int index) {
    if (index == 1) {
      return;
    }
    Widget destination;
    switch (index) {
      case 0:
        destination = ResponsiveScaffold(
          childBuilder: (device) => HomePage(device: device),
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

  void _toggleInternal() {
    setState(() {
      _showInternal = !_showInternal;
    });
  }

  void _toggleExternal() {
    setState(() {
      _showExternal = !_showExternal;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showBottomNav = MediaQuery.of(context).size.width < 1200;
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
              Breadcrumbs(
                items: [
                  BreadcrumbItem(
                    'Home',
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResponsiveScaffold(
                            childBuilder: (device) => HomePage(device: device),
                          ),
                        ),
                      );
                    },
                  ),
                  const BreadcrumbItem('Services'),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Services',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Browse available service lanes and launch tools from your ${widget.device} workspace.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
              ),
              const SizedBox(height: 20),
              _CategoryToggleButton(
                title: 'Internal services',
                subtitle: 'Operations, compliance, and internal requests.',
                icon: Icons.apartment_rounded,
                isExpanded: _showInternal,
                accentColor: theme.colorScheme.secondary,
                onTap: _toggleInternal,
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: _showInternal
                    ? _ServiceList(
                        options: internalServiceOptions,
                        onTap: (option) => handleInternalServiceTap(context, option),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              _CategoryToggleButton(
                title: 'External services',
                subtitle: 'Community-facing submissions and permits.',
                icon: Icons.public,
                isExpanded: _showExternal,
                accentColor: theme.colorScheme.primary,
                onTap: _toggleExternal,
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: _showExternal
                    ? _ServiceList(
                        options: externalServiceOptions,
                        onTap: (option) => handleExternalServiceTap(context, option),
                      )
                    : const SizedBox.shrink(),
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
      bottomNavigationBar: showBottomNav
          ? BottomNavBar(
              currentIndex: 1,
              onTap: (index) => _handleBottomNavTap(context, index),
            )
          : null,
    );
  }
}

class _CategoryToggleButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isExpanded;
  final Color accentColor;
  final VoidCallback onTap;

  const _CategoryToggleButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isExpanded,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isExpanded ? accentColor.withOpacity(0.12) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded ? accentColor.withOpacity(0.5) : theme.dividerColor.withOpacity(0.2),
        ),
        boxShadow: [
          if (isExpanded)
            BoxShadow(
              color: accentColor.withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: accentColor),
        title: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: AnimatedRotation(
          turns: isExpanded ? 0.5 : 0,
          duration: const Duration(milliseconds: 200),
          child: const Icon(Icons.keyboard_arrow_down_rounded),
        ),
      ),
    );
  }
}

class _ServiceList extends StatelessWidget {
  final List<ServiceOption> options;
  final ValueChanged<ServiceOption> onTap;

  const _ServiceList({
    required this.options,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Column(
        children: options
            .map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  elevation: 0,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => onTap(option),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.dividerColor.withOpacity(0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: option.accentColor.withOpacity(0.15),
                            child: Icon(option.icon, color: option.accentColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  option.label,
                                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  option.description,
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
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
            )
            .toList(),
      ),
    );
  }
}
