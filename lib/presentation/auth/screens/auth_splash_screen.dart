import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class AuthSplashScreen extends StatelessWidget {
  const AuthSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
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
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                  'SafariMap GameWarden',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryDark,
                      ),
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
