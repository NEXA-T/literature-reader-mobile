import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../models/analysis_result.dart';

/// Клиент бэкенда: POST /api/v1/explain.
///
/// Договорённость со шторкой (lib/widgets/analysis_sheet.dart):
/// при успехе возвращаем [AnalysisResult], при любой ошибке бросаем
/// [AnalysisException] — шторка сама покажет экран ошибки и «Повторить».
class AiApiClient {
  AiApiClient({Dio? dio, Connectivity? connectivity})
    : _dio = dio ?? _createDio(),
      _connectivity = connectivity ?? Connectivity();

  final Dio _dio;
  final Connectivity _connectivity;

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        sendTimeout: ApiConfig.sendTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
        headers: {
          // Иначе бесплатный ngrok может отдать HTML-страницу предупреждения
          'ngrok-skip-browser-warning': 'true',
        },
      ),
    );
    if (kDebugMode) {
      // Лог запроса и ответа (200 OK) в консоли flutter run
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: false,
          responseHeader: false,
          logPrint: (o) => debugPrint('[AI API] $o'),
        ),
      );
    }
    return dio;
  }

  /// Та же сигнатура, что у MockAnalysisService.analyze — подставляется
  /// в `fetch` шторки без других изменений.
  Future<AnalysisResult> analyze({
    required String selectedText,
    required String context,
    required String bookTitle,
  }) async {
    // Нет сети — сразу ошибка, без HTTP-запроса и без ожидания
    if (!await _hasNetwork()) {
      debugPrint('[AI API] нет подключения к сети, запрос не отправлен');
      throw const AnalysisException(AnalysisFailureKind.offline);
    }

    final Response<dynamic> response;
    try {
      response = await _dio.post<dynamic>(
        ApiConfig.explainPath,
        data: {
          'selected_text': selectedText,
          'context': context,
          'book_title': bookTitle,
        },
      );
    } on DioException catch (e) {
      debugPrint('[AI API] ошибка запроса: ${e.type} ${e.message ?? ''}');
      throw AnalysisException(_failureKind(e));
    }

    debugPrint(
      '[AI API] ${response.statusCode} ${response.statusMessage ?? ''}',
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      debugPrint('[AI API] неожиданный формат ответа: $data');
      throw const AnalysisException(AnalysisFailureKind.server);
    }

    final result = AnalysisResult.fromJson(data);
    if (result.translation.isEmpty || result.contextMeaning.isEmpty) {
      debugPrint('[AI API] в ответе нет обязательных полей: $data');
      throw const AnalysisException(AnalysisFailureKind.server);
    }
    return result;
  }

  Future<bool> _hasNetwork() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      // Не смогли узнать статус сети — пробуем отправить запрос
      return true;
    }
  }

  static AnalysisFailureKind _failureKind(DioException e) {
    // Не удалось достучаться до сервера (нет интернета, DNS) — «нет сети».
    // Таймаут 10 с, ответ не 200 и всё остальное — «сбой сервера».
    return e.type == DioExceptionType.connectionError
        ? AnalysisFailureKind.offline
        : AnalysisFailureKind.server;
  }
}
