import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../core/config/app_config.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._client);

  final supabase.SupabaseClient? _client;

  bool get isAvailable => _client != null;

  Future<AuthResult> login(LoginCredentials credentials) async {
    if (_client == null) {
      return const AuthResult(success: false, error: 'Supabase is not configured');
    }

    try {
      final response = await _client!.auth.signInWithPassword(
        email: credentials.email,
        password: credentials.password,
      );

      if (response.user == null) {
        return const AuthResult(success: false, error: 'Login failed');
      }

      final user = UserModel.fromAuthUser(response.user!);
      refreshUserProfileInBackground(response.user!.id);

      return AuthResult(
        success: true,
        user: user,
        message: 'Login successful',
      );
    } on supabase.AuthException catch (e) {
      return AuthResult(success: false, error: e.message);
    } catch (_) {
      return const AuthResult(success: false, error: 'Network error');
    }
  }

  Future<AuthResult> signup(SignupCredentials credentials) async {
    if (_client == null) {
      return const AuthResult(success: false, error: 'Supabase is not configured');
    }

    try {
      final avatar = credentials.name
          .split(' ')
          .where((n) => n.isNotEmpty)
          .map((n) => n[0])
          .join()
          .toUpperCase();

      final response = await _client!.auth.signUp(
        email: credentials.email,
        password: credentials.password,
        data: {
          'name': credentials.name,
          'role': credentials.role,
          'ranger_id': credentials.rangerId,
          'team': credentials.team,
          'avatar': avatar,
        },
      );

      if (response.user == null) {
        return const AuthResult(success: false, error: 'Signup failed');
      }

      await Future<void>.delayed(const Duration(seconds: 1));

      var profile = await _fetchProfile(response.user!.id);
      if (profile == null) {
        await _client!.rpc('create_user_profile', params: {
          'user_id': response.user!.id,
          'user_name': credentials.name,
          'user_email': credentials.email,
          'user_role': credentials.role,
          'ranger_id': credentials.rangerId,
          'team': credentials.team,
        });
        profile = await _fetchProfile(response.user!.id);
      }

      if (profile == null) {
        return const AuthResult(
          success: false,
          error: 'Failed to create user profile',
        );
      }

      return AuthResult(
        success: true,
        user: UserModel.fromProfile(profile, email: response.user!.email),
        message: 'Account created successfully',
      );
    } on supabase.AuthException catch (e) {
      return AuthResult(success: false, error: e.message);
    } catch (_) {
      return const AuthResult(success: false, error: 'Network error');
    }
  }

  Future<AuthResult> logout() async {
    if (_client == null) {
      return const AuthResult(success: false, error: 'Supabase is not configured');
    }

    try {
      await _client!.auth.signOut();
      return const AuthResult(success: true, message: 'Logged out successfully');
    } on supabase.AuthException catch (e) {
      return AuthResult(success: false, error: e.message);
    }
  }

  UserModel? getLocalUser() {
    if (_client == null) return null;

    final user = _client!.auth.currentUser;
    if (user == null) return null;

    return UserModel.fromAuthUser(user);
  }

  Future<UserModel?> getCurrentUser() async {
    final sessionUser = getLocalUser();
    if (sessionUser == null) return null;

    try {
      final profile = await _fetchProfile(sessionUser.id).timeout(
        const Duration(seconds: 5),
      );
      if (profile != null) {
        return UserModel.fromProfile(
          profile,
          email: _client!.auth.currentUser?.email,
        );
      }
    } catch (_) {}

    return sessionUser;
  }

  Future<UserModel?> getUserProfile(String userId) async {
    if (_client == null) return null;

    try {
      var profile = await _fetchProfile(userId);
      if (profile == null) {
        profile = await _createProfileForExistingUser(userId);
      }
      if (profile == null) return null;

      final email = _client!.auth.currentUser?.email;
      return UserModel.fromProfile(profile, email: email);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchProfile(String userId) async {
    final result = await _client!
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return result;
  }

  void refreshUserProfileInBackground(String userId) {
    Future<void>(() async {
      try {
        await getUserProfile(userId).timeout(const Duration(seconds: 10));
      } catch (_) {}
    });
  }

  void refreshSessionInBackground() {
    Future<void>(() async {
      if (_client == null) return;

      try {
        final session = _client!.auth.currentSession;
        if (session == null || !session.isExpired) return;

        await _client!.auth.refreshSession().timeout(
          const Duration(seconds: 10),
        );
      } catch (_) {}
    });
  }

  Future<Map<String, dynamic>?> _createProfileForExistingUser(
    String userId,
  ) async {
    final user = _client!.auth.currentUser;
    if (user == null) return null;

    await _client!.rpc('create_user_profile', params: {
      'user_id': userId,
      'user_name': user.userMetadata?['name'] ?? 'New User',
      'user_email': user.email ?? '',
      'user_role': 'Visitor',
      'ranger_id': null,
      'team': null,
    });

    return _fetchProfile(userId);
  }

  Future<bool> isAuthenticated() async {
    if (_client == null) return false;
    return _client!.auth.currentSession != null;
  }

  Stream<supabase.AuthState> get authStateChanges =>
      _client?.auth.onAuthStateChange ?? const Stream.empty();

  Future<AuthResult> resetPassword(String email) async {
    if (_client == null) {
      return const AuthResult(success: false, error: 'Supabase is not configured');
    }

    try {
      await _client!.auth.resetPasswordForEmail(
        email,
        redirectTo: AppConfig.passwordResetRedirect,
      );
      return const AuthResult(
        success: true,
        message: 'Password reset email sent',
      );
    } on supabase.AuthException catch (e) {
      return AuthResult(success: false, error: e.message);
    }
  }

  bool validateEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  String? validatePassword(String password) {
    if (password.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    if (password.length > 50) {
      return 'Password must be less than 50 characters';
    }
    return null;
  }

  bool validateRangerId(String rangerId) {
    return RegExp(r'^[A-Z]{3}-\d{3}$').hasMatch(rangerId);
  }
}
