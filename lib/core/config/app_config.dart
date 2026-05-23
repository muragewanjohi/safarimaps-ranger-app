import '../../core/constants/app_constants.dart';

class AppConfig {
  static const String appName = 'SafariMap GameWarden';
  static const String appVersion = '1.0.4';
  static const bool useMockData = AppConstants.useMockData;
  static const bool useSupabase = true;

  static const String primaryColor = '#2E7D32';
  static const String secondaryColor = '#4CAF50';
  static const String errorColor = '#ff6b6b';
  static const String warningColor = '#ff9500';
  static const String successColor = '#4caf50';

  static const int mockApiDelayMs = 500;
  static const String passwordResetRedirect = 'ranger://reset-password';
}
