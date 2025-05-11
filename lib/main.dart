import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Added for number formatting
import 'services/coingecko_service.dart';
import 'services/blockchain_service.dart';
import 'services/myfxbook_service.dart';
import 'services/settings_service.dart'; // Added SettingsService import
import 'screens/settings_screen.dart'; // Added SettingsScreen import
import 'dart:developer' as developer; // For console logging

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Portfolio Rebalancer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const PortfolioDashboardScreen(),
    );
  }
}

class PortfolioDashboardScreen extends StatefulWidget {
  const PortfolioDashboardScreen({super.key});

  @override
  State<PortfolioDashboardScreen> createState() =>
      _PortfolioDashboardScreenState();
}

class _PortfolioDashboardScreenState extends State<PortfolioDashboardScreen> {
  // Services
  final CoinGeckoService _coinGeckoService = CoinGeckoService();
  final BlockchainService _blockchainService = BlockchainService();
  final MyfxbookService _myfxbookService = MyfxbookService();
  final SettingsService _settingsService =
      SettingsService(); // Added SettingsService instance

  // State variables for display (Strings)
  bool _isLoading = true; // Start true for initial setup and data loading check
  bool _areEssentialSettingsConfigured = false;
  String btcBalance = "N/A";
  String myfxbookBalance = "N/A";
  String btcTargetCurrencyRate = "N/A"; // Updated name for clarity
  String usdtTargetCurrencyRate = "N/A"; // Updated name for clarity
  String totalPortfolioValueUsdt = "N/A";
  String currentAllocationBtc = "N/A";
  String currentAllocationMyfxbook = "N/A";
  String totalPortfolioValueThb = "N/A"; // Added for THB total
  String usdtToThbRate = "N/A"; // Added for USDT/THB rate
  String rebalancingSuggestion = "Load data to see suggestions.";

  // Numeric state variables for calculations
  double? _numericBtcBalance;
  double? _numericMyfxbookBalance;
  double? _numericBtcTargetCurrencyRate;
  // double? _numericUsdtTargetCurrencyRate; // For consistency if used later

  late TextEditingController
      _targetRatioController; // Made non-final and late initialized
  final String _targetDisplayCurrency = "USD"; // For display purposes on UI

  // Helper function to format numbers with commas and specified fraction digits
  String _formatNumber(dynamic value, int fractionDigits,
      {bool useCommas = true}) {
    if (value == null) return "Error"; // Or "N/A" depending on context upstream
    if (value is String) {
      // If it's already a string like "Error" or "N/A", return it directly
      // Attempt to parse if it might be a numeric string without formatting
      final double? parsedValue = double.tryParse(value);
      if (parsedValue == null) return value; // Not a parsable numeric string
      value = parsedValue; // Continue with the parsed double
    }

    if (value is num) {
      if (!useCommas) {
        return value.toStringAsFixed(fractionDigits);
      }
      // Create a NumberFormat instance for a specific locale if needed, e.g., 'en_US'
      // For just commas and decimal places, a pattern is often sufficient.
      String pattern = '#,##0';
      if (fractionDigits > 0) {
        pattern += '.';
        for (int i = 0; i < fractionDigits; i++) {
          pattern += '0';
        }
      }
      final formatter = NumberFormat(pattern, 'en_US');
      return formatter.format(value);
    }
    return value
        .toString(); // Fallback for other types, though not expected for numbers
  }

  @override
  void initState() {
    super.initState();
    _targetRatioController =
        TextEditingController(); // Initialize controller here
    _performInitialSetup(); // Perform initial setup and checks
  }

