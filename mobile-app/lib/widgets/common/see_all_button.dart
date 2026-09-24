import 'package:flutter/material.dart';
import 'package:qspot/themes/app_theme.dart';

// import '../themes/app_theme.dart';
class SeeAllButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;

  const SeeAllButton({
    super.key,
    required this.onPressed,
    this.text = 'See All',
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppTheme.gradientEnd,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.paddingSmall,
          vertical: AppTheme.paddingSmall / 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppTheme.gradientEnd,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.arrow_forward_ios,
            color: AppTheme.gradientEnd,
            size: 12,
          ),
        ],
      ),
    );
  }
}
