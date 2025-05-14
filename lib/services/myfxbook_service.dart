import 'dart:convert';
import 'package:http/http.dart' as http;
import 'settings_service.dart';
import 'dart:developer' as developer;

class MyfxbookService {
  final String _baseUrl = "https://www.myfxbook.com/api";
  String? _sessionKey;
  final SettingsService _settingsService = SettingsService();

  Future<bool> login() async {
    String? email = await _settingsService.getMyfxbookEmail();
    String? password = await _settingsService.getMyfxbookPassword();

    if (_sessionKey != null && _sessionKey!.isNotEmpty) {
      developer.log(
          "Existing Myfxbook session key found: $_sessionKey. Will try to use this first.",
          name: "MyfxbookService");
      return true;
    }

    if (email == null ||
        email.isEmpty ||
        password == null ||
        password.isEmpty) {
      developer.log("Myfxbook credentials not configured in settings.",
          name: "MyfxbookService");
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
          developer.log('Myfxbook login successful. Session: $_sessionKey',
              name: "MyfxbookService");
          await _settingsService.saveMyfxbookSessionKey(_sessionKey!);
          return true;
        } else {
          developer.log('Myfxbook login failed: ${data['message']}',
              name: "MyfxbookService");
          _sessionKey = null;
          await _settingsService.clearMyfxbookSessionKey();
        }
      } else {
        developer.log(
            'Myfxbook API Error (login): ${response.statusCode} - ${response.body}',
            name: "MyfxbookService");
      }
    } catch (e) {
      developer.log('Error during Myfxbook login: $e', name: "MyfxbookService");
    }
    return false;
  }

  Future<Map<String, dynamic>?> getAccountDetails() async {
    _sessionKey = await _settingsService.getMyfxbookSessionKey();

    if (_sessionKey == null) {
      developer.log(
          'Not logged into Myfxbook or session expired. Attempting to log in.',
          name: "MyfxbookService");
      bool loggedIn = await login();
      if (!loggedIn || _sessionKey == null) {
        return null;
      }
      _sessionKey = await _settingsService.getMyfxbookSessionKey();
      if (_sessionKey == null) {
        developer.log("Failed to establish a session even after login attempt.",
            name: "MyfxbookService");
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
            developer.log("No accounts found on Myfxbook.",
                name: "MyfxbookService");
            return null;
          }

          Map<String, dynamic>? targetAccountData;
          final String? accNameToFindFromSettings =
              await _settingsService.getTargetAccountName();

          Map<String, dynamic>? selectedAccountJson;

          if (accNameToFindFromSettings != null &&
              accNameToFindFromSettings.isNotEmpty) {
            selectedAccountJson = accounts.firstWhere(
              (acc) => acc['name'] == accNameToFindFromSettings,
              orElse: () => null,
            );
            if (selectedAccountJson == null) {
              developer.log(
                  "Target account '$accNameToFindFromSettings' (from settings) not found. Found accounts: ${accounts.map((a) => a['name']).toList()}",
                  name: "MyfxbookService");
              if (accounts.isNotEmpty) {
                developer.log(
                    "Falling back to the first available account: ${accounts.first['name']}",
                    name: "MyfxbookService");
                selectedAccountJson = accounts.first;
              }
            }
          } else if (accounts.isNotEmpty) {
            selectedAccountJson = accounts.first;
            developer.log(
                "No specific account name in settings, using first account: ${selectedAccountJson?['name']}",
                name: "MyfxbookService");
          }

          if (selectedAccountJson != null) {
            developer.log(
                "Selected Myfxbook Account Data: ${jsonEncode(selectedAccountJson)}",
                name: "MyfxbookService.AccountData");

            double? balance =
                (selectedAccountJson['balance'] as num?)?.toDouble();
            double? equity =
                (selectedAccountJson['equity'] as num?)?.toDouble();
            double? drawdown =
                (selectedAccountJson['drawdown'] as num?)?.toDouble() ??
                    (selectedAccountJson['dd'] as num?)?.toDouble();

            if (balance != null && equity != null) {
              return {
                'balance': balance,
                'equity': equity,
                'drawdown': drawdown,
              };
            } else {
              developer.log(
                  "Balance or Equity is null for selected account. Balance: $balance, Equity: $equity",
                  name: "MyfxbookService");
            }
          }
        } else {
          developer.log('Myfxbook get accounts error: ${data['message']}',
              name: "MyfxbookService");
          if (data['message'] == 'Invalid session.') {
            _sessionKey = null;
            await _settingsService.clearMyfxbookSessionKey();
          }
        }
      } else {
        developer.log(
            'Myfxbook API Error (get-my-accounts): ${response.statusCode} - ${response.body}',
            name: "MyfxbookService");
      }
    } catch (e, s) {
      developer.log('Error fetching Myfxbook account details: $e',
          stackTrace: s, name: "MyfxbookService");
    }
    return null;
  }

  void logout() {
    _sessionKey = null;
    _settingsService.clearMyfxbookSessionKey();
    developer.log("Myfxbook session cleared.", name: "MyfxbookService");
  }
}
