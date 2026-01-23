import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class BaseVersionFooter extends StatelessWidget {
  const BaseVersionFooter({super.key});

  Future<String> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    final appName = info.appName.trim().isEmpty ? 'Trini Hub' : info.appName;
    final buildSuffix = info.buildNumber.isEmpty ? '' : '+${info.buildNumber}';
    return '$appName v${info.version}$buildSuffix';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SizedBox(
          width: double.infinity,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.dividerColor.withOpacity(0.6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: FutureBuilder<String>(
                  future: _loadVersion(),
                  builder: (context, snapshot) {
                    final label = snapshot.data ?? 'Trini Hub';
                    return Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
