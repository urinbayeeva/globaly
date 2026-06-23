import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class DioClient {
  DioClient() : _dio = _build();

  final Dio _dio;
  Dio get instance => _dio;

  static Dio _build() {
    final Dio dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 15),
        headers: <String, String>{'Accept': 'application/json'},
      ),
    );
    dio.interceptors.add(
      PrettyDioLogger(
        responseBody: false,
      ),
    );
    return dio;
  }
}
