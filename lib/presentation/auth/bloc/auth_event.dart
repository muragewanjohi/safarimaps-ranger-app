part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class AuthSignupRequested extends AuthEvent {
  const AuthSignupRequested({
    required this.email,
    required this.password,
    required this.name,
    this.rangerId,
    this.team,
  });

  final String email;
  final String password;
  final String name;
  final String? rangerId;
  final String? team;

  @override
  List<Object?> get props => [email, password, name, rangerId, team];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthResetPasswordRequested extends AuthEvent {
  const AuthResetPasswordRequested({required this.email});

  final String email;

  @override
  List<Object?> get props => [email];
}

class AuthErrorCleared extends AuthEvent {
  const AuthErrorCleared();
}

class AuthSessionUpdated extends AuthEvent {
  const AuthSessionUpdated(this.user);

  final UserModel user;

  @override
  List<Object?> get props => [user];
}

class AuthSessionCleared extends AuthEvent {
  const AuthSessionCleared();
}
