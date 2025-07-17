// lib/services/config_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  static const String _apiUrlKey = 'api_url';
  static String defaultApiUrl = 'http://localhost:5000';

  static Future<String> getApiUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiUrlKey) ?? defaultApiUrl;
  }

  static Future<void> setApiUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiUrlKey, url);
  }
}
