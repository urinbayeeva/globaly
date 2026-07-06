import 'dart:async';

import 'package:dio/dio.dart';

import '../config/env.dart';
import '../utils/app_logger.dart';

class CurrencyService {
  CurrencyService(this._dio);
  final Dio _dio;

  final Map<String, double> _cache = <String, double>{};
  final Map<String, Future<double?>> _inFlight = <String, Future<double?>>{};

  static const Map<String, String> _countryToCurrency = <String, String>{
    'AF': 'AFN',
    'AL': 'ALL',
    'DZ': 'DZD',
    'AD': 'EUR',
    'AO': 'AOA',
    'AG': 'XCD',
    'AR': 'ARS',
    'AM': 'AMD',
    'AU': 'AUD',
    'AT': 'EUR',
    'AZ': 'AZN',
    'BS': 'BSD',
    'BH': 'BHD',
    'BD': 'BDT',
    'BB': 'BBD',
    'BY': 'BYN',
    'BE': 'EUR',
    'BZ': 'BZD',
    'BJ': 'XOF',
    'BT': 'BTN',
    'BO': 'BOB',
    'BA': 'BAM',
    'BW': 'BWP',
    'BR': 'BRL',
    'BN': 'BND',
    'BG': 'BGN',
    'BF': 'XOF',
    'BI': 'BIF',
    'KH': 'KHR',
    'CM': 'XAF',
    'CA': 'CAD',
    'CV': 'CVE',
    'CF': 'XAF',
    'TD': 'XAF',
    'CL': 'CLP',
    'CN': 'CNY',
    'CO': 'COP',
    'KM': 'KMF',
    'CG': 'XAF',
    'CD': 'CDF',
    'CR': 'CRC',
    'CI': 'XOF',
    'HR': 'EUR',
    'CU': 'CUP',
    'CY': 'EUR',
    'CZ': 'CZK',
    'DK': 'DKK',
    'DJ': 'DJF',
    'DM': 'XCD',
    'DO': 'DOP',
    'EC': 'USD',
    'EG': 'EGP',
    'SV': 'USD',
    'GQ': 'XAF',
    'ER': 'ERN',
    'EE': 'EUR',
    'SZ': 'SZL',
    'ET': 'ETB',
    'FJ': 'FJD',
    'FI': 'EUR',
    'FR': 'EUR',
    'GA': 'XAF',
    'GM': 'GMD',
    'GE': 'GEL',
    'DE': 'EUR',
    'GH': 'GHS',
    'GR': 'EUR',
    'GD': 'XCD',
    'GT': 'GTQ',
    'GN': 'GNF',
    'GW': 'XOF',
    'GY': 'GYD',
    'HT': 'HTG',
    'HN': 'HNL',
    'HK': 'HKD',
    'HU': 'HUF',
    'IS': 'ISK',
    'IN': 'INR',
    'ID': 'IDR',
    'IR': 'IRR',
    'IQ': 'IQD',
    'IE': 'EUR',
    'IL': 'ILS',
    'IT': 'EUR',
    'JM': 'JMD',
    'JP': 'JPY',
    'JO': 'JOD',
    'KZ': 'KZT',
    'KE': 'KES',
    'KI': 'AUD',
    'KW': 'KWD',
    'KG': 'KGS',
    'LA': 'LAK',
    'LV': 'EUR',
    'LB': 'LBP',
    'LS': 'LSL',
    'LR': 'LRD',
    'LY': 'LYD',
    'LI': 'CHF',
    'LT': 'EUR',
    'LU': 'EUR',
    'MO': 'MOP',
    'MG': 'MGA',
    'MW': 'MWK',
    'MY': 'MYR',
    'MV': 'MVR',
    'ML': 'XOF',
    'MT': 'EUR',
    'MH': 'USD',
    'MR': 'MRU',
    'MU': 'MUR',
    'MX': 'MXN',
    'FM': 'USD',
    'MD': 'MDL',
    'MC': 'EUR',
    'MN': 'MNT',
    'ME': 'EUR',
    'MA': 'MAD',
    'MZ': 'MZN',
    'MM': 'MMK',
    'NA': 'NAD',
    'NR': 'AUD',
    'NP': 'NPR',
    'NL': 'EUR',
    'NZ': 'NZD',
    'NI': 'NIO',
    'NE': 'XOF',
    'NG': 'NGN',
    'KP': 'KPW',
    'MK': 'MKD',
    'NO': 'NOK',
    'OM': 'OMR',
    'PK': 'PKR',
    'PW': 'USD',
    'PS': 'ILS',
    'PA': 'PAB',
    'PG': 'PGK',
    'PY': 'PYG',
    'PE': 'PEN',
    'PH': 'PHP',
    'PL': 'PLN',
    'PT': 'EUR',
    'QA': 'QAR',
    'RO': 'RON',
    'RU': 'RUB',
    'RW': 'RWF',
    'KN': 'XCD',
    'LC': 'XCD',
    'VC': 'XCD',
    'WS': 'WST',
    'SM': 'EUR',
    'ST': 'STN',
    'SA': 'SAR',
    'SN': 'XOF',
    'RS': 'RSD',
    'SC': 'SCR',
    'SL': 'SLE',
    'SG': 'SGD',
    'SK': 'EUR',
    'SI': 'EUR',
    'SB': 'SBD',
    'SO': 'SOS',
    'ZA': 'ZAR',
    'KR': 'KRW',
    'SS': 'SSP',
    'ES': 'EUR',
    'LK': 'LKR',
    'SD': 'SDG',
    'SR': 'SRD',
    'SE': 'SEK',
    'CH': 'CHF',
    'SY': 'SYP',
    'TW': 'TWD',
    'TJ': 'TJS',
    'TZ': 'TZS',
    'TH': 'THB',
    'TL': 'USD',
    'TG': 'XOF',
    'TO': 'TOP',
    'TT': 'TTD',
    'TN': 'TND',
    'TR': 'TRY',
    'TM': 'TMT',
    'TV': 'AUD',
    'UG': 'UGX',
    'UA': 'UAH',
    'AE': 'AED',
    'GB': 'GBP',
    'US': 'USD',
    'UY': 'UYU',
    'UZ': 'UZS',
    'VU': 'VUV',
    'VA': 'EUR',
    'VE': 'VES',
    'VN': 'VND',
    'YE': 'YER',
    'ZM': 'ZMW',
    'ZW': 'ZWL',
  };

