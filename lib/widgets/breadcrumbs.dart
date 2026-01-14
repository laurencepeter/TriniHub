import 'package:flutter/material.dart';

class BreadcrumbItem {
  final String label;
  final VoidCallback? onTap;

  const BreadcrumbItem(
    this.label, {
    this.onTap,
  });
}

class Breadcrumbs extends StatelessWidget {
  final List<BreadcrumbItem> items;

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
          _BreadcrumbLink(
            label: items[index].label,
            onTap: items[index].onTap,
            isCurrent: index == items.length - 1,
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

class _BreadcrumbLink extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isCurrent;

  const _BreadcrumbLink({
    required this.label,
    required this.onTap,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.labelLarge?.copyWith(
      color: isCurrent ? theme.colorScheme.onSurface : theme.colorScheme.primary,
      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
    );

    if (isCurrent || onTap == null) {
      return Text(label, style: textStyle);
    }

    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: theme.colorScheme.primary,
      ),
      child: Text(label, style: textStyle),
    );
  }
}
