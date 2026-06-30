import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:otax/tabunganku/core/theme/app_colors.dart';
import 'package:otax/tabunganku/core/theme/theme_provider.dart';
import 'package:otax/tabunganku/services/currency_service.dart';

class CurrencyConverterPage extends ConsumerStatefulWidget {
  const CurrencyConverterPage({super.key});

  @override
  ConsumerState<CurrencyConverterPage> createState() =>
      _CurrencyConverterPageState();
}

class _CurrencyConverterPageState extends ConsumerState<CurrencyConverterPage> {
  String _amountStr = '1';
  bool _isNumpadVisible = true;
  bool _isLoading = true;
  DateTime? _lastUpdated;

  final List<Map<String, dynamic>> _currencies = [
    {
      'code': 'IDR',
      'name': 'Indonesian Rupiah',
      'flag': '🇮🇩',
      'rate': 1.0,
      'symbol': 'Rp',
    },
    {
      'code': 'USD',
      'name': 'US Dollar',
      'flag': '🇺🇸',
      'rate': 16250.0,
      'symbol': '\$',
    },
    {
      'code': 'EUR',
      'name': 'Euro',
      'flag': '🇪🇺',
      'rate': 17400.0,
      'symbol': '€',
    },
    {
      'code': 'SGD',
      'name': 'Singapore Dollar',
      'flag': '🇸🇬',
      'rate': 11950.0,
      'symbol': 'S\$',
    },
    {
      'code': 'JPY',
      'name': 'Japanese Yen',
      'flag': '🇯🇵',
      'rate': 105.0,
      'symbol': '¥',
    },
    {
      'code': 'SAR',
      'name': 'Saudi Riyal',
      'flag': '🇸🇦',
      'rate': 4330.0,
      'symbol': 'SR',
    },
    {
      'code': 'MYR',
      'name': 'Malaysian Ringgit',
      'flag': '🇲🇾',
      'rate': 3400.0,
      'symbol': 'RM',
    },
    {
      'code': 'AUD',
      'name': 'Australian Dollar',
      'flag': '🇦🇺',
      'rate': 10600.0,
      'symbol': 'A\$',
    },
    {
      'code': 'GBP',
      'name': 'British Pound',
      'flag': '🇬🇧',
      'rate': 20200.0,
      'symbol': '£',
    },
    {
      'code': 'CNY',
      'name': 'Chinese Yuan',
      'flag': '🇨🇳',
      'rate': 2250.0,
      'symbol': '¥',
    },
    {
      'code': 'HKD',
      'name': 'Hong Kong Dollar',
      'flag': '🇭🇰',
      'rate': 2080.0,
      'symbol': 'HK\$',
    },
    {
      'code': 'KRW',
      'name': 'South Korean Won',
      'flag': '🇰🇷',
      'rate': 11.8,
      'symbol': '₩',
    },
    {
      'code': 'THB',
      'name': 'Thai Baht',
      'flag': '🇹🇭',
      'rate': 440.0,
      'symbol': '฿',
    },
    {
      'code': 'VND',
      'name': 'Vietnamese Dong',
      'flag': '🇻🇳',
      'rate': 0.64,
      'symbol': '₫',
    },
    {
      'code': 'PHP',
      'name': 'Philippine Peso',
      'flag': '🇵🇭',
      'rate': 282.0,
      'symbol': '₱',
    },
    {
      'code': 'CAD',
      'name': 'Canadian Dollar',
      'flag': '🇨🇦',
      'rate': 11900.0,
      'symbol': 'C\$',
    },
    {
      'code': 'CHF',
      'name': 'Swiss Franc',
      'flag': '🇨🇭',
      'rate': 17800.0,
      'symbol': 'CHF',
    },
    {
      'code': 'TWD',
      'name': 'Taiwan Dollar',
      'flag': '🇹🇼',
      'rate': 500.0,
      'symbol': 'NT\$',
    },
    {
      'code': 'NZD',
      'name': 'New Zealand Dollar',
      'flag': '🇳🇿',
      'rate': 9600.0,
      'symbol': 'NZ\$',
    },
    {
      'code': 'BRL',
      'name': 'Brazilian Real',
      'flag': '🇧🇷',
      'rate': 3100.0,
      'symbol': 'R\$',
    },
  ];

  late Map<String, dynamic> _fromCurrency;
  late Map<String, dynamic> _toCurrency;

  @override
  void initState() {
    super.initState();
    _fromCurrency = _currencies[1]; // USD
    _toCurrency = _currencies[0]; // IDR


    final initialRates = ref.read(currencyRatesProvider).value;
    if (initialRates != null) {
      _updateRatesFromMap(initialRates);
      _isLoading = false;
    } else {
      _isLoading = true;

      _fetchRates();
    }
  }

  void _updateRatesFromMap(Map<String, double> rates) {
    for (var curr in _currencies) {
      if (rates.containsKey(curr['code'])) {
        curr['rate'] = rates[curr['code']];
      }
    }
    _lastUpdated = DateTime.now();
  }

  Future<void> _fetchRates() async {
    setState(() => _isLoading = true);
    await ref.read(currencyRatesProvider.notifier).refresh();
  }

  void _onNumberPress(String val) {
    setState(() {
      if (_amountStr == '0' && val != '.') {
        _amountStr = val;
      } else {
        _amountStr += val;
      }
    });
  }

  void _onBackspace() {
    setState(() {
      if (_amountStr.length > 1) {
        _amountStr = _amountStr.substring(0, _amountStr.length - 1);
      } else {
        _amountStr = '0';
      }
    });
  }

