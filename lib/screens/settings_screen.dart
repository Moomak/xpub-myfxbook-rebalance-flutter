import 'package:flutter/material.dart';
import 'package:rebalance_portfolio_flutter/services/settings_service.dart'; // Assuming this is the correct path

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final SettingsService _settingsService = SettingsService();

  // Controllers for text fields
  late TextEditingController _myfxbookEmailController;
  late TextEditingController _myfxbookPasswordController;
  late TextEditingController _zpubKeyController;
  late TextEditingController _addressDiscoveryLimitController;
  late TextEditingController _targetRatioController;
  late TextEditingController _targetAccountNameController;
  late TextEditingController _binanceApiKeyController;
  late TextEditingController _binanceApiSecretController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _myfxbookEmailController = TextEditingController();
    _myfxbookPasswordController = TextEditingController();
    _zpubKeyController = TextEditingController();
    _addressDiscoveryLimitController = TextEditingController();
    _targetRatioController = TextEditingController();
    _targetAccountNameController = TextEditingController();
    _binanceApiKeyController = TextEditingController();
    _binanceApiSecretController = TextEditingController();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    _myfxbookEmailController.text =
        await _settingsService.getMyfxbookEmail() ?? '';
    _myfxbookPasswordController.text =
        await _settingsService.getMyfxbookPassword() ?? '';
    _zpubKeyController.text = await _settingsService.getZpubKey() ?? '';
    _addressDiscoveryLimitController.text =
        (await _settingsService.getAddressDiscoveryLimit(defaultValue: 20))
            .toString();
    _targetRatioController.text =
        await _settingsService.getTargetRatio(defaultValue: "2.0");
    _targetAccountNameController.text =
        await _settingsService.getTargetAccountName() ?? '';
    _binanceApiKeyController.text =
        await _settingsService.getBinanceApiKey() ?? '';
    _binanceApiSecretController.text =
        await _settingsService.getBinanceApiSecret() ?? '';
    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      await _settingsService.saveMyfxbookEmail(_myfxbookEmailController.text);
      await _settingsService
          .saveMyfxbookPassword(_myfxbookPasswordController.text);
      await _settingsService.saveZpubKey(_zpubKeyController.text);
      await _settingsService.saveAddressDiscoveryLimit(
          int.tryParse(_addressDiscoveryLimitController.text) ?? 20);
      await _settingsService.saveTargetRatio(_targetRatioController.text);
      await _settingsService
          .saveTargetAccountName(_targetAccountNameController.text);
      await _settingsService.saveBinanceApiKey(_binanceApiKeyController.text);
      await _settingsService
          .saveBinanceApiSecret(_binanceApiSecretController.text);
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully!')),
        );
      }
    }
  }

  @override
  void dispose() {
    _myfxbookEmailController.dispose();
    _myfxbookPasswordController.dispose();
    _zpubKeyController.dispose();
    _addressDiscoveryLimitController.dispose();
    _targetRatioController.dispose();
    _targetAccountNameController.dispose();
    _binanceApiKeyController.dispose();
    _binanceApiSecretController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: <Widget>[
                  TextFormField(
                    controller: _myfxbookEmailController,
                    decoration:
                        const InputDecoration(labelText: 'Myfxbook Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter Myfxbook Email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _myfxbookPasswordController,
                    decoration:
                        const InputDecoration(labelText: 'Myfxbook Password'),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter Myfxbook Password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _zpubKeyController,
                    decoration: const InputDecoration(labelText: 'ZPUB Key'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter ZPUB Key';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressDiscoveryLimitController,
                    decoration: const InputDecoration(
                        labelText: 'Address Discovery Limit'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter Address Discovery Limit';
                      }
                      if (int.tryParse(value) == null ||
                          int.parse(value) <= 0) {
                        return 'Please enter a valid positive number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _targetAccountNameController,
                    decoration: const InputDecoration(
                      labelText: 'Target Myfxbook Account Name (Optional)',
                      hintText: 'Leave blank to use the first account found',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _binanceApiKeyController,
                    decoration:
                        const InputDecoration(labelText: 'Binance API Key'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _binanceApiSecretController,
                    decoration:
                        const InputDecoration(labelText: 'Binance API Secret'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _targetRatioController,
                    decoration: const InputDecoration(
                        labelText: 'Target BTC:Myfxbook Ratio (e.g., 2.0)'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter Target Ratio';
                      }
                      if (double.tryParse(value) == null ||
                          double.parse(value) <= 0) {
                        return 'Please enter a valid positive number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveSettings,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Save Settings'),
                  ),
                ],
              ),
            ),
    );
  }
}
