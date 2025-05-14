import 'package:flutter/material.dart';

class ResponsiveButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const ResponsiveButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    double buttonWidth;

    if (screenWidth < 600) {
      // Mobile
      buttonWidth = screenWidth * 0.8;
    } else if (screenWidth < 1200) {
      // Tablet
      buttonWidth = screenWidth * 0.4;
    } else {
      // Desktop
      buttonWidth = screenWidth * 0.25;
    }

    return Center(
      child: SizedBox(
        width: buttonWidth,
        child: ElevatedButton(
          onPressed: onPressed,
          child: Text(label),
        ),
      ),
    );
  }
}
