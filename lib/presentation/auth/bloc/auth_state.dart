part of 'auth_bloc.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
    this.message,
    this.sessionResolved = false,
  });

  const AuthState.initial() : this();

  final AuthStatus status;
  final UserModel? user;
  final String? error;
  final String? message;
  final bool sessionResolved;

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get isLoading => status == AuthStatus.loading;
  bool get isBootstrapping => !sessionResolved;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? error,
    String? message,
    bool? sessionResolved,
    bool clearUser = false,
    bool clearError = false,
    bool clearMessage = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      error: clearError ? null : (error ?? this.error),
      message: clearMessage ? null : (message ?? this.message),
      sessionResolved: sessionResolved ?? this.sessionResolved,
    );
  }

  @override
  List<Object?> get props => [status, user, error, message, sessionResolved];
}
