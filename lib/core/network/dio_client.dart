import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../errors/app_exception.dart';

/// Dio HTTP client with JWT interceptor and error handling.
/// Automatically attaches the Firebase ID token to every request.
class DioClient {
  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000',
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 8),
        // Do NOT set Content-Type globally — Dio sets it correctly per request
        // (application/json for body, multipart/form-data for FormData uploads)
        headers: {},
      ),
    );
    _authInterceptor = _AuthInterceptor(_dio);
    _dio.interceptors.add(_authInterceptor);
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: false,
        responseBody: false,
        error: true,
        logPrint: (o) => debugPrint('[DIO] $o'),
      ));
    }
  }

  late final Dio _dio;
  late final _AuthInterceptor _authInterceptor;

  Dio get instance => _dio;

  /// Call on sign-out to clear the cached token so the next user
  /// always gets a fresh Firebase ID token.
  void clearTokenCache() => _authInterceptor.clearCache();
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._dio);

  final Dio _dio;
  bool _isRefreshing = false;
  String? _cachedToken;
  DateTime? _tokenExpiry;

  void clearCache() {
    _cachedToken = null;
    _tokenExpiry = null;
  }

  Future<String?> _getToken({bool forceRefresh = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    // Use cached token if still valid (with 60s buffer)
    if (!forceRefresh &&
        _cachedToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!.subtract(const Duration(seconds: 60)))) {
      return _cachedToken;
    }

    final token = await user.getIdToken(forceRefresh);
    _cachedToken = token;
    // Firebase tokens expire in 1 hour
    _tokenExpiry = DateTime.now().add(const Duration(hours: 1));
    return token;
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final token = await _getToken(forceRefresh: true);
        if (token != null) {
          err.requestOptions.headers['Authorization'] = 'Bearer $token';
          final response = await _dio.fetch(err.requestOptions);
          handler.resolve(response);
          return;
        }
      } catch (_) {
        // Token refresh failed — sign out handled by auth state listener
      } finally {
        _isRefreshing = false;
      }
    }

    final message = _extractMessage(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: NetworkException(message),
        response: err.response,
        type: err.type,
      ),
    );
  }

  String _extractMessage(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      return 'Request timed out. Check your connection and try again.';
    }
    if (err.type == DioExceptionType.connectionError) {
      final url = err.requestOptions.baseUrl;
      return 'Cannot reach server ($url). Make sure the backend is running and the device is on the same network.';
    }
    if (err.response != null) {
      final status = err.response!.statusCode;
      final data = err.response!.data;
      if (data is Map && data['detail'] != null) return data['detail'].toString();
      return 'Server error ($status).';
    }
    return 'Something went wrong. Try again.';
  }
}
