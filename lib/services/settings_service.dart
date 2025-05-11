import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String myfxbookEmailKey = 'myfxbook_email';
  static const String myfxbookPasswordKey = 'myfxbook_password';
  static const String myfxbookSessionKey = 'myfxbook_session_key';
  static const String zpubKey = 'zpub_key';
  static const String addressDiscoveryLimitKey = 'address_discovery_limit';
  static const String targetRatioKey =
      'target_ratio'; // For the ratio on main screen
  static const String targetAccountNameKey = 'myfxbook_target_account_name';

  Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  Future<void> saveString(String key, String value) async {
    final prefs = await _getPrefs();
    await prefs.setString(key, value);
  }

  Future<String?> getString(String key, {String? defaultValue}) async {
    final prefs = await _getPrefs();
    return prefs.getString(key) ?? defaultValue;
  }

  Future<void> saveInt(String key, int value) async {
    final prefs = await _getPrefs();
    await prefs.setInt(key, value);
  }

  Future<int?> getInt(String key, {int? defaultValue}) async {
    final prefs = await _getPrefs();
    return prefs.getInt(key) ?? defaultValue;
  }

  // Specific getters/setters
  Future<String?> getMyfxbookEmail() =>
      getString(myfxbookEmailKey, defaultValue: '');
  Future<void> saveMyfxbookEmail(String email) =>
      saveString(myfxbookEmailKey, email);

  Future<String?> getMyfxbookPassword() =>
      getString(myfxbookPasswordKey, defaultValue: '');
  Future<void> saveMyfxbookPassword(String password) =>
      saveString(myfxbookPasswordKey, password);

  Future<String?> getMyfxbookSessionKey() => getString(myfxbookSessionKey);
  Future<void> saveMyfxbookSessionKey(String sessionKey) =>
      saveString(myfxbookSessionKey, sessionKey);
  Future<void> clearMyfxbookSessionKey() async {
    final prefs = await _getPrefs();
    await prefs.remove(myfxbookSessionKey);
  }

  Future<String?> getZpubKey() => getString(zpubKey, defaultValue: '');
  Future<void> saveZpubKey(String zpub) => saveString(zpubKey, zpub);

  Future<int> getAddressDiscoveryLimit({int defaultValue = 20}) async {
    // Ensure a non-null return, falling back to a hardcoded default if necessary.
    return await getInt(addressDiscoveryLimitKey, defaultValue: defaultValue) ??
        defaultValue;
  }

  Future<void> saveAddressDiscoveryLimit(int limit) =>
      saveInt(addressDiscoveryLimitKey, limit);

  Future<String> getTargetRatio({String defaultValue = "2.0"}) async {
    // Ensure a non-null return
    return await getString(targetRatioKey, defaultValue: defaultValue) ??
        defaultValue;
  }

  Future<void> saveTargetRatio(String ratio) =>
      saveString(targetRatioKey, ratio);

  // Getter and Setter for Target Account Name
  Future<String?> getTargetAccountName() => getString(targetAccountNameKey);
  Future<void> saveTargetAccountName(String name) =>
      saveString(targetAccountNameKey, name);
}
