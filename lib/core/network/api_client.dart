import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';
import 'api_endpoints.dart';

/// Singleton Dio client with auth and CSRF interceptors.
class ApiClient {
  late final Dio dio;
  final SecureStorage _storage;

  ApiClient(this._storage) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(_AuthInterceptor(_storage));
    dio.interceptors.add(_CsrfInterceptor(_storage));
  }
}

/// Injects Bearer token from secure storage into every request.
class _AuthInterceptor extends Interceptor {
  final SecureStorage _storage;

  _AuthInterceptor(this._storage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401 || err.response?.statusCode == 403) {
      // Token expired — clear storage, let auth provider handle redirect
      _storage.clearAll();
    }
    handler.next(err);
  }
}

/// Injects X-CSRF-Token on mutating requests (POST, PUT, DELETE, PATCH).
class _CsrfInterceptor extends Interceptor {
  final SecureStorage _storage;
  static const _mutatingMethods = {'POST', 'PUT', 'DELETE', 'PATCH'};

  _CsrfInterceptor(this._storage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_mutatingMethods.contains(options.method.toUpperCase())) {
      final csrf = await _storage.getCsrf();
      if (csrf != null) {
        options.headers['X-CSRF-Token'] = csrf;
      }
    }
    handler.next(options);
  }
}
