import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:blockchain_utils/blockchain_utils.dart' as bu;
import 'package:bitcoin_base/bitcoin_base.dart';
import 'dart:developer' as developer;
import 'settings_service.dart';

class BlockchainService {
  final String _baseUrl = "https://blockchain.info";
  final SettingsService _settingsService = SettingsService();

  Future<double?> getBitcoinBalance() async {
    List<String> addressesToQuery = [];

    String? zpubKey = await _settingsService.getZpubKey();
    int addressDiscoveryLimit = await _settingsService.getAddressDiscoveryLimit(
        defaultValue: 20); // Load with default

    if (zpubKey != null && zpubKey.isNotEmpty) {
      developer.log(
          "Attempting to derive addresses from ZPUB: $zpubKey (NOTE: Derivation logic needs to be fixed and un-commented)",
          name: "BlockchainService");
      try {
        List<String> derivedAddresses =
            await _deriveAddressesFromZpub(zpubKey, addressDiscoveryLimit);
        addressesToQuery.addAll(derivedAddresses);

        if (addressesToQuery.isEmpty) {
          developer.log(
              "No addresses derived from ZPUB (or derivation logic is not functional). Returning 0 BTC.",
              name: "BlockchainService");
          return 0.0;
        }
        developer.log(
            "Derived ${addressesToQuery.length} addresses (check if functional). First 5: ${addressesToQuery.take(5).toList()}",
            name: "BlockchainService");
      } catch (e, s) {
        developer.log("Error during ZPUB address derivation or setup: $e",
            name: "BlockchainService", error: e, stackTrace: s);
        return null;
      }
    } else {
      developer.log("ZPUB Key not configured. Cannot fetch Bitcoin balance.",
          name: "BlockchainService");
      return null;
    }

    if (addressesToQuery.isEmpty) {
      developer.log(
          "Address list is empty after derivation attempt. This shouldn't happen if ZPUB is valid and derivation works.",
          name: "BlockchainService");
      return 0.0;
    }

    double totalBalanceSatoshis = 0;
    int batchSize = 150; // Consider making this configurable if necessary
    for (int i = 0; i < addressesToQuery.length; i += batchSize) {
      List<String> batch = addressesToQuery.sublist(
          i,
          i + batchSize > addressesToQuery.length
              ? addressesToQuery.length
              : i + batchSize);
      if (batch.isEmpty) continue;
      final String activeAddresses = batch.join('|');
      final Uri url = Uri.parse('$_baseUrl/balance?active=$activeAddresses');
      developer.log(
          "Querying batch ${i ~/ batchSize + 1} for ZPUB-derived addresses: $url",
          name: "BlockchainService");
      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          data.forEach((address, addressData) {
            if (addressData is Map &&
                addressData.containsKey('final_balance')) {
              totalBalanceSatoshis += (addressData['final_balance'] as num);
            }
          });
        } else {
          developer.log(
              'Blockchain.info API Error for ZPUB batch: ${response.statusCode} - ${response.body}',
              name: "BlockchainService");
        }
      } catch (e) {
        developer.log('Error fetching ZPUB Bitcoin balance for batch: $e',
            name: "BlockchainService");
      }
    }
    developer.log(
        "Total satoshis from all ZPUB-derived address batches: $totalBalanceSatoshis",
        name: "BlockchainService");
    return totalBalanceSatoshis / 100000000;
  }

  Future<List<String>> _deriveAddressesFromZpub(String zpub, int count) async {
    List<String> derivedAddresses = [];
    developer.log(
        "Attempting to derive addresses from ZPUB: $zpub with count: $count",
        name: "BlockchainService");
    try {
      final bip84Account =
          bu.Bip84.fromExtendedKey(zpub, bu.Bip84Coins.bitcoin);

      final bu.Bip84 externalChainNode =
          bip84Account.change(bu.Bip44Changes.chainExt);

      for (int i = 0; i < count; i++) {
        final bu.Bip84 derivedKeyInfoExternal =
            externalChainNode.addressIndex(i);
        final bu.Bip44PublicKey ecPublicKeyBuExternal =
            derivedKeyInfoExternal.publicKey;
        final List<int> compressedPubKeyBytesExternal =
            ecPublicKeyBuExternal.compressed;
        final ECPublic ecPublicKeyBbExternal =
            ECPublic.fromBytes(compressedPubKeyBytesExternal);
        final P2wpkhAddress p2wpkhAddrExternal =
            ecPublicKeyBbExternal.toSegwitAddress();
        derivedAddresses
            .add(p2wpkhAddrExternal.toAddress(BitcoinNetwork.mainnet));
        developer.log(
            "Derived External Address [$i]: ${p2wpkhAddrExternal.toAddress(BitcoinNetwork.mainnet)}",
            name: "BlockchainService");
      }

      final bu.Bip84 internalChainNode =
          bip84Account.change(bu.Bip44Changes.chainInt);

      for (int i = 0; i < count; i++) {
        final bu.Bip84 derivedKeyInfoInternal =
            internalChainNode.addressIndex(i);
        final bu.Bip44PublicKey ecPublicKeyBuInternal =
            derivedKeyInfoInternal.publicKey;
        final List<int> compressedPubKeyBytesInternal =
            ecPublicKeyBuInternal.compressed;
        final ECPublic ecPublicKeyBbInternal =
            ECPublic.fromBytes(compressedPubKeyBytesInternal);
        final P2wpkhAddress p2wpkhAddrInternal =
            ecPublicKeyBbInternal.toSegwitAddress();
        derivedAddresses
            .add(p2wpkhAddrInternal.toAddress(BitcoinNetwork.mainnet));
        developer.log(
            "Derived Internal Address [$i]: ${p2wpkhAddrInternal.toAddress(BitcoinNetwork.mainnet)}",
            name: "BlockchainService");
      }

      developer.log(
          "Successfully derived ${derivedAddresses.length} addresses.",
          name: "BlockchainService");
    } catch (e, s) {
      developer.log("Error in _deriveAddressesFromZpub: $e",
          name: "BlockchainService", error: e, stackTrace: s);
      return [];
    }
    return derivedAddresses;
  }
}
