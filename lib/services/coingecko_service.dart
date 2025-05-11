import 'dart:convert';
import 'package:http/http.dart' as http;

class CoinGeckoService {
  final String _baseUrl = "https://api.coingecko.com/api/v3";

  Future<Map<String, dynamic>?> getPrices(
      List<String> ids, List<String> vsCurrencies) async {
    if (ids.isEmpty || vsCurrencies.isEmpty) {
      return null;
    }
    final String idsString = ids.join(',');
    final String vsCurrenciesString = vsCurrencies.join(',');
    final Uri uri = Uri.parse(
        '$_baseUrl/simple/price?ids=$idsString&vs_currencies=$vsCurrenciesString');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<double?> getPrice(String id, String vsCurrency) async {
    final Map<String, dynamic>? prices = await getPrices([id], [vsCurrency]);
    if (prices != null &&
        prices.containsKey(id) &&
        prices[id] is Map &&
        prices[id].containsKey(vsCurrency)) {
      return (prices[id][vsCurrency] as num).toDouble();
    }
    return null;
  }

  // Example: Fetches BTC/USD and ETH/USD
  Future<Map<String, double?>> getMultiplePrices(
      List<String> cryptoIds, String vsCurrency) async {
    final String idsParam = cryptoIds.join(',');
    final Uri url = Uri.parse(
        '$_baseUrl/simple/price?ids=$idsParam&vs_currencies=$vsCurrency');
    Map<String, double?> prices = {};
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        for (String id in cryptoIds) {
          if (data[id] != null && data[id][vsCurrency] != null) {
            prices[id] = (data[id][vsCurrency] as num).toDouble();
          } else {
            prices[id] = null;
          }
        }
      } else {
        print('CoinGecko API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching multiple CoinGecko prices: $e');
    }
    return prices;
  }
}
