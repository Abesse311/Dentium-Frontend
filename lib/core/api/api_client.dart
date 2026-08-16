import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

class ApiException implements Exception {
  final String messageFr;
  final int? statusCode;
  final dynamic data;

  ApiException({
    required this.messageFr,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => messageFr;
}

class ApiClient {
  static ApiClient? _instance;
  late final Dio dio;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (kDebugMode) {
            debugPrint('🚀 [API REQ] ${options.method} ${options.uri}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint('✅ [API RESP] ${response.statusCode} ${response.requestOptions.uri}');
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          if (kDebugMode) {
            debugPrint('❌ [API ERR] ${e.type}: ${e.message} for ${e.requestOptions.uri}');
          }
          return handler.next(e);
        },
      ),
    );
  }

  static ApiClient get instance {
    _instance ??= ApiClient._internal();
    return _instance!;
  }

  /// Converts a DioException into a user-friendly French message
  static ApiException handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return ApiException(
            messageFr: 'Délai d\'attente dépassé. Vérifiez que le serveur local est actif.',
            statusCode: 408,
          );
        case DioExceptionType.connectionError:
          return ApiException(
            messageFr: 'Impossible de joindre le serveur local (127.0.0.1:8000). Veuillez démarrer le backend.',
            statusCode: 503,
          );
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final responseData = error.response?.data;
          String detail = 'Une erreur est survenue lors de la communication avec le serveur.';
          if (responseData is Map && responseData.containsKey('detail')) {
            final d = responseData['detail'];
            if (d is String) {
              detail = d;
            } else if (d is List) {
              detail = d.map((item) => item['msg'] ?? item.toString()).join('\n');
            }
          }
          return ApiException(
            messageFr: detail,
            statusCode: statusCode,
            data: responseData,
          );
        case DioExceptionType.cancel:
          return ApiException(messageFr: 'La requête a été annulée.');
        default:
          return ApiException(
            messageFr: 'Erreur de connexion au serveur local (127.0.0.1:8000).',
          );
      }
    }
    if (error is ApiException) return error;
    return ApiException(messageFr: error.toString());
  }

  /// Quick health check to test backend reachability
  Future<bool> checkConnection() async {
    try {
      final response = await dio.get(
        AppConstants.endpointSettings,
        options: Options(
          sendTimeout: const Duration(seconds: 2),
          receiveTimeout: const Duration(seconds: 2),
        ),
      );
      return response.statusCode == 200;
    } catch (_) {
      try {
        final fallbackResponse = await dio.get(
          '/docs',
          options: Options(
            sendTimeout: const Duration(seconds: 2),
            receiveTimeout: const Duration(seconds: 2),
          ),
        );
        return fallbackResponse.statusCode == 200;
      } catch (_) {
        return false;
      }
    }
  }
}
