import 'dart:io' show Platform;
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const Map<String, String> _targetMarketSymbols = {
  'BD': '৳',
  'IN': '₹',
  'PK': '₨',
  'LK': '₨',
  'NP': '₨',
  'BT': 'Nu.',
  'MV': 'Rf',
  'AF': '؋',

  'ID': 'Rp',
  'PH': '₱',
  'VN': '₫',
  'TH': '฿',
  'MY': 'RM',
  'MM': 'K',
  'KH': '៛',
  'LA': '₭',
  'SG': 'S\$',

  'KE': 'KSh',
  'TZ': 'TSh',
  'UG': 'USh',
  'NG': '₦',
  'GH': '₵',
  'ZA': 'R',
  'EG': 'ج.م',
  'MA': 'د.م',
  'ET': 'Br',
  'RW': 'FRw',
  'SN': 'CFA',
  'CI': 'CFA',

  'BR': 'R\$',
  'MX': '\$',
  'AR': '\$',
  'CO': '\$',
  'PE': 'S/',
  'CL': '\$',
  'VE': 'Bs.',

  'SA': 'ر.س',
  'AE': 'د.إ',
  'IR': '﷼',
  'IQ': 'ع.د',
  'JO': 'د.أ',
  'LB': 'ل.ل',
  'TR': '₺',
  'IL': '₪',

  'US': '\$',
  'GB': '£',
  'CA': 'C\$',
  'AU': 'A\$',
  'NZ': 'NZ\$',
  'JP': '¥',
  'CN': '¥',
  'KR': '₩',
  'HK': 'HK\$',
  'TW': 'NT\$',
  'RU': '₽',
  'UA': '₴',
  'PL': 'zł',
  'CZ': 'Kč',
  'HU': 'Ft',
  'SE': 'kr',
  'NO': 'kr',
  'DK': 'kr',
  'CH': 'CHF',

  'DE': '€',
  'FR': '€',
  'IT': '€',
  'ES': '€',
  'NL': '€',
  'BE': '€',
  'AT': '€',
  'IE': '€',
  'FI': '€',
  'PT': '€',
  'GR': '€',
  'LU': '€',
};

const Map<String, String> _languageFallback = {
  'bn': '৳',
  'hi': '₹',
  'ur': '₨',
  'ta': '₹',
  'te': '₹',
  'mr': '₹',
  'gu': '₹',
  'pa': '₹',
  'id': 'Rp',
  'ms': 'RM',
  'th': '฿',
  'vi': '₫',
  'tl': '₱',
  'sw': 'KSh',
  'ar': 'ر.س',
  'fa': '﷼',
  'tr': '₺',
  'ru': '₽',
  'zh': '¥',
  'ja': '¥',
  'ko': '₩',
  'pt': 'R\$',
  'es': '\$',
  'de': '€',
  'fr': '€',
  'it': '€',
  'nl': '€',
  'en': '\$',
};

String deviceCurrencySymbol(BuildContext? context) {
  String lang = '';
  String country = '';

  try {
    final raw = Platform.localeName.split('.').first.replaceAll('-', '_');
    final parts = raw.split('_');
    if (parts.isNotEmpty) lang = parts[0].toLowerCase();
    if (parts.length > 1) country = parts[1].toUpperCase();
  } catch (_) {}

  if (country.isEmpty) {
    try {
      final locale = PlatformDispatcher.instance.locale;
      if (lang.isEmpty) lang = locale.languageCode.toLowerCase();
      country = (locale.countryCode ?? '').toUpperCase();
    } catch (_) {}
  }

  if (country.isNotEmpty && _targetMarketSymbols.containsKey(country)) {
    return _targetMarketSymbols[country]!;
  }

  try {
    final cleaned = country.isNotEmpty ? '${lang}_$country' : lang;
    if (cleaned.isNotEmpty) {
      final fmt = NumberFormat.simpleCurrency(locale: cleaned);
      final sym = fmt.currencySymbol;
      if (sym.isNotEmpty && sym.length < 10) return sym;
    }
  } catch (_) {}

  if (lang.isNotEmpty && _languageFallback.containsKey(lang)) {
    return _languageFallback[lang]!;
  }

  return '\$';
}

String deviceCurrencySymbolStatic() => deviceCurrencySymbol(null);

Map<String, String> currencyDebugInfo() {
  final info = <String, String>{};
  try {
    final locale = PlatformDispatcher.instance.locale;
    info['PD.lang'] = locale.languageCode;
    info['PD.country'] = locale.countryCode ?? '(null)';
    info['PD.full'] = locale.toString();
  } catch (e) {
    info['PD.error'] = e.toString();
  }
  try {
    info['Platform.localeName'] = Platform.localeName;
  } catch (e) {
    info['Platform.error'] = e.toString();
  }
  info['Resolved symbol'] = deviceCurrencySymbolStatic();
  return info;
}

String currencyDetectionDebug() {
  final info = currencyDebugInfo();
  final lines = <String>[];
  info.forEach((k, v) => lines.add('$k: $v'));
  return lines.join('\n');
}

Widget amountPrefixIcon(BuildContext context, {double fontSize = 18}) {
  final cs = Theme.of(context).colorScheme;
  return Padding(
    padding: const EdgeInsets.only(left: 12, right: 6),
    child: Center(
      widthFactor: 1,
      child: Text(
        deviceCurrencySymbol(context),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: cs.primary.withValues(alpha: 0.7),
        ),
      ),
    ),
  );
}
