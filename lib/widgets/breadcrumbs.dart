import 'package:flutter/material.dart';

class Breadcrumbs extends StatelessWidget {
  final List<String> items;

  const Breadcrumbs({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: [
        for (int index = 0; index < items.length; index++) ...[
          Text(
            items[index],
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: index == items.length - 1 ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          if (index != items.length - 1)
            Icon(
              Icons.chevron_right,
              size: 16,
              color: theme.colorScheme.primary.withOpacity(0.6),
            ),
        ],
      ],
    );
  }
}
