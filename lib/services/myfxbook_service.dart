import 'dart:convert';
import 'package:http/http.dart' as http;
import 'settings_service.dart';

class MyfxbookService {
  final String _baseUrl = "https://www.myfxbook.com/api";
  String? _sessionKey;
  final SettingsService _settingsService = SettingsService();

  Future<bool> login() async {
    String? email = await _settingsService.getMyfxbookEmail();
    String? password = await _settingsService.getMyfxbookPassword();

    if (_sessionKey != null && _sessionKey!.isNotEmpty) {
      print(
          "Existing Myfxbook session key found: $_sessionKey. Will try to use this first.");
      return true;
    }

    if (email == null ||
        email.isEmpty ||
        password == null ||
        password.isEmpty) {
      print("Myfxbook credentials not configured in settings.");
      return false;
    }

    final Uri url =
        Uri.parse('$_baseUrl/login.json?email=$email&password=$password');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['error'] == false && data['session'] != null) {
          _sessionKey = data['session'];
          print('Myfxbook login successful. Session: $_sessionKey');
          await _settingsService.saveMyfxbookSessionKey(_sessionKey!);
          return true;
        } else {
          print('Myfxbook login failed: ${data['message']}');
          _sessionKey = null;
          await _settingsService.clearMyfxbookSessionKey();
        }
      } else {
        print(
            'Myfxbook API Error (login): ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error during Myfxbook login: $e');
    }
    return false;
  }

  Future<double?> getAccountBalance() async {
    _sessionKey = await _settingsService.getMyfxbookSessionKey();

    if (_sessionKey == null) {
      print(
          'Not logged into Myfxbook or session expired. Attempting to log in.');
      bool loggedIn = await login();
      if (!loggedIn || _sessionKey == null) {
        return null;
      }
      // After a successful login, re-fetch the session key that was saved by login()
      _sessionKey = await _settingsService.getMyfxbookSessionKey();
      if (_sessionKey == null) {
        // Still null after login attempt, something went wrong
        print("Failed to establish a session even after login attempt.");
        return null;
      }
    }

    final Uri url =
        Uri.parse('$_baseUrl/get-my-accounts.json?session=$_sessionKey');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['error'] == false && data['accounts'] != null) {
          List<dynamic> accounts = data['accounts'];
          if (accounts.isEmpty) {
            print("No accounts found on Myfxbook.");
            return null;
          }

          Map<String, dynamic>? targetAccount;
          // Fetch target account name from settings
          final String? accNameToFindFromSettings =
              await _settingsService.getTargetAccountName();

          if (accNameToFindFromSettings != null &&
              accNameToFindFromSettings.isNotEmpty) {
            targetAccount = accounts.firstWhere(
              (acc) => acc['name'] == accNameToFindFromSettings,
              orElse: () => null,
            );
            if (targetAccount == null) {
              print(
                  "Target account '$accNameToFindFromSettings' (from settings) not found. Found accounts: ${accounts.map((a) => a['name']).toList()}");
              // Fallback to first account if specific one from settings not found
              if (accounts.isNotEmpty) {
                print(
                    "Falling back to the first available account: ${accounts.first['name']}");
                targetAccount = accounts.first;
              }
            }
          } else if (accounts.isNotEmpty) {
            // If no target name specified in settings, use the first account
            targetAccount = accounts.first;
            print(
                "No specific account name in settings, using first account: ${targetAccount?['name']}");
          }

          if (targetAccount != null && targetAccount['balance'] != null) {
            return (targetAccount['balance'] as num).toDouble();
          }
        } else {
          print('Myfxbook get accounts error: ${data['message']}');
          if (data['message'] == 'Invalid session.') {
            // Handle session expiry
            _sessionKey = null; // Clear session key to force re-login next time
            await _settingsService.clearMyfxbookSessionKey();
          }
        }
      } else {
        print(
            'Myfxbook API Error (get-my-accounts): ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching Myfxbook account balance: $e');
    }
    return null;
  }

  // Call this to clear session if needed, e.g., on app exit or manual logout
  void logout() {
    _sessionKey = null;
    _settingsService.clearMyfxbookSessionKey();
    print("Myfxbook session cleared.");
    // Myfxbook does not seem to have an explicit logout API endpoint
    // Clearing the session key locally is usually sufficient.
  }
}
