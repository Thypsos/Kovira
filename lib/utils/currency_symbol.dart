import 'dart:io' show Platform;
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const Map<String, String> targetMarketSymbols = {
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

const Map<String, String> _timezoneToCountry = {
  'Asia/Dhaka': 'BD',
  'Asia/Kolkata': 'IN',
  'Asia/Calcutta': 'IN',
  'Asia/Karachi': 'PK',
  'Asia/Colombo': 'LK',
  'Asia/Kathmandu': 'NP',
  'Asia/Thimphu': 'BT',
  'Asia/Kabul': 'AF',
  'Indian/Maldives': 'MV',
  'Asia/Jakarta': 'ID',
  'Asia/Makassar': 'ID',
  'Asia/Jayapura': 'ID',
  'Asia/Manila': 'PH',
  'Asia/Ho_Chi_Minh': 'VN',
  'Asia/Saigon': 'VN',
  'Asia/Bangkok': 'TH',
  'Asia/Kuala_Lumpur': 'MY',
  'Asia/Kuching': 'MY',
  'Asia/Yangon': 'MM',
  'Asia/Rangoon': 'MM',
  'Asia/Phnom_Penh': 'KH',
  'Asia/Vientiane': 'LA',
  'Asia/Singapore': 'SG',
  'Africa/Nairobi': 'KE',
  'Africa/Dar_es_Salaam': 'TZ',
  'Africa/Kampala': 'UG',
  'Africa/Lagos': 'NG',
  'Africa/Accra': 'GH',
  'Africa/Johannesburg': 'ZA',
  'Africa/Cairo': 'EG',
  'Africa/Casablanca': 'MA',
  'Africa/Addis_Ababa': 'ET',
  'Africa/Kigali': 'RW',
  'Africa/Dakar': 'SN',
  'Africa/Abidjan': 'CI',
  'America/Sao_Paulo': 'BR',
  'America/Manaus': 'BR',
  'America/Recife': 'BR',
  'America/Mexico_City': 'MX',
  'America/Argentina/Buenos_Aires': 'AR',
  'America/Buenos_Aires': 'AR',
  'America/Bogota': 'CO',
  'America/Lima': 'PE',
  'America/Santiago': 'CL',
  'America/Caracas': 'VE',
  'Asia/Riyadh': 'SA',
  'Asia/Dubai': 'AE',
  'Asia/Tehran': 'IR',
  'Asia/Baghdad': 'IQ',
  'Asia/Amman': 'JO',
  'Asia/Beirut': 'LB',
  'Europe/Istanbul': 'TR',
  'Asia/Istanbul': 'TR',
  'Asia/Jerusalem': 'IL',
  'America/New_York': 'US',
  'America/Detroit': 'US',
  'America/Chicago': 'US',
  'America/Denver': 'US',
  'America/Phoenix': 'US',
  'America/Los_Angeles': 'US',
  'America/Anchorage': 'US',
  'Pacific/Honolulu': 'US',
  'Europe/London': 'GB',
  'America/Toronto': 'CA',
  'America/Vancouver': 'CA',
  'America/Edmonton': 'CA',
  'America/Winnipeg': 'CA',
  'America/Halifax': 'CA',
  'Australia/Sydney': 'AU',
  'Australia/Melbourne': 'AU',
  'Australia/Brisbane': 'AU',
  'Australia/Perth': 'AU',
  'Australia/Adelaide': 'AU',
  'Pacific/Auckland': 'NZ',
  'Asia/Tokyo': 'JP',
  'Asia/Shanghai': 'CN',
  'Asia/Hong_Kong': 'HK',
  'Asia/Seoul': 'KR',
  'Asia/Taipei': 'TW',
  'Europe/Moscow': 'RU',
  'Europe/Kiev': 'UA',
  'Europe/Kyiv': 'UA',
  'Europe/Warsaw': 'PL',
  'Europe/Prague': 'CZ',
  'Europe/Budapest': 'HU',
  'Europe/Stockholm': 'SE',
  'Europe/Oslo': 'NO',
  'Europe/Copenhagen': 'DK',
  'Europe/Zurich': 'CH',
  'Europe/Berlin': 'DE',
  'Europe/Paris': 'FR',
  'Europe/Rome': 'IT',
  'Europe/Madrid': 'ES',
  'Europe/Amsterdam': 'NL',
  'Europe/Brussels': 'BE',
  'Europe/Vienna': 'AT',
  'Europe/Dublin': 'IE',
  'Europe/Helsinki': 'FI',
  'Europe/Lisbon': 'PT',
  'Europe/Athens': 'GR',
  'Europe/Luxembourg': 'LU',
};

class CurrencyDetector {
  static String? cachedTimezone;
  static String? overrideSymbol;

  static String? countryFromTimezone() {
    final tz = cachedTimezone;
    if (tz == null || tz.isEmpty) return null;
    return _timezoneToCountry[tz];
  }
}

String _detectSymbolNoOverride() {
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

  final tzCountry = CurrencyDetector.countryFromTimezone();
  if (tzCountry != null && targetMarketSymbols.containsKey(tzCountry)) {
    return targetMarketSymbols[tzCountry]!;
  }

  if (country.isNotEmpty && targetMarketSymbols.containsKey(country)) {
    return targetMarketSymbols[country]!;
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

String deviceCurrencySymbol(BuildContext? context) {
  final override = CurrencyDetector.overrideSymbol;
  if (override != null && override.isNotEmpty) return override;
  return _detectSymbolNoOverride();
}

String deviceCurrencySymbolStatic() => deviceCurrencySymbol(null);

String autoDetectedCurrencySymbol() => _detectSymbolNoOverride();

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
  info['Timezone'] = CurrencyDetector.cachedTimezone ?? '(null)';
  info['Override'] = CurrencyDetector.overrideSymbol ?? '(none)';
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
