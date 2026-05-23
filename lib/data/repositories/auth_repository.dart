import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepository {
  AuthRepository(this._dataSource);

  final AuthRemoteDataSource _dataSource;

  Future<AuthResult> login(LoginCredentials credentials) =>
      _dataSource.login(credentials);

  Future<AuthResult> signup(SignupCredentials credentials) =>
      _dataSource.signup(credentials);

  Future<AuthResult> logout() => _dataSource.logout();

  UserModel? getLocalUser() => _dataSource.getLocalUser();

  Future<UserModel?> getCurrentUser() => _dataSource.getCurrentUser();

  Future<bool> isAuthenticated() => _dataSource.isAuthenticated();

  void refreshSessionInBackground() => _dataSource.refreshSessionInBackground();

  Stream<supabase.AuthState> get authStateChanges => _dataSource.authStateChanges;

  void refreshUserProfileInBackground(String userId) =>
      _dataSource.refreshUserProfileInBackground(userId);

  Future<AuthResult> resetPassword(String email) =>
      _dataSource.resetPassword(email);

  bool validateEmail(String email) => _dataSource.validateEmail(email);

  String? validatePassword(String password) =>
      _dataSource.validatePassword(password);

  bool validateRangerId(String rangerId) => _dataSource.validateRangerId(rangerId);
}