  void _swapCurrencies() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
    });
  }

  double get _convertedAmount {
    final amount =
        double.tryParse(_amountStr.replaceAll('.', '').replaceAll(',', '.')) ??
        0;
    return amount * _fromCurrency['rate'] / _toCurrency['rate'];
  }

  String _formatValue(double value) {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: value < 1 && value > 0 ? (value < 0.0001 ? 6 : 4) : 0,
    );
    return format.format(value).trim();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(currencyRatesProvider, (prev, next) {
      next.whenData((rates) {
        setState(() {
          _updateRatesFromMap(rates);
          _isLoading = false;
        });
      });
    });

    final theme = Theme.of(context);
    final isDarkMode =
        ref.watch(themeProvider) == ThemeMode.dark ||
        (ref.watch(themeProvider) == ThemeMode.system &&
            theme.brightness == Brightness.dark);
    final contentColor = isDarkMode ? Colors.white : AppColors.primaryDark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? AppColors.backgroundDark
          : const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: contentColor,
            size: 20,
          ),
        ),
        title: Text(
          'Konverter Valas',
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: contentColor,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _fetchRates,
            icon: Icon(
              Icons.refresh_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoading)
            const LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 2,
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReferenceLabel('DARI', isDarkMode),
                  const SizedBox(height: 6),
                  _buildCurrencyCard(
                    _fromCurrency,
                    _amountStr,
                    true,
                    isDarkMode,
                  ),

                  const SizedBox(height: 8),
                  Center(
                    child: IconButton.filledTonal(
                      onPressed: _swapCurrencies,
                      icon: const Icon(
                        Icons.swap_vert_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.1,
                        ),
                        padding: const EdgeInsets.all(6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  _buildReferenceLabel('KE', isDarkMode),
                  const SizedBox(height: 6),
                  _buildCurrencyCard(
                    _toCurrency,
                    _formatValue(_convertedAmount),
                    false,
                    isDarkMode,
                  ),

                  if (_lastUpdated != null) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Pembaruan terakhir: ${DateFormat('HH:mm').format(_lastUpdated!)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: contentColor.withValues(alpha: 0.3),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),


          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isNumpadVisible
                ? (320 + MediaQuery.of(context).padding.bottom)
                : 0,
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: _buildNumpad(isDarkMode),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceLabel(String label, bool isDarkMode) {
    final contentColor = isDarkMode ? Colors.white : AppColors.primaryDark;
    return Text(
      label,
      style: GoogleFonts.comicNeue(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        color: contentColor.withValues(alpha: 0.4),
      ),
    );
  }

  Widget _buildCurrencyCard(
    Map<String, dynamic> currency,
    String val,
    bool isFrom,
    bool isDarkMode,
  ) {
    final contentColor = isDarkMode ? Colors.white : AppColors.primaryDark;
    final isActive = isFrom && _isNumpadVisible;

    return InkWell(
      onTap: isFrom
          ? () => setState(() => _isNumpadVisible = !_isNumpadVisible)
          : () => _showCurrencyPicker(context, isFrom),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? AppColors.primary
                : (isDarkMode
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05)),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currency['symbol'],
                          style: GoogleFonts.comicNeue(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (isActive && val == '0') ...[
                          _buildBlinkingCursor(isDarkMode),
                          const SizedBox(width: 2),
                        ],
                        Text(
                          val,
                          style: GoogleFonts.comicNeue(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: val == '0'
                                ? contentColor.withValues(alpha: 0.3)
                                : contentColor,
                          ),
                        ),
                        if (isActive && val != '0') ...[
                          const SizedBox(width: 2),
                          _buildBlinkingCursor(isDarkMode),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    currency['name'],
                    style: TextStyle(
                      fontSize: 10,
                      color: contentColor.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: () => _showCurrencyPicker(context, isFrom),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currency['flag'],
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      currency['code'],
                      style: GoogleFonts.comicNeue(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlinkingCursor(bool isDarkMode) {
    return _BlinkingCursor(isDarkMode: isDarkMode);
  }

  Widget _buildNumpad(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF121212) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildNumpadRow(['1', '2', '3'], isDarkMode),
          _buildNumpadRow(['4', '5', '6'], isDarkMode),
          _buildNumpadRow(['7', '8', '9'], isDarkMode),
          _buildNumpadRow(['.', '0', 'back'], isDarkMode),
        ],
      ),
    );
  }

  Widget _buildNumpadRow(List<String> values, bool isDarkMode) {
    return Row(
      children: values
          .map((val) => _numpadBtn(val, isDarkMode, isIcon: val == 'back'))
          .toList(),
    );
  }

  Widget _numpadBtn(String val, bool isDarkMode, {bool isIcon = false}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (val == 'back') {
                _onBackspace();
              } else {
                _onNumberPress(val);
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.black.withValues(alpha: 0.01),
              ),
              child: isIcon
                  ? Icon(
                      Icons.backspace_outlined,
                      color: AppColors.primary,
                      size: 20,
                    )
                  : Text(
                      val,
                      style: GoogleFonts.comicNeue(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode
                            ? Colors.white
                            : AppColors.primaryDark,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, bool isFrom) {
    final isDarkMode = ref.read(themeProvider) == ThemeMode.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Pilih Mata Uang',
              style: GoogleFonts.comicNeue(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _currencies.length,
                itemBuilder: (context, index) {
                  final curr = _currencies[index];
                  final isSelected =
                      (isFrom ? _fromCurrency : _toCurrency) == curr;
                  return ListTile(
                    leading: Text(
                      curr['flag'],
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(
                      curr['code'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      curr['name'],
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white54 : Colors.black54,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        if (isFrom)
                          _fromCurrency = curr;
                        else
                          _toCurrency = curr;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  final bool isDarkMode;
  const _BlinkingCursor({required this.isDarkMode});

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(width: 2, height: 22, color: AppColors.primary),
    );
  }
}
