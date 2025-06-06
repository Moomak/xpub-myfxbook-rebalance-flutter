import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'settings_service.dart'; // To get API keys
import 'dart:developer' as developer;

class BinanceService {
  final String _baseUrl = 'https://api.binance.com';
  final SettingsService _settingsService = SettingsService();

  Future<Map<String, String>> _getApiKeys() async {
    final apiKey = await _settingsService.getBinanceApiKey();
    final apiSecret = await _settingsService.getBinanceApiSecret();
    return {'apiKey': apiKey ?? '', 'apiSecret': apiSecret ?? ''};
  }

  Future<Map<String, dynamic>?> _sendSignedRequest(
      String endpoint, String params) async {
    final keys = await _getApiKeys();
    final apiKey = keys['apiKey'];
    final apiSecret = keys['apiSecret'];

    if (apiKey == null ||
        apiKey.isEmpty ||
        apiSecret == null ||
        apiSecret.isEmpty) {
      developer.log('Binance API Key/Secret not set.', name: 'BinanceService');
      return null;
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final queryString = 'timestamp=$timestamp&$params';

    final key = utf8.encode(apiSecret);
    final bytes = utf8.encode(queryString);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    final signature = digest.toString();

    final url =
        Uri.parse('$_baseUrl$endpoint?$queryString&signature=$signature');

    try {
      final response = await http.get(
        url,
        headers: {'X-MBX-APIKEY': apiKey},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        developer.log(
            'Binance API Error: ${response.statusCode} ${response.body}',
            name: 'BinanceService');
        return null;
      }
    } catch (e) {
      developer.log('Error making signed request to Binance: $e',
          name: 'BinanceService');
      return null;
    }
  }

  Future<Map<String, double>> getAccountBalances() async {
    final spotBalances = await _getSpotBalances();
    final earnBalances = await _getEarnBalances();

    final totalBalances = <String, double>{};

    spotBalances.forEach((key, value) {
      totalBalances[key] = (totalBalances[key] ?? 0) + value;
    });

    earnBalances.forEach((key, value) {
      totalBalances[key] = (totalBalances[key] ?? 0) + value;
    });

    return totalBalances;
  }

  Future<Map<String, double>> _getSpotBalances() async {
    final endpoint = '/api/v3/account';
    final response = await _sendSignedRequest(endpoint, '');

    if (response == null || response['balances'] == null) {
      return {};
    }

    final balances = <String, double>{};
    for (var item in response['balances']) {
      final asset = item['asset'];
      if (asset == 'BTC' || asset == 'USDT') {
        final free = double.tryParse(item['free'].toString()) ?? 0.0;
        final locked = double.tryParse(item['locked'].toString()) ?? 0.0;
        balances[asset] = (balances[asset] ?? 0) + free + locked;
      }
    }
    return balances;
  }

  Future<Map<String, double>> _getEarnBalances() async {
    final endpoint = '/sapi/v1/simple-earn/flexible/position';
    // Binance requires pageSize and it can be up to 100
    final response = await _sendSignedRequest(endpoint, 'pageSize=100');

    if (response == null || response['rows'] == null) {
      return {};
    }

    final balances = <String, double>{};
    for (var item in response['rows']) {
      final asset = item['asset'];
      if (asset == 'BTC' || asset == 'USDT') {
        final amount = double.tryParse(item['totalAmount'].toString()) ?? 0.0;
        balances[asset] = (balances[asset] ?? 0) + amount;
      }
    }
    return balances;
  }
}
