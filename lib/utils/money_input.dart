import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../data/settings_service.dart';

final NumberFormat _displaySep = NumberFormat('#,##0');
final NumberFormat _displayNoSep = NumberFormat('0');

int? parseCents(String? text) {
  if (text == null) return null;
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;

  final cleaned = trimmed.replaceAll(',', '');

  if ('.'.allMatches(cleaned).length > 1) return null;

  final parts = cleaned.split('.');
  final wholePart = parts[0];
  final fracPart = parts.length > 1 ? parts[1] : '';

  if (wholePart.isEmpty && fracPart.isEmpty) return null;
  if (!RegExp(r'^\d*$').hasMatch(wholePart)) return null;
  if (!RegExp(r'^\d*$').hasMatch(fracPart)) return null;

  final whole = wholePart.isEmpty ? 0 : int.parse(wholePart);

  String frac = fracPart;
  if (frac.length > 2) {
    final halfDigit = int.tryParse(frac[2]) ?? 0;
    frac = frac.substring(0, 2);
    if (halfDigit >= 5) {
      int f = int.parse(frac) + 1;
      if (f == 100) {
        return (whole + 1) * 100;
      }
      frac = f.toString().padLeft(2, '0');
    }
  } else if (frac.length == 1) {
    frac = '${frac}0';
  } else if (frac.isEmpty) {
    frac = '00';
  }
  return whole * 100 + int.parse(frac);
}

String formatMoney(int cents, {bool trimZeroDecimals = false}) {
  final useSep = SettingsService.instance.useThousandSep;
  final smart = SettingsService.instance.smartDecimals;
  final fmt = useSep ? _displaySep : _displayNoSep;
  final sign = cents < 0 ? '-' : '';
  final absC = cents.abs();
  final whole = absC ~/ 100;
  final dec = absC % 100;
  if ((trimZeroDecimals || smart) && dec == 0) {
    return '$sign${fmt.format(whole)}';
  }
  if (smart && dec % 10 == 0) {
    return '$sign${fmt.format(whole)}.${dec ~/ 10}';
  }
  return '$sign${fmt.format(whole)}.${dec.toString().padLeft(2, '0')}';
}

/// Short form for cramped UIs: no thousands separator, no trailing zeros.
/// `50000` → `"500"`, `12345` → `"123.45"`.
String formatMoneyCompact(int cents) {
  if (cents % 100 == 0) return (cents ~/ 100).toString();
  return (cents / 100).toStringAsFixed(2);
}

// ── TextInputFormatter — restrict input to decimal money characters ────────

/// Formatter for money TextFields. Accepts digits, comma (thousands), and at
/// most one period (decimal). Caps fractional digits at 2. Does NOT auto-
/// insert thousands separators as the user types — that's handled visually

class MoneyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    if (!RegExp(r'^[\d,.]*$').hasMatch(text)) return oldValue;

    if ('.'.allMatches(text).length > 1) return oldValue;

    final dot = text.indexOf('.');
    if (dot >= 0) {
      final fracLen = text.length - dot - 1;
      if (fracLen > 2) return oldValue;
    }

    return newValue;
  }
}
