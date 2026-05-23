import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class AuthScreenShell extends StatelessWidget {
  const AuthScreenShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.form,
    this.footer,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final Widget form;
  final Widget? footer;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          const _AuthBackground(),
          SafeArea(
            child: Column(
              children: [
                if (onBack != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8, top: 4),
                      child: IconButton(
                        tooltip: 'Back',
                        onPressed: onBack,
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: AppTheme.primaryDark,
                      ),
                    ),
                  ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          children: [
                            _AuthBrandHeader(
                              title: title,
                              subtitle: subtitle,
                              textTheme: textTheme,
                            ),
                            const SizedBox(height: 32),
                            form,
                            if (footer != null) ...[
                              const SizedBox(height: 28),
                              footer!,
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthBackground extends StatelessWidget {
  const _AuthBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.authGradientTop,
            AppTheme.authGradientMid,
            AppTheme.authGradientBottom,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: _GlowOrb(
              size: 220,
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -40,
            child: _GlowOrb(
              size: 180,
              color: AppTheme.accentColor.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class _AuthBrandHeader extends StatelessWidget {
  const _AuthBrandHeader({
    required this.title,
    required this.subtitle,
    required this.textTheme,
  });

  final String title;
  final String subtitle;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: AppTheme.authSurface,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.12),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryDark.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Image.asset('assets/images/logo.png'),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: textTheme.headlineMedium?.copyWith(fontSize: 26),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class AuthFormCard extends StatelessWidget {
  const AuthFormCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.authSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.authBorder),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: child,
      ),
    );
  }
}

class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14),
      ),
    );
  }
}

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _AuthBanner(
      message: message,
      icon: Icons.error_outline_rounded,
      color: AppTheme.errorColor,
    );
  }
}

class AuthSuccessBanner extends StatelessWidget {
  const AuthSuccessBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _AuthBanner(
      message: message,
      icon: Icons.check_circle_outline_rounded,
      color: AppTheme.successColor,
    );
  }
}

class _AuthBanner extends StatelessWidget {
  const _AuthBanner({
    required this.message,
    required this.icon,
    required this.color,
  });

  final String message;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.loadingLabel,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final String loadingLabel;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: isLoading
            ? Row(
                key: const ValueKey('loading'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(loadingLabel),
                ],
              )
            : Text(label, key: const ValueKey('label')),
      ),
    );
  }
}
