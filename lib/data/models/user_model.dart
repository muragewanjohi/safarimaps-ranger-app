import 'package:supabase_flutter/supabase_flutter.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.rangerId,
    this.team,
    this.park = 'Masai Mara National Reserve',
    this.avatar,
    this.joinDate,
    this.isActive = true,
  });

  final String id;
  final String email;
  final String name;
  final String role;
  final String? rangerId;
  final String? team;
  final String park;
  final String? avatar;
  final String? joinDate;
  final bool isActive;

  factory UserModel.fromProfile(Map<String, dynamic> json, {String? email}) {
    return UserModel(
      id: json['id'] as String,
      email: (json['email'] as String?) ?? email ?? '',
      name: json['name'] as String? ?? 'Ranger',
      role: json['role'] as String? ?? 'Ranger',
      rangerId: json['ranger_id'] as String?,
      team: json['team'] as String?,
      park: json['park'] as String? ?? 'Masai Mara National Reserve',
      avatar: json['avatar'] as String?,
      joinDate: json['join_date'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  factory UserModel.fromAuthUser(User user) {
    final metadata = user.userMetadata ?? {};
    final name = metadata['name'] as String? ?? 'Ranger';
    final avatar = metadata['avatar'] as String? ??
        name
            .split(' ')
            .where((part) => part.isNotEmpty)
            .map((part) => part[0])
            .take(2)
            .join()
            .toUpperCase();

    return UserModel(
      id: user.id,
      email: user.email ?? '',
      name: name,
      role: metadata['role'] as String? ?? 'Ranger',
      rangerId: metadata['ranger_id'] as String?,
      team: metadata['team'] as String?,
      park: metadata['park'] as String? ?? 'Masai Mara National Reserve',
      avatar: avatar,
      joinDate: metadata['join_date'] as String?,
      isActive: metadata['is_active'] as bool? ?? true,
    );
  }
}

class LoginCredentials {
  const LoginCredentials({required this.email, required this.password});

  final String email;
  final String password;
}

class SignupCredentials {
  const SignupCredentials({
    required this.email,
    required this.password,
    required this.name,
    this.rangerId,
    this.team,
    this.role = 'Ranger',
  });

  final String email;
  final String password;
  final String name;
  final String? rangerId;
  final String? team;
  final String role;
}

class AuthResult {
  const AuthResult({
    required this.success,
    this.user,
    this.error,
    this.message,
  });

  final bool success;
  final UserModel? user;
  final String? error;
  final String? message;
}
