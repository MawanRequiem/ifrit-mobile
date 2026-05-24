import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper around flutter_secure_storage for JWT + CSRF token management.
class SecureStorage {
  static const _tokenKey = 'jwt_token';
  static const _csrfKey  = 'csrf_token';
  static const _userKey  = 'user_json';

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);
  Future<String?> getToken() => _storage.read(key: _tokenKey);
  Future<void> deleteToken() => _storage.delete(key: _tokenKey);

  Future<void> saveCsrf(String csrf) => _storage.write(key: _csrfKey, value: csrf);
  Future<String?> getCsrf() => _storage.read(key: _csrfKey);
  Future<void> deleteCsrf() => _storage.delete(key: _csrfKey);

  Future<void> saveUser(String userJson) => _storage.write(key: _userKey, value: userJson);
  Future<String?> getUser() => _storage.read(key: _userKey);
  Future<void> deleteUser() => _storage.delete(key: _userKey);

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
