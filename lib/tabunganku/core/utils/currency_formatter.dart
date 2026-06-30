import 'package:flutter/services.dart';



class RibuanFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;


    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return const TextEditingValue(text: '');

    final formatted = formatNumber(digitsOnly);


    int numDigitsBefore =
        newValue.selection.end -
        newValue.text
            .substring(0, newValue.selection.end)
            .replaceAll(RegExp(r'[0-9]'), '')
            .length;

    int newSelectionIndex = 0;
    int digitsCount = 0;
    while (digitsCount < numDigitsBefore &&
        newSelectionIndex < formatted.length) {
      if (RegExp(r'[0-9]').hasMatch(formatted[newSelectionIndex])) {
        digitsCount++;
      }
      newSelectionIndex++;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newSelectionIndex),
    );
  }


  static String formatNumber(dynamic value) {
    if (value == null) return '0';
    String digitsOnly = value.toString().replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return '0';
    return digitsOnly.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
  }
}
