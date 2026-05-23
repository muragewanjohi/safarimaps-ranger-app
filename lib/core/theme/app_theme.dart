import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color secondaryColor = Color(0xFF4CAF50);
  static const Color accentColor = Color(0xFF8D6E63);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color warningColor = Color(0xFFFF9500);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color backgroundColor = Color(0xFFF1F5F1);
  static const Color surfaceColor = Color(0xFFFFFFFF);

  static TextStyle monoStyle({
    double fontSize = 13,
    Color? color,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return TextStyle(
      fontFamily: 'SpaceMono',
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
    );
  }

  static TextTheme uiTextTheme(TextTheme base) {
    return base.apply(fontFamily: uiFontFamily).copyWith(
          titleLarge: base.titleLarge?.copyWith(
            fontFamily: uiFontFamily,
            fontWeight: FontWeight.w700,
            color: primaryDark,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontFamily: uiFontFamily,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
          bodyLarge: base.bodyLarge?.copyWith(
            fontFamily: uiFontFamily,
            color: const Color(0xFF334155),
          ),
          bodyMedium: base.bodyMedium?.copyWith(
            fontFamily: uiFontFamily,
            color: authMutedText,
          ),
          bodySmall: base.bodySmall?.copyWith(
            fontFamily: uiFontFamily,
            color: authMutedText,
          ),
          labelLarge: base.labelLarge?.copyWith(
            fontFamily: uiFontFamily,
            fontWeight: FontWeight.w600,
          ),
        );
  }

  // Auth / landing screen palette — warm savanna tones
  static const Color authGradientTop = Color(0xFFF8F4EC);
  static const Color authGradientMid = Color(0xFFEAF2E6);
  static const Color authGradientBottom = Color(0xFFD5E6D0);
  static const Color authSurface = Color(0xFFFFFFFF);
  static const Color authMutedText = Color(0xFF64748B);
  static const Color authBorder = Color(0xFFE2E8F0);

  static String get uiFontFamily {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return '.AppleSystemUIFont';
      default:
        return 'Roboto';
    }
  }

  static TextTheme authTextTheme(TextTheme base) {
    return base.apply(fontFamily: uiFontFamily).copyWith(
          headlineMedium: base.headlineMedium?.copyWith(
            fontFamily: uiFontFamily,
            fontWeight: FontWeight.w700,
            color: primaryDark,
            letterSpacing: -0.5,
            height: 1.2,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontFamily: uiFontFamily,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
          bodyLarge: base.bodyLarge?.copyWith(
            fontFamily: uiFontFamily,
            color: authMutedText,
            height: 1.5,
          ),
          bodyMedium: base.bodyMedium?.copyWith(
            fontFamily: uiFontFamily,
            color: authMutedText,
          ),
          labelLarge: base.labelLarge?.copyWith(
            fontFamily: uiFontFamily,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        );
  }

  static ThemeData authTheme(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      textTheme: authTextTheme(base.textTheme),
      scaffoldBackgroundColor: authGradientTop,
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        fillColor: const Color(0xFFF8FAFC),
        labelStyle: TextStyle(
          fontFamily: uiFontFamily,
          color: authMutedText,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          fontFamily: uiFontFamily,
          color: authMutedText.withValues(alpha: 0.7),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primaryColor.withValues(alpha: 0.5),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: TextStyle(
            fontFamily: uiFontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: TextStyle(
            fontFamily: uiFontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: uiTextTheme(Typography.material2021(platform: TargetPlatform.android).black),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: surfaceColor,
        foregroundColor: primaryDark,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: uiFontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: primaryDark,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: authBorder),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primaryColor.withValues(alpha: 0.12),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontFamily: uiFontFamily,
              color: primaryDark,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            );
          }
          return TextStyle(
            fontFamily: uiFontFamily,
            color: authMutedText,
            fontSize: 12,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryDark, size: 24);
          }
          return IconThemeData(
            color: authMutedText.withValues(alpha: 0.85),
            size: 24,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
