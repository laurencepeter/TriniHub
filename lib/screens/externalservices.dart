import 'package:flutter/material.dart';
import 'package:local_app_tt/data/service_catalog.dart';
import 'package:local_app_tt/screens/home.dart';
import 'package:local_app_tt/screens/internalservices.dart';
import 'package:local_app_tt/screens/services.dart';
import 'package:local_app_tt/screens/settings.dart';
import 'package:local_app_tt/widgets/bottom_tab_nav.dart';
import 'package:local_app_tt/widgets/breadcrumbs.dart';
import 'package:local_app_tt/widgets/service_tile.dart';
import 'package:local_app_tt/widgets/responsive_scaffold.dart';

class ExternalServices extends StatelessWidget {
  ExternalServices({super.key});

  String _deviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) {
      return 'Desktop';
    }
    if (width >= 600) {
      return 'Tablet';
    }
    return 'Mobile';
  }

  void _handleBottomNavTap(BuildContext context, int index) {
    if (index == 3) {
      return;
    }
    final device = _deviceType(context);
    Widget destination;
    switch (index) {
      case 0:
        destination = ResponsiveScaffold(
          childBuilder: (device) => HomePage(device: device),
        );
        break;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showBottomNav = MediaQuery.of(context).size.width < 1200;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.08),
              theme.colorScheme.surface,
              theme.colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                  childBuilder: (device) => HomePage(device: _deviceType(context)),
                                ),
                              ),
                            );
                          },
                        ),
                        BreadcrumbItem(
                          'Services',
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ResponsiveScaffold(
                                  childBuilder: (device) => ServicesPage(device: _deviceType(context)),
                                ),
                              ),
                            );
                          },
                        ),
                        const BreadcrumbItem('External Services'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'External Services',
                                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                'Public-facing tools and citizen requests',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  itemCount: externalServiceOptions.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == externalServiceOptions.length) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: theme.colorScheme.surface,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                          border: Border.all(color: Colors.black.withOpacity(0.05)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                              child: Icon(Icons.lightbulb_outline, color: theme.colorScheme.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Need to register a dog? Select Dog Registration to begin the form.',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    final option = externalServiceOptions[index];
                    return ServiceTile(
                      option: option,
                      index: index,
                      onTap: () => handleExternalServiceTap(context, option),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: showBottomNav
          ? BottomNavBar(
              currentIndex: 3,
              onTap: (index) => _handleBottomNavTap(context, index),
            )
          : null,
    );
  }
}
