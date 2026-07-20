import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/api/api_providers.dart';
import '../../data/models/app_user.dart';
import '../../data/repositories/auth_repository.dart';

/// Holds the authenticated user (or null when signed out) and persists the
/// bearer token across app launches.
///
/// The state is an [AsyncValue<AppUser?>]:
///   * loading  -> a request (bootstrap / login / signup) is in flight
///   * data null -> signed out
///   * data user -> signed in
///   * error     -> the last auth request failed
class AuthController extends AsyncNotifier<AppUser?> {
  static const _tokenKey = 'auth_token';

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  /// On startup, restore a saved token and re-fetch the user.
  @override
  Future<AppUser?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) return null;

    ref.read(apiClientProvider).token = token;
    try {
      return await _repo.me();
    } catch (_) {
      // Token expired / invalid — clear it and stay signed out.
      await prefs.remove(_tokenKey);
      ref.read(apiClientProvider).token = null;
      return null;
    }
  }

  bool get isSignedIn => state.asData?.value != null;

  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await _repo.login(email: email, password: password);
      await _persist(result);
      return result.user;
    });
  }

  Future<void> signup({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result =
          await _repo.signup(name: name, email: email, password: password, phone: phone);
      await _persist(result);
      return result.user;
    });
  }

  Future<void> updateProfile({String? name, String? phone}) async {
    final updated = await _repo.updateProfile(name: name, phone: phone);
    state = AsyncValue.data(updated);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    ref.read(apiClientProvider).token = null;
    state = const AsyncValue.data(null);
  }

  Future<void> _persist(AuthResult result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, result.token);
    ref.read(apiClientProvider).token = result.token;
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AppUser?>(AuthController.new);