  static const Map<String, String> _symbols = <String, String>{
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'CNY': '¥',
    'KRW': '₩',
    'INR': '₹',
    'RUB': '₽',
    'TRY': '₺',
    'UAH': '₴',
    'CHF': 'Fr',
    'CAD': 'CA\$',
    'AUD': 'AU\$',
    'NZD': 'NZ\$',
    'HKD': 'HK\$',
    'SGD': 'S\$',
    'BRL': 'R\$',
    'MXN': 'Mex\$',
    'ZAR': 'R',
    'AED': 'د.إ',
    'SAR': '﷼',
    'ILS': '₪',
    'PHP': '₱',
    'THB': '฿',
    'VND': '₫',
    'IDR': 'Rp',
    'MYR': 'RM',
    'PLN': 'zł',
    'CZK': 'Kč',
    'SEK': 'kr',
    'NOK': 'kr',
    'DKK': 'kr',
    'HUF': 'Ft',
  };

  String? currencyFor(String countryCode) =>
      _countryToCurrency[countryCode.toUpperCase()];

  Future<double?> rate(String fromCode, String toCode) async {
    if (fromCode == toCode) return 1.0;
    if (Env.backendUrl.isEmpty) return null;
    final String key = '$fromCode|$toCode';
    final double? cached = _cache[key];
    if (cached != null) return cached;

    final Future<double?>? inFlight = _inFlight[key];
    if (inFlight != null) return inFlight;
    final Future<double?> task = _fetch(fromCode, toCode);
    _inFlight[key] = task;
    final double? value = await task;
    unawaited(_inFlight.remove(key));
    if (value != null) _cache[key] = value;
    return value;
  }

  Future<double?> _fetch(String from, String to) async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>(
        '${Env.backendUrl}/v1/currency/rate',
        queryParameters: <String, dynamic>{'from': from, 'to': to},
        options: Options(receiveTimeout: const Duration(seconds: 10)),
      );
      final dynamic data = res.data;
      if (data is! Map<String, dynamic>) return null;
      final dynamic raw = data['rate'];
      if (raw is num) return raw.toDouble();
    } catch (e) {
      appLogger.w('💱 FX $from→$to failed: $e');
    }
    return null;
  }

  String format(double amount, String currencyCode) {
    final String symbol = _symbols[currencyCode] ?? currencyCode;
    final int rounded = amount.round();
    final String number = _withThousands(rounded);

    if (_symbols.containsKey(currencyCode)) {
      return '$symbol$number';
    }
    return '$number $currencyCode';
  }

  String _withThousands(int n) {
    final String s = n.abs().toString();
    final StringBuffer out = StringBuffer(n < 0 ? '-' : '');
    final int firstChunk = s.length % 3;
    if (firstChunk > 0) out.write(s.substring(0, firstChunk));
    for (int i = firstChunk; i < s.length; i += 3) {
      if (i > 0) out.write(',');
      out.write(s.substring(i, i + 3));
    }
    return out.toString();
  }
}
