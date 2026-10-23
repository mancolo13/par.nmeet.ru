import 'dart:convert';
import 'package:flagsmith/flagsmith.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'geo_service.dart';

class FlagService {
  static const String _apiKey = 'nq37ww3jR4tLmpncSKVxN3';
  static const String _cachedConfigKey = 'flagsmith_cached_appconfig';

  FlagsmithClient? _flagsmithClient;
  bool showWebView = false;
  Map<String, String> webViewConfig = {};
  String? rawConfig;

  /// Главный метод, вызываемый из SplashScreen для получения целевого URL
  static Future<String?> checkWebviewUrl() async {
    final service = FlagService();
    return await service.getResolvedUrl();
  }

  /// Получение URL в зависимости от ГЕО по IP пользователя
  Future<String?> getResolvedUrl() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Параллельно запрашиваем ISO-код страны по IP и флаги из Flagsmith
    final results = await Future.wait([
      GeoService.getCountryCode(),
      init(),
    ]);

    final countryCode = results[0] as String?;

    // 2. Если удалось загрузить конфиг с сервера - кэшируем, иначе пробуем кэш
    if (rawConfig != null && rawConfig!.isNotEmpty) {
      await prefs.setString(_cachedConfigKey, rawConfig!);
    } else {
      final cachedJson = prefs.getString(_cachedConfigKey);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        applyFromJson(cachedJson);
      }
    }

    if (kDebugMode) {
      print('[FlagService] User country from IP: $countryCode');
      print('[FlagService] showWebView: $showWebView, available GEOs: ${webViewConfig.keys.toList()}');
    }

    // 3. Проверяем, включен ли показ и есть ли совпадение по ГЕО пользователя
    if (showWebView && countryCode != null && countryCode.isNotEmpty) {
      final targetUrl = webViewConfig[countryCode.toUpperCase()];
      if (targetUrl != null && targetUrl.startsWith('http')) {
        if (kDebugMode) {
          print('[FlagService] GEO Match found for $countryCode -> $targetUrl');
        }
        return targetUrl;
      }
    }

    if (kDebugMode) {
      print('[FlagService] No match for $countryCode. Opening stub screen.');
    }

    return null;
  }

  Future<void> init() async {
    // 1. Попытка через официальный Flagsmith SDK
    try {
      _flagsmithClient = await FlagsmithClient.init(
        apiKey: _apiKey,
        config: const FlagsmithConfig(caches: false),
      );

      await _flagsmithClient!.getFeatureFlags(reload: true);

      final isEnabled = await _flagsmithClient!.isFeatureFlagEnabled('appconfig');
      if (isEnabled == false) {
        showWebView = false;
      }

      final appConfigString = await _flagsmithClient!.getFeatureFlagValue(
        'appconfig',
      );

      rawConfig = appConfigString;

      if (appConfigString != null && appConfigString.isNotEmpty) {
        applyFromJson(appConfigString);
        if (webViewConfig.isNotEmpty) return;
      } else {
        _reset();
      }
    } catch (e) {
      if (kDebugMode) {
        print('[FlagService] SDK init error: $e');
      }
      _reset();
    } finally {
      close();
    }

    // 2. Резервный HTTP Fallback на случай блокировок или сбоев SDK
    for (final endpoint in [
      'https://edge.api.flagsmith.com/api/v1/flags/',
      'https://api.flagsmith.com/api/v1/flags/',
    ]) {
      try {
        final response = await http.get(
          Uri.parse(endpoint),
          headers: {
            'X-Environment-Key': _apiKey,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is List && data.isNotEmpty) {
            for (final item in data) {
              if (item is Map<String, dynamic>) {
                if (item['enabled'] == false) {
                  showWebView = false;
                }
                final stateVal = item['feature_state_value']?.toString() ?? '';
                if (stateVal.isNotEmpty && stateVal.trim().startsWith('{')) {
                  rawConfig = stateVal;
                  applyFromJson(stateVal);
                  if (webViewConfig.isNotEmpty) return;
                }
              }
            }
          }
        }
      } catch (_) {}
    }
  }

  /// Применить конфиг из JSON строки
  void applyFromJson(String json) {
    try {
      final configJson = jsonDecode(json) as Map<String, dynamic>;

      if (configJson.containsKey('showWebView')) {
        showWebView = configJson['showWebView'] as bool? ?? false;
      } else {
        showWebView = true; // Если передан плоский JSON {"DE": "...", "RU": "..."}, по умолчанию включаем
      }

      if (configJson.containsKey('webViewConfig') && configJson['webViewConfig'] is Map) {
        final wvc = configJson['webViewConfig'] as Map<String, dynamic>;
        webViewConfig = wvc.map(
          (key, value) => MapEntry(key.toUpperCase().trim(), value.toString().trim()),
        );
      } else {
        webViewConfig = {};
        configJson.forEach((key, value) {
          if (key != 'showWebView' && value != null) {
            final url = value.toString().trim();
            if (url.startsWith('http')) {
              webViewConfig[key.toUpperCase().trim()] = url;
            }
          }
        });
      }
    } catch (_) {
      _reset();
    }
  }

  void _reset() {
    showWebView = false;
    webViewConfig = {};
  }

  void close() {
    _flagsmithClient?.close();
    _flagsmithClient = null;
  }
}

// Алиас для удобства
typedef FlagsmithService = FlagService;
