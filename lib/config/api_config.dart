import 'package:flutter/foundation.dart';

/// Настройки подключения к бэкенду (literature-reader-backend, FastAPI).
///
/// Адрес можно поменять без правки кода — при запуске:
///   flutter run --dart-define=API_BASE_URL=https://abc123.ngrok-free.app
///
/// Без --dart-define используется локальный сервер на порту 8000
/// (`docker compose up` в репозитории бэкенда).
class ApiConfig {
  ApiConfig._();

  static const _fromEnvironment = String.fromEnvironment('API_BASE_URL');

  /// Базовый адрес сервера без завершающего «/».
  static String get baseUrl {
    if (_fromEnvironment.isNotEmpty) {
      return _fromEnvironment.endsWith('/')
          ? _fromEnvironment.substring(0, _fromEnvironment.length - 1)
          : _fromEnvironment;
    }
    // Эмулятор Android видит localhost компьютера по адресу 10.0.2.2
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8000'
        : 'http://127.0.0.1:8000';
  }

  static const explainPath = '/api/v1/explain';

  /// Сколько ждать ответа сервера (задача #13: ReceiveTimeout = 10 с).
  static const receiveTimeout = Duration(seconds: 10);
  static const connectTimeout = Duration(seconds: 10);
  static const sendTimeout = Duration(seconds: 10);

  /// Ограничения на текст, который уходит на анализ.
  static const maxSelectionLength = 200;
  static const maxContextLength = 1000;
}
