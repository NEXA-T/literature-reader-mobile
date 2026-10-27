import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../config/api_config.dart';
import '../models/analysis_result.dart';

/// Клиент бэкенда: POST /api/v1/explain и POST /api/v1/generate-image.
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

  /// Генерация иллюстрации: POST /api/v1/generate-image (задача #15).
  ///
  /// Вызывается отдельно от [analyze], уже после показа текста разбора,
  /// поэтому тяжёлая картинка не задерживает шторку.
  /// Возвращает [ImageProvider] — его можно сразу отдать в Image(image: ...).
  /// При ошибке бросает [AnalysisException], как и [analyze].
  ///
  /// Формат ответа бэкенд ещё не зафиксировал, поэтому понимаем три варианта:
  /// сама картинка (Content-Type: image/*), JSON со ссылкой
  /// (`image_url` / `url`) или JSON с base64 (`image_base64` / `image`).
  Future<ImageProvider> generateImage(String imagePrompt) async {
    if (!await _hasNetwork()) {
      throw const AnalysisException(AnalysisFailureKind.offline);
    }

    final Response<List<int>> response;
    try {
      response = await _dio.post<List<int>>(
        ApiConfig.generateImagePath,
        data: {'image_prompt': imagePrompt},
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: ApiConfig.imageReceiveTimeout,
        ),
      );
    } on DioException catch (e) {
      debugPrint(
        '[AI API] ошибка генерации картинки: ${e.type} ${e.message ?? ''}',
      );
      throw AnalysisException(_failureKind(e));
    }
    debugPrint(
      '[AI API] картинка: ${response.statusCode} ${response.statusMessage ?? ''}',
    );

    final bytes = Uint8List.fromList(response.data ?? const []);
    final contentType = response.headers.value(Headers.contentTypeHeader) ?? '';
    if (contentType.startsWith('image/')) return MemoryImage(bytes);

    try {
      final json = jsonDecode(utf8.decode(bytes));
      if (json is Map<String, dynamic>) {
        final url = (json['image_url'] ?? json['url']) as String?;
        if (url != null && url.isNotEmpty) {
          return NetworkImage(
            Uri.parse(ApiConfig.baseUrl).resolve(url).toString(),
          );
        }
        var b64 = (json['image_base64'] ?? json['image']) as String?;
        if (b64 != null && b64.isNotEmpty) {
          final comma = b64.indexOf(',');
          if (b64.startsWith('data:') && comma != -1) {
            b64 = b64.substring(comma + 1);
          }
          return MemoryImage(base64Decode(b64));
        }
      }
    } catch (e) {
      debugPrint('[AI API] не удалось разобрать ответ с картинкой: $e');
    }
    throw const AnalysisException(AnalysisFailureKind.server);
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