  Future<void> _performInitialSetup() async {
    if (mounted) setState(() => _isLoading = true);

    // Always load target ratio for the text field
    _targetRatioController.text =
        await _settingsService.getTargetRatio(defaultValue: "2.0");

    final email = await _settingsService.getMyfxbookEmail();
    final password = await _settingsService.getMyfxbookPassword();
    final zpub = await _settingsService.getZpubKey();

    final bool configured = email != null &&
        email.isNotEmpty &&
        password != null &&
        password.isNotEmpty &&
        zpub != null &&
        zpub.isNotEmpty;

    if (mounted) {
      setState(() {
        _areEssentialSettingsConfigured = configured;
      });
    }

    if (configured) {
      await _loadPortfolioData(); // This will manage _isLoading for its duration
    } else {
      if (mounted) {
        setState(() {
          // Reset UI fields to "N/A" or placeholder messages
          btcBalance = "N/A";
          myfxbookBalance = "N/A";
          btcTargetCurrencyRate = "N/A";
          usdtTargetCurrencyRate = "N/A";
          totalPortfolioValueUsdt = "N/A";
          currentAllocationBtc = "N/A";
          currentAllocationMyfxbook = "N/A";
          totalPortfolioValueThb = "N/A";
          usdtToThbRate = "N/A";
          rebalancingSuggestion =
              "Please configure critical settings (Myfxbook credentials, ZPUB Key) to view portfolio and suggestions.";
          _isLoading = false; // Finished initial setup, settings not configured
          // Reset numeric values as well
          _numericBtcBalance = null;
          _numericMyfxbookBalance = null;
          _numericBtcTargetCurrencyRate = null;
        });
      }
    }
  }

