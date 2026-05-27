import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'app.dart';
import 'core/constants/app_constants.dart';
import 'core/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Programmatically configure the Mapbox access token for all map components
  MapboxOptions.setAccessToken(AppConstants.mapboxPublicToken);

  await _initializeSupabase();
  await configureDependencies();

  runApp(const RangerApp());
}

Future<void> _initializeSupabase() async {
  final supabaseUrl = AppConstants.supabaseUrl;
  final supabaseKey = AppConstants.supabaseAnonKey;

  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) return;

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: true,
      ),
    ).timeout(const Duration(seconds: 8));
  } on TimeoutException {
    debugPrint(
      'Supabase initialization timed out. Auth will retry once the client is ready.',
    );
  } catch (error, stackTrace) {
    debugPrint('Supabase initialization failed: $error');
    debugPrint('$stackTrace');
  }
}