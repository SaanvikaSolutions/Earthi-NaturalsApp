import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_providers.dart';
import '../api/api_client.dart';
import '../models/app_user.dart';

/// Result of a successful login / signup: a bearer token plus the user.
class AuthResult {
  final String token;
  final AppUser user;
  const AuthResult({required this.token, required this.user});

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      token: json['token'] as String,
      user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

/// Talks to the `/api/auth` endpoints on the backend.
class AuthRepository {
  AuthRepository(this._api);
  final ApiClient _api;

  Future<AuthResult> signup({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final data = await _api.post('/auth/signup', {
      'name': name,
      'email': email,
      'password': password,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    });
    return AuthResult.fromJson(data as Map<String, dynamic>);
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final data = await _api.post('/auth/login', {
      'email': email,
      'password': password,
    });
    return AuthResult.fromJson(data as Map<String, dynamic>);
  }

  /// Restores the current user from a previously-saved token.
  Future<AppUser> me() async {
    final data = await _api.get('/auth/me');
    return AppUser.fromJson(data as Map<String, dynamic>);
  }

  Future<AppUser> updateProfile({String? name, String? phone}) async {
    final data = await _api.patch('/auth/me', {
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
    });
    return AppUser.fromJson(data as Map<String, dynamic>);
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);
