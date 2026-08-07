import 'dart:convert';

/// Modelo de Usuário retornado por /api/auth/login e /api/auth/me.
class User {
  final int id;
  final String name;
  final String email;
  final String? role;
  final String? avatar;
  final String? city;
  final String? state;
  final String? bio;
  final String? createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.role,
    this.avatar,
    this.city,
    this.state,
    this.bio,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String?,
      avatar: json['avatar'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      bio: json['bio'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'avatar': avatar,
        'city': city,
        'state': state,
        'bio': bio,
        'created_at': createdAt,
      };

  /// Primeiro nome para a saudação (spec §4: "saudação").
  String get firstName => name.trim().split(' ').first;

  @override
  String toString() => 'User($id, $name, $email)';
}

/// Resposta de login: token + usuário.
class AuthSession {
  final String token;
  final int expiresIn;
  final User user;

  AuthSession({
    required this.token,
    required this.expiresIn,
    required this.user,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: json['token'] as String? ?? '',
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 3600,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  /// Serializa para guardar em SharedPreferences.
  String encode() => jsonEncode({
        'token': token,
        'expires_in': expiresIn,
        'user': user.toJson(),
      });

  static AuthSession? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return AuthSession(
        token: map['token'] as String,
        expiresIn: (map['expires_in'] as num).toInt(),
        user: User.fromJson(map['user'] as Map<String, dynamic>),
      );
    } catch (_) {
      return null;
    }
  }
}
