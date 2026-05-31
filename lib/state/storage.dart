import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around SharedPreferences so the rest of the app never touches
/// the plugin directly (easy to swap for Hive/secure storage later).
class Storage {
  Storage(this._prefs);

  final SharedPreferences _prefs;

  static Future<Storage> open() async {
    return Storage(await SharedPreferences.getInstance());
  }

  int getInt(String key, int fallback) => _prefs.getInt(key) ?? fallback;
  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);

  bool getBool(String key, bool fallback) => _prefs.getBool(key) ?? fallback;
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  String? getString(String key) => _prefs.getString(key);
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);
}
