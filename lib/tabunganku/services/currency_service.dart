import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final currencyServiceProvider = Provider((ref) => CurrencyService());

final currencyRatesProvider =
    AsyncNotifierProvider<CurrencyRatesNotifier, Map<String, double>>(() {
      return CurrencyRatesNotifier();
    });

class CurrencyRatesNotifier extends AsyncNotifier<Map<String, double>> {
  @override
  FutureOr<Map<String, double>> build() {
    return ref.read(currencyServiceProvider).fetchLatestRates();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final rates = await ref.read(currencyServiceProvider).fetchLatestRates();
    state = AsyncData(rates);
  }
}

class CurrencyService {
  final String _baseUrl = 'https://api.frankfurter.app/latest';

  Future<Map<String, double>> fetchLatestRates() async {
    try {

      final response = await http
          .get(Uri.parse('$_baseUrl?from=IDR'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rates = Map<String, dynamic>.from(data['rates']);



        final Map<String, double> idrRates = {};
        idrRates['IDR'] = 1.0;

        rates.forEach((code, rate) {
          idrRates[code] = 1.0 / (double.tryParse(rate.toString()) ?? 1.0);
        });

        return idrRates;
      }
    } catch (e) {
      print('Currency API error: $e');
    }


    return {
      'IDR': 1.0,
      'USD': 16250.0,
      'EUR': 17400.0,
      'SGD': 11950.0,
      'JPY': 105.0,
      'SAR': 4330.0,
      'MYR': 3400.0,
      'AUD': 10600.0,
      'GBP': 20200.0,
      'CNY': 2250.0,
      'HKD': 2080.0,
      'KRW': 11.8,
      'THB': 440.0,
      'VND': 0.64,
      'PHP': 282.0,
      'CAD': 11900.0,
      'CHF': 17800.0,
      'TWD': 500.0,
      'NZD': 9600.0,
      'BRL': 3100.0,
    };
  }
}
