import 'package:dio/dio.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../models/api_settings.dart';

class ApiService {
  late final Dio _dio;
  final ApiSettings settings;

  ApiService(this.settings) {
    _dio = Dio(BaseOptions(
      baseUrl: settings.endpoint,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': settings.apiKey,
      },
    ));

    // Add interceptor for logging
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }

  Future<void> sendSmsData({
    required String from,
    required String message,
    required int? date,
    required String description,
    required String amount,
    required String recipeId,
  }) async {
    try {
      final response = await _dio.post(
        '',
        data: {
          'from': from,
          'message': message,
          'date': date,
          'description': description,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'خطا در ارسال اطلاعات به سرور',
        );
      }
    } on DioException catch (e) {
      EasyLoading.showError("خطا در ارسال به API: ${e.message}");
      if (e.response != null) {
        EasyLoading.showError("کد خطا: ${e.response?.statusCode}");
        EasyLoading.showError("پاسخ سرور: ${e.response?.data}");
      }
      rethrow;
    }
  }
} 