import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class RangerAppBar extends StatelessWidget implements PreferredSizeWidget {
  const RangerAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  @override
  Size get preferredSize => Size.fromHeight(subtitle != null ? 72 : 56);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppTheme.surfaceColor,
      foregroundColor: AppTheme.primaryDark,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleSpacing: 20,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: AppTheme.authBorder,
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryDark,
              letterSpacing: -0.3,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: textTheme.bodySmall?.copyWith(
                color: AppTheme.authMutedText,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
      actions: [
        ...?actions,
        const SizedBox(width: 8),
      ],
    );
  }
}

class RangerIconAction extends StatelessWidget {
  const RangerIconAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
        foregroundColor: AppTheme.primaryDark,
      ),
      icon: Icon(icon, size: 20),
    );
  }
}
