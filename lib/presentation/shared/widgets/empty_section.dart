import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class EmptySectionMessage extends StatelessWidget {
  const EmptySectionMessage({
    super.key,
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.authBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.authMutedText.withValues(alpha: 0.7)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.authMutedText,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
