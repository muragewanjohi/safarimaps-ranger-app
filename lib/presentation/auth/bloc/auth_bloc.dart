import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._authRepository) : super(const AuthState.initial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthSignupRequested>(_onSignupRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthResetPasswordRequested>(_onResetPasswordRequested);
    on<AuthErrorCleared>(_onErrorCleared);
    on<AuthSessionUpdated>(_onSessionUpdated);
    on<AuthSessionCleared>(_onSessionCleared);

    _authSubscription = _authRepository.authStateChanges.listen(
      _handleAuthStateChange,
    );

    add(const AuthCheckRequested());
  }

  final AuthRepository _authRepository;
  StreamSubscription<supabase.AuthState>? _authSubscription;

  void _handleAuthStateChange(supabase.AuthState authState) {
    final event = authState.event;
    final session = authState.session;

    switch (event) {
      case supabase.AuthChangeEvent.initialSession:
        if (session?.user != null) {
          add(AuthSessionUpdated(UserModel.fromAuthUser(session!.user!)));
        } else if (!state.sessionResolved) {
          add(const AuthSessionCleared());
        }
      case supabase.AuthChangeEvent.signedIn:
      case supabase.AuthChangeEvent.tokenRefreshed:
      case supabase.AuthChangeEvent.userUpdated:
        if (session?.user != null) {
          add(AuthSessionUpdated(UserModel.fromAuthUser(session!.user!)));
        }
      case supabase.AuthChangeEvent.signedOut:
        add(const AuthSessionCleared());
      default:
        break;
    }
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (!state.sessionResolved) {
      emit(state.copyWith(status: AuthStatus.loading));
    }

    final user = _authRepository.getLocalUser();

    if (user != null) {
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        sessionResolved: true,
        clearError: true,
      ));
      _authRepository.refreshUserProfileInBackground(user.id);
      _authRepository.refreshSessionInBackground();
      return;
    }

    emit(state.copyWith(
      status: AuthStatus.unauthenticated,
      sessionResolved: true,
      clearUser: true,
    ));
  }

  void _onSessionUpdated(
    AuthSessionUpdated event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(
      status: AuthStatus.authenticated,
      user: event.user,
      sessionResolved: true,
      clearError: true,
    ));
    _authRepository.refreshUserProfileInBackground(event.user.id);
    _authRepository.refreshSessionInBackground();
  }

  void _onSessionCleared(
    AuthSessionCleared event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(
      status: AuthStatus.unauthenticated,
      sessionResolved: true,
      clearUser: true,
    ));
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    final result = await _authRepository.login(
      LoginCredentials(email: event.email, password: event.password),
    );
    if (result.success && result.user != null) {
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
        message: result.message,
        sessionResolved: true,
      ));
    } else {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        error: result.error ?? 'Login failed',
        sessionResolved: true,
        clearUser: true,
      ));
    }
  }

  Future<void> _onSignupRequested(
    AuthSignupRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    final result = await _authRepository.signup(
      SignupCredentials(
        email: event.email,
        password: event.password,
        name: event.name,
        rangerId: event.rangerId,
        team: event.team,
      ),
    );
    if (result.success && result.user != null) {
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
        message: result.message,
        sessionResolved: true,
      ));
    } else {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        error: result.error ?? 'Signup failed',
        sessionResolved: true,
        clearUser: true,
      ));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    await _authRepository.logout();
    emit(state.copyWith(
      status: AuthStatus.unauthenticated,
      sessionResolved: true,
      clearUser: true,
      clearError: true,
      clearMessage: true,
    ));
  }

  Future<void> _onResetPasswordRequested(
    AuthResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    final result = await _authRepository.resetPassword(event.email);
    if (result.success) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        message: result.message,
        sessionResolved: true,
        clearUser: true,
      ));
    } else {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        error: result.error,
        sessionResolved: true,
        clearUser: true,
      ));
    }
  }

  void _onErrorCleared(AuthErrorCleared event, Emitter<AuthState> emit) {
    emit(state.copyWith(clearError: true, clearMessage: true));
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
