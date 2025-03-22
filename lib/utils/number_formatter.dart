import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ThousandsFormatter extends TextInputFormatter {
  final String separator;

  ThousandsFormatter({this.separator = '.'});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Return empty string if newValue is empty
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Only allow digits
    if (newValue.text.contains(RegExp(r'[^\d\.]'))) {
      return oldValue;
    }

    // Remove all non-digit characters (except decimal)
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Don't format if nothing changed or if deleting
    if (digitsOnly.isEmpty || digitsOnly == oldValue.text.replaceAll(RegExp(r'[^\d]'), '')) {
      return newValue;
    }

    // Format the number with thousand separators
    String formatted = _formatNumber(digitsOnly);

    // Calculate cursor position
    int selectionIndex = newValue.selection.end;
    int oldValueLength = oldValue.text.length;
    int newValueLength = newValue.text.length;
    int formattedLength = formatted.length;
    
    // Adjust selection based on how many characters were added/removed
    int cursorPos = selectionIndex + (formattedLength - newValueLength);
    
    if (cursorPos < 0) {
      cursorPos = 0;
    } else if (cursorPos > formatted.length) {
      cursorPos = formatted.length;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPos),
    );
  }

  String _formatNumber(String value) {
    if (value.isEmpty) return '';
    
    try {
      final number = int.parse(value);
      final formatted = NumberFormat('#,###').format(number);
      return formatted.replaceAll(',', separator);
    } catch (e) {
      return value;
    }
  }
}

// Helper function to convert formatted number string back to number
double parseFormattedNumber(String formattedNumber) {
  if (formattedNumber.isEmpty) return 0;
  String digitsOnly = formattedNumber.replaceAll(RegExp(r'[^\d]'), '');
  return double.tryParse(digitsOnly) ?? 0;
}

// Helper function to format a number to display with thousand separators
String formatNumber(num number, {String separator = '.'}) {
  if (number == 0) return '0';
  
  final formatted = NumberFormat('#,###').format(number);
  return formatted.replaceAll(',', separator);
} 