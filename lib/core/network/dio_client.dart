import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

class DioClient {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  )..interceptors.addAll([
    LogInterceptor(requestBody: true, responseBody: true, error: true),
    InterceptorsWrapper(
      onError: (DioException e, ErrorInterceptorHandler handler) {
        // 서버가 내려준 message 필드를 DioException.message로 덮어씌워
        // 각 Provider에서 e.message 로 바로 꺼내 쓸 수 있게 함
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          handler.next(
            DioException(
              requestOptions: e.requestOptions,
              response: e.response,
              type: e.type,
              error: e.error,
              message: data['message'] as String,
            ),
          );
          return;
        }
        handler.next(e);
      },
    ),
  ]);

  static Dio get instance => _dio;
}

/// 백엔드 에러 응답에서 메시지를 추출하는 헬퍼
String extractErrorMessage(Object? error, {String fallback = '오류가 발생했습니다.'}) {
  if (error is DioException) {
    // 인터셉터가 이미 덮어쓴 message
    if (error.message != null && error.message!.isNotEmpty) {
      return error.message!;
    }
    // 인터셉터를 거치지 않은 경우 대비
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'] as String;
    }
    // 네트워크/타임아웃 등
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return '서버 응답이 너무 늦습니다. 잠시 후 다시 시도해주세요.';
      case DioExceptionType.connectionError:
        return '네트워크 연결을 확인해주세요.';
      default:
        break;
    }
  }
  return fallback;
}
