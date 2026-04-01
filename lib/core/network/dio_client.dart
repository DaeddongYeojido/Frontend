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
  )..interceptors.add(
    LogInterceptor(requestBody: true, responseBody: true, error: true),
  );

  static Dio get instance => _dio;
}
