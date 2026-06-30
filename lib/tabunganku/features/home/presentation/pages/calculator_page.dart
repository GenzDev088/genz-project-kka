import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otax/tabunganku/core/theme/app_colors.dart';
import 'package:otax/tabunganku/core/theme/theme_provider.dart';

class CalculatorPage extends ConsumerStatefulWidget {
  const CalculatorPage({super.key});

  @override
  ConsumerState<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends ConsumerState<CalculatorPage> {
  String _output = "0";
  String _currentExpression = "";
  double _num1 = 0;
  double _num2 = 0;
  String _operand = "";
  bool _isFinished = false;

  void _buttonPressed(String buttonText) {
    setState(() {
      if (buttonText == "C") {
        _output = "0";
        _currentExpression = "";
        _num1 = 0;
        _num2 = 0;
        _operand = "";
        _isFinished = false;
      } else if (buttonText == "+" ||
          buttonText == "-" ||
          buttonText == "x" ||
          buttonText == "/") {
        if (_operand.isNotEmpty && !_isFinished) {
          _calculate();
        }
        _num1 = double.parse(_output);
        _operand = buttonText;
        _currentExpression = "$_output $buttonText ";
        _isFinished = false;
      } else if (buttonText == ".") {
        if (_output.contains(".")) {
          return;
        } else {
          _output = _output + buttonText;
        }
      } else if (buttonText == "=") {
        _calculate();
        _operand = "";
        _isFinished = true;
      } else {
        if (_output == "0" || _isFinished) {
          _output = buttonText;
          _isFinished = false;
        } else {
          _output = _output + buttonText;
        }
      }
    });
  }

  void _calculate() {
    _num2 = double.parse(_output);
    if (_operand == "+") {
      _output = (_num1 + _num2).toString();
    }
    if (_operand == "-") {
      _output = (_num1 - _num2).toString();
    }
    if (_operand == "x") {
      _output = (_num1 * _num2).toString();
    }
    if (_operand == "/") {
      _output = (_num1 / _num2).toString();
    }
    if (_output.endsWith(".0")) {
      _output = _output.substring(0, _output.length - 2);
    }
    _currentExpression = "";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode =
        ref.watch(themeProvider) == ThemeMode.dark ||
        (ref.watch(themeProvider) == ThemeMode.system &&
            theme.brightness == Brightness.dark);

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDarkMode ? Colors.white : AppColors.primaryDark,
            size: 20,
          ),
        ),
        title: Text(
          'Kalkulator',
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isDarkMode ? Colors.white : AppColors.primaryDark,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.bottomRight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _currentExpression,
                    style: TextStyle(
                      fontSize: 24,
                      color: isDarkMode ? Colors.white24 : Colors.black26,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _output,
                      style: GoogleFonts.comicNeue(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode
                            ? Colors.white
                            : AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF121212)
                  : AppColors.background,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(40),
              ),
            ),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _calcButton("C", isAction: true, isDarkMode: isDarkMode),
                _calcButton("/", isOperator: true, isDarkMode: isDarkMode),
                _calcButton("x", isOperator: true, isDarkMode: isDarkMode),
                _calcButton("DEL", isAction: true, isDarkMode: isDarkMode),
                _calcButton("7", isDarkMode: isDarkMode),
                _calcButton("8", isDarkMode: isDarkMode),
                _calcButton("9", isDarkMode: isDarkMode),
                _calcButton("-", isOperator: true, isDarkMode: isDarkMode),
                _calcButton("4", isDarkMode: isDarkMode),
                _calcButton("5", isDarkMode: isDarkMode),
                _calcButton("6", isDarkMode: isDarkMode),
                _calcButton("+", isOperator: true, isDarkMode: isDarkMode),
                _calcButton("1", isDarkMode: isDarkMode),
                _calcButton("2", isDarkMode: isDarkMode),
                _calcButton("3", isDarkMode: isDarkMode),
                _calcButton(
                  "=",
                  isOperator: true,
                  isPrimary: true,
                  isDarkMode: isDarkMode,
                ),
                _calcButton("0", isDarkMode: isDarkMode),
                _calcButton(".", isDarkMode: isDarkMode),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _calcButton(
    String text, {
    bool isOperator = false,
    bool isAction = false,
    bool isPrimary = false,
    required bool isDarkMode,
  }) {
    Color bgColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white;
    Color textColor = isDarkMode ? Colors.white : AppColors.primaryDark;

    if (isOperator) {
      bgColor = isPrimary
          ? AppColors.primary
          : (isDarkMode
                ? Colors.teal.shade900.withValues(alpha: 0.3)
                : Colors.teal.shade50);
      textColor = isPrimary
          ? Colors.white
          : (isDarkMode ? Colors.teal.shade300 : AppColors.primary);
    } else if (isAction) {
      bgColor = isDarkMode
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.grey.shade100;
      textColor = isDarkMode ? Colors.redAccent.shade100 : Colors.red;
    }

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () {
          if (text == "DEL") {
            setState(() {
              if (_output.length > 1) {
                _output = _output.substring(0, _output.length - 1);
              } else {
                _output = "0";
              }
            });
          } else {
            _buttonPressed(text);
          }
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          alignment: Alignment.center,
          child: Text(
            text,
            style: GoogleFonts.comicNeue(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
