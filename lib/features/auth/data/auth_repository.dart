import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:agniraksha_mobile/core/network/api_client.dart';
import 'package:agniraksha_mobile/core/network/api_endpoints.dart';
import 'package:agniraksha_mobile/core/storage/secure_storage.dart';
import 'package:agniraksha_mobile/features/auth/domain/user_model.dart';

class AuthRepository {
  final ApiClient _client;
  final SecureStorage _storage;

  AuthRepository(this._client, this._storage);

  /// Login with email + password. Returns the authenticated user.
  Future<UserModel> login(String email, String password) async {
    final response = await _client.dio.post(
      ApiEndpoints.login,
      data: FormData.fromMap({
        'username': email,
        'password': password,
      }),
      options: Options(
        contentType: 'application/x-www-form-urlencoded',
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    if (response.statusCode == 401) {
      throw Exception('Invalid email or password');
    }

    if (response.statusCode != 200) {
      final detail = response.data?['detail'] ?? 'Login failed';
      throw Exception(detail);
    }

    // Extract JWT from Set-Cookie header
    final cookies = response.headers['set-cookie'];
    String? jwt;
    if (cookies != null) {
      for (final cookie in cookies) {
        if (cookie.startsWith('access_token=Bearer%20') || cookie.startsWith('access_token=Bearer ')) {
          final tokenPart = cookie.split(';').first;
          final value = tokenPart.split('=').sublist(1).join('=');
          jwt = value.replaceFirst('Bearer%20', '').replaceFirst('Bearer ', '');
          break;
        }
      }
    }

    if (jwt == null) {
      throw Exception('No access token received from server');
    }

    // Extract CSRF token from response body
    final csrfToken = response.data['csrf_token'] as String?;
    final userData = response.data['user'] as Map<String, dynamic>;
    final user = UserModel.fromJson(userData);

    // Persist credentials
    await _storage.saveToken(jwt);
    if (csrfToken != null) await _storage.saveCsrf(csrfToken);
    await _storage.saveUser(jsonEncode(user.toJson()));

    return user;
  }

  /// Fetch current user profile from /me endpoint.
  Future<UserModel> fetchMe() async {
    final response = await _client.dio.get(ApiEndpoints.me);

    final csrf = response.headers.value('X-CSRF-Token');
    if (csrf != null) {
      await _storage.saveCsrf(csrf);
    }

    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Check if user has a stored token and it's still valid.
  Future<UserModel?> tryRestoreSession() async {
    final token = await _storage.getToken();
    if (token == null) return null;

    try {
      return await fetchMe();
    } catch (_) {
      await _storage.clearAll();
      return null;
    }
  }

  /// Logout — clear local storage.
  Future<void> logout() async {
    try {
      await _client.dio.post(ApiEndpoints.logout);
    } catch (_) {
      // Best-effort server logout
    }
    await _storage.clearAll();
  }
}
