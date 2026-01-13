import 'package:flutter/material.dart';
import 'package:local_app_tt/data/service_catalog.dart';
import 'package:local_app_tt/screens/externalservices.dart';
import 'package:local_app_tt/screens/home.dart';
import 'package:local_app_tt/screens/services.dart';
import 'package:local_app_tt/screens/settings.dart';
import 'package:local_app_tt/widgets/bottom_tab_nav.dart';
import 'package:local_app_tt/widgets/breadcrumbs.dart';
import 'package:local_app_tt/widgets/service_tile.dart';
import 'package:local_app_tt/widgets/responsive_scaffold.dart';

class InternalServices extends StatelessWidget {
  InternalServices({super.key});

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
    if (index == 2) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showBottomNav = MediaQuery.of(context).size.width < 1200;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.secondary.withOpacity(0.08),
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
                    const Breadcrumbs(items: ['Home', 'Services', 'Internal Services']),
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
                                'Internal Services',
                                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                'Team workflows and operational tools',
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
                  itemCount: internalServiceOptions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final option = internalServiceOptions[index];
                    return ServiceTile(
                      option: option,
                      index: index,
                      onTap: () => handleInternalServiceTap(context, option),
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
              currentIndex: 2,
              onTap: (index) => _handleBottomNavTap(context, index),
            )
          : null,
    );
  }
}
