import 'package:flutter/material.dart';
import 'package:local_app_tt/utils/base_version.dart';

class BaseVersionFooter extends StatelessWidget {
  const BaseVersionFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Base v$baseVersion',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