  Future<void> _loadPortfolioData() async {
    if (!_areEssentialSettingsConfigured) {
      if (mounted) {
        setState(() {
          rebalancingSuggestion =
              "Cannot load data. Please configure settings.";
          _isLoading = false;
        });
      }
      return;
    }

    // if (_isLoading && mounted) return; // Original guard might be too aggressive if _isLoading is true from _performInitialSetup
    // The _isLoading will be set to true specifically for this data loading part.

    if (mounted) {
      setState(() {
        _isLoading = true;
        rebalancingSuggestion = "Loading data...";
      });
    }

    try {
      // 1. Fetch Myfxbook Balance
      final myfxBalanceNum = await _myfxbookService.getAccountBalance();
      _numericMyfxbookBalance = myfxBalanceNum; // Store numeric value
      if (mounted) {
        setState(() {
          myfxbookBalance = _formatNumber(myfxBalanceNum, 2);
        });
      }
      if (myfxBalanceNum == null)
        developer.log("Failed to fetch Myfxbook balance.",
            name: "PortfolioDashboard");

      // 2. Fetch Bitcoin Balance (now always attempts ZPUB derivation)
      final btcBalNum = await _blockchainService.getBitcoinBalance();
      _numericBtcBalance = btcBalNum; // Store numeric value
      if (mounted) {
        setState(() {
          btcBalance = _formatNumber(btcBalNum, 8);
        });
      }
      if (btcBalNum == null)
        developer.log("Failed to fetch BTC balance (check ZPUB derivation).",
            name: "PortfolioDashboard");

      // 3. Fetch Exchange Rates (BTC/USD and USDT/USD - assuming TARGET_CURRENCY from config is 'usd')
      // CoinGecko IDs: bitcoin, tether
      // Original PHP used TARGET_CURRENCY for intermediate, then converted to USDT for total.
      // Here, we aim for BTC/TARGET_CURRENCY and USDT/TARGET_CURRENCY for display,
      // and will use them to calculate total in USDT.
      // TARGET_CURRENCY from config.php was 'usd'. So we fetch BTC/USD and USDT/USD.

      final String actualTargetCurrency = "usd"; // From your config.php
      final String displayCurrencyThb = "thb";

      final btcRateNum =
          await _coinGeckoService.getPrice('bitcoin', actualTargetCurrency);
      _numericBtcTargetCurrencyRate = btcRateNum; // Store numeric value
      final usdtRateNum = await _coinGeckoService.getPrice(
          'tether', actualTargetCurrency); // tether is USDT
      final usdtThbRateDataNum =
          await _coinGeckoService.getPrice('tether', displayCurrencyThb);

      if (mounted) {
        setState(() {
          btcTargetCurrencyRate = _formatNumber(btcRateNum, 2);
          usdtTargetCurrencyRate = _formatNumber(usdtRateNum, 2);
          usdtToThbRate = _formatNumber(usdtThbRateDataNum, 2);
        });
      }
      if (btcRateNum == null)
        developer.log("Failed to fetch BTC/$actualTargetCurrency rate.",
            name: "PortfolioDashboard");
      if (usdtRateNum == null)
        developer.log("Failed to fetch USDT/$actualTargetCurrency rate.",
            name: "PortfolioDashboard");
      if (usdtThbRateDataNum == null)
        developer.log("Failed to fetch USDT/$displayCurrencyThb rate.",
            name: "PortfolioDashboard");

      // 4. Calculate Total Portfolio Value in USDT
      // and Current Allocation
      // Also calculate Total Portfolio Value in THB
      if (_numericBtcBalance != null &&
          _numericMyfxbookBalance != null &&
          _numericBtcTargetCurrencyRate !=
              null /* and usdtRate != null if needed for conversion */) {
        // Assuming Myfxbook balance is already in USD (as per typical Myfxbook display)
        // If Myfxbook is in another currency, it would need conversion using its own rate.
        // For now, let's assume Myfxbook balance is in USD.

        double btcValueInUsd =
            _numericBtcBalance! * _numericBtcTargetCurrencyRate!;
        double myfxbookValueInUsd =
            _numericMyfxbookBalance!; // Assuming Myfxbook balance is already in USD

        // Total portfolio value in USD. Since USDT is pegged to USD, this is also approx total value in USDT.
        double totalValueUsd = btcValueInUsd + myfxbookValueInUsd;

        // Calculate Total Portfolio Value in THB
        String calculatedTotalPortfolioValueThb = "Error";
        if (usdtThbRateDataNum != null && totalValueUsd > 0) {
          calculatedTotalPortfolioValueThb =
              _formatNumber((totalValueUsd * usdtThbRateDataNum), 2);
        }

        if (mounted) {
          setState(() {
            totalPortfolioValueUsdt = _formatNumber(totalValueUsd, 2);
            totalPortfolioValueThb = calculatedTotalPortfolioValueThb;

            if (totalValueUsd > 0) {
              currentAllocationBtc = _formatNumber(
                  ((btcValueInUsd / totalValueUsd) * 100), 1,
                  useCommas: false);
              currentAllocationMyfxbook = _formatNumber(
                  ((myfxbookValueInUsd / totalValueUsd) * 100), 1,
                  useCommas: false);
            } else {
              currentAllocationBtc = "0";
              currentAllocationMyfxbook = "0";
            }
          });
        }
        _updateRebalancingSuggestion(btcValueInUsd, myfxbookValueInUsd);
      } else {
        if (mounted) {
          setState(() {
            totalPortfolioValueUsdt = "Error";
            currentAllocationBtc = "Error";
            currentAllocationMyfxbook = "Error";
            totalPortfolioValueThb = "Error"; // Reset THB total on error
            rebalancingSuggestion = "Could not calculate due to missing data.";
            // Reset numeric values as well on data error
            _numericBtcBalance = null;
            _numericMyfxbookBalance = null;
            _numericBtcTargetCurrencyRate = null;
          });
        }
      }
    } catch (e) {
      developer.log('Error in _loadPortfolioData: $e',
          name: "PortfolioDashboard");
      if (mounted) {
        setState(() {
          btcBalance = "Error";
          myfxbookBalance = "Error";
          btcTargetCurrencyRate = "Error";
          usdtTargetCurrencyRate = "Error";
          totalPortfolioValueUsdt = "Error";
          currentAllocationBtc = "Error";
          currentAllocationMyfxbook = "Error";
          totalPortfolioValueThb = "Error"; // Reset THB total on error
          usdtToThbRate = "Error"; // Reset USDT/THB rate on error
          rebalancingSuggestion = "An error occurred while loading data.";
          // Reset numeric values on exception
          _numericBtcBalance = null;
          _numericMyfxbookBalance = null;
          _numericBtcTargetCurrencyRate = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _updateAndRebalance() {
    _loadPortfolioData().then((_) {
      if (_numericBtcBalance != null &&
          _numericMyfxbookBalance != null &&
          _numericBtcTargetCurrencyRate != null) {
        double btcValueInUsd =
            _numericBtcBalance! * _numericBtcTargetCurrencyRate!;
        double myfxbookValueInUsd = _numericMyfxbookBalance!;
        _updateRebalancingSuggestion(btcValueInUsd, myfxbookValueInUsd);
      } else {
        if (mounted) {
          setState(() {
            bool dataSeemsInvalidOrNotLoaded =
                (btcBalance == "N/A" || btcBalance == "Error") ||
                    (myfxbookBalance == "N/A" || myfxbookBalance == "Error") ||
                    (btcTargetCurrencyRate == "N/A" ||
                        btcTargetCurrencyRate == "Error");

            if (dataSeemsInvalidOrNotLoaded &&
                (rebalancingSuggestion.contains("Loading") ||
                    rebalancingSuggestion.contains("configure") ||
                    rebalancingSuggestion.contains("due to missing data"))) {
              rebalancingSuggestion =
                  "Cannot calculate: data is invalid or failed to load for rebalance.";
            }
            // Otherwise, trust the message from _loadPortfolioData or _updateRebalancingSuggestion
          });
        }
      }
    });
  }

  void _updateRebalancingSuggestion(
      double currentBtcValueUsd, double currentMyfxbookValueUsd) {
    final targetRatioText = _targetRatioController.text;
    final targetRatio = double.tryParse(targetRatioText);

    if (targetRatio == null || targetRatio <= 0) {
      if (mounted) {
        setState(() {
          rebalancingSuggestion =
              "Invalid target ratio. Please enter a positive number.";
        });
      }
      return;
    }

    // Total current value = BTC value in USD + Myfxbook value in USD
    double totalValue = currentBtcValueUsd + currentMyfxbookValueUsd;

    if (totalValue <= 0) {
      if (mounted) {
        setState(() {
          rebalancingSuggestion =
              "Cannot rebalance with zero or negative total portfolio value.";
        });
      }
      return;
    }

    // Desired BTC value = total value * (target BTC ratio part / sum of ratio parts)
    // If ratio is X:1 (BTC:MyFxBook), sum of ratio parts is X+1
    // Desired BTC value = Total Value * (X / (X+1))
    // Desired MyFxBook value = Total Value * (1 / (X+1))
    double desiredBtcValue = totalValue * (targetRatio / (targetRatio + 1.0));
    double desiredMyfxbookValue = totalValue * (1.0 / (targetRatio + 1.0));

    double diffBtc = desiredBtcValue - currentBtcValueUsd;
    double diffMyfxbook = desiredMyfxbookValue - currentMyfxbookValueUsd;

    // Format targetRatio display
    String displayRatio = targetRatioText;
    final double? parsedRatio = double.tryParse(targetRatioText);
    if (parsedRatio != null && parsedRatio == parsedRatio.toInt()) {
      displayRatio = parsedRatio.toInt().toString();
    }

    String suggestionText = "Target Ratio: ${displayRatio}:1 (BTC:Myfxbook)\n";
    suggestionText +=
        "Current: BTC \$${_formatNumber(currentBtcValueUsd, 2)}, Myfxbook \$${_formatNumber(currentMyfxbookValueUsd, 2)}\n";
    suggestionText +=
        "Desired: BTC \$${_formatNumber(desiredBtcValue, 2)}, Myfxbook \$${_formatNumber(desiredMyfxbookValue, 2)}\n\n";

    if (diffBtc.abs() < 0.01 && diffMyfxbook.abs() < 0.01) {
      suggestionText +=
          "Portfolio is already balanced according to the target ratio.";
    } else {
      if (diffBtc > 0) {
        suggestionText +=
            "Action: Increase BTC value by \$${_formatNumber(diffBtc, 2)}. ";
      } else if (diffBtc < 0) {
        suggestionText +=
            "Action: Decrease BTC value by \$${_formatNumber(-diffBtc, 2)}. ";
      }
      // Note: The Myfxbook difference will typically be the inverse of the BTC difference
      // if (diffMyfxbook > 0) {
      //     suggestionText += "Increase Myfxbook value by \$${diffMyfxbook.toStringAsFixed(2)}.\n";
      // } else if (diffMyfxbook < 0) {
      //     suggestionText += "Decrease Myfxbook value by \$${(-diffMyfxbook).toStringAsFixed(2)}.\n";
      // }
    }

    if (mounted) {
      setState(() {
        rebalancingSuggestion = suggestionText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ).then((_) {
                _performInitialSetup(); // Re-run setup after returning from settings
              });
            },
            tooltip: "Settings",
          ),
        ],
      ),
      body: _buildBody(context), // Extracted body to a new method
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading && !_areEssentialSettingsConfigured) {
      // Show loading indicator only if initial setup is in progress
      // If _areEssentialSettingsConfigured is true, _loadPortfolioData handles its own loading state for RefreshIndicator
      return const Center(child: CircularProgressIndicator());
    }

    if (!_areEssentialSettingsConfigured) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Please configure critical settings (Myfxbook credentials, ZPUB Key) to view your portfolio.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsScreen()),
                  ).then((_) {
                    _performInitialSetup(); // Re-run setup after returning from settings
                  });
                },
                child: const Text('Go to Settings'),
              ),
            ],
          ),
        ),
      );
    }

    // Settings are configured, show portfolio with RefreshIndicator
    return RefreshIndicator(
      onRefresh: _loadPortfolioData,
      child: SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(), // Ensure scroll even if content is small
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (_isLoading &&
                currentAllocationBtc ==
                    "N/A") // Show specific loading only if initial data isn't there yet during a refresh cycle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Center(
                    child: Text(
                        rebalancingSuggestion)), // Or a more subtle loading indicator
              ),
            _buildInfoCard(
              context,
              title: 'Portfolio Overview',
              children: [
                _buildInfoRow(context, 'BTC Balance:', btcBalance),
                _buildInfoRow(
                    context,
                    'Myfxbook Balance ($_targetDisplayCurrency):',
                    myfxbookBalance),
                _buildInfoRow(context, 'Total Portfolio Value (USDT):',
                    totalPortfolioValueUsdt),
                _buildInfoRow(context, 'Total Portfolio Value (THB):',
                    totalPortfolioValueThb), // Added THB total display
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              context,
              title: 'Current Allocation',
              children: [
                _buildInfoRow(context, 'BTC:', '$currentAllocationBtc%'),
                _buildInfoRow(
                    context, 'Myfxbook:', '$currentAllocationMyfxbook%'),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              context,
              title: 'Exchange Rates',
              children: [
                _buildInfoRow(context, 'BTC/$_targetDisplayCurrency:',
                    btcTargetCurrencyRate),
                _buildInfoRow(context, 'USDT/$_targetDisplayCurrency:',
                    usdtTargetCurrencyRate),
                _buildInfoRow(context, 'USDT/THB:',
                    usdtToThbRate), // Added USDT/THB rate display
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Rebalancing',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _targetRatioController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Target BTC:Myfxbook Ratio (e.g., 1.0 for 1:1)',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _updateAndRebalance(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _updateAndRebalance,
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Update Ratio & Rebalance'),
            ),
            const SizedBox(height: 16),
            Text(
              'Suggestion:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                rebalancingSuggestion,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context,
      {required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: textTheme.bodyMedium),
          Text(value,
              style:
                  textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _targetRatioController.dispose();
    super.dispose();
  }
}
