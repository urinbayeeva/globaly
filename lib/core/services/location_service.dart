import 'package:dio/dio.dart';

import '../network/dio_client.dart';
import '../storage/prefs.dart';
import '../utils/app_logger.dart';

class LocationService {
  LocationService(this._dio, this._prefs);

  final DioClient _dio;
  final Prefs _prefs;

  static final List<_Provider> _providers = <_Provider>[
    _Provider(
      'ipwho.is',
      'https://ipwho.is/',
      (Map<String, dynamic> j) => j['country_code'] as String?,
      okCheck: (Map<String, dynamic> j) => j['success'] != false,
    ),
    _Provider(
      'country.is',
      'https://api.country.is/',
      (Map<String, dynamic> j) => j['country'] as String?,
    ),
    _Provider(
      'ipapi.co',
      'https://ipapi.co/json/',
      (Map<String, dynamic> j) => j['country_code'] as String?,
    ),
  ];

  static const Duration _ttl = Duration(days: 7);
  static const Duration _failureCooldown = Duration(hours: 1);
  static const String _fallback = 'UZ';

  String? _memCode;
  DateTime? _lastFailureAt;

  Future<String> getOriginCountry() async {
    if (_memCode != null) return _memCode!;

    final String? cached = _prefs.getString(Prefs.kOriginCountry);
    final int? cachedAtMs = _prefs.getInt(Prefs.kOriginCachedAt);
    if (cached != null && cachedAtMs != null) {
      final DateTime cachedAt = DateTime.fromMillisecondsSinceEpoch(cachedAtMs);
      if (DateTime.now().difference(cachedAt) < _ttl) {
        _memCode = cached;
        appLogger.i('📍 Origin (cache): $cached');
        return cached;
      }
    }

    if (_lastFailureAt != null &&
        DateTime.now().difference(_lastFailureAt!) < _failureCooldown) {
      appLogger.w('📍 Origin in cool-down — returning ${cached ?? _fallback}');
      return cached ?? _fallback;
    }

    for (final _Provider p in _providers) {
      final String? code = await _tryProvider(p);
      if (code != null) {
        _memCode = code;
        await _prefs.setString(Prefs.kOriginCountry, code);
        await _prefs.setInt(
          Prefs.kOriginCachedAt,
          DateTime.now().millisecondsSinceEpoch,
        );
        appLogger.i('📍 Origin via ${p.name}: $code');
        return code;
      }
    }

    _lastFailureAt = DateTime.now();
    appLogger.w('📍 All providers failed → fallback (${cached ?? _fallback})');
    return cached ?? _fallback;
  }

  Future<String?> _tryProvider(_Provider p) async {
    try {
      final Response<dynamic> res = await _dio.instance.get<dynamic>(
        p.url,
        options: Options(
          receiveTimeout: const Duration(seconds: 4),
          sendTimeout: const Duration(seconds: 4),
        ),
      );
      final dynamic data = res.data;
      if (data is! Map<String, dynamic>) return null;
      if (p.okCheck != null && !p.okCheck!(data)) return null;
      final String? code = p.extract(data);
      if (code == null || code.length != 2) return null;
      return code.toUpperCase();
    } catch (e) {
      appLogger.w('📍 ${p.name} lookup failed: $e');
      return null;
    }
  }
}

typedef _Extractor = String? Function(Map<String, dynamic> json);
typedef _OkCheck = bool Function(Map<String, dynamic> json);

class _Provider {
  _Provider(this.name, this.url, this.extract, {this.okCheck});
  final String name;
  final String url;
  final _Extractor extract;
  final _OkCheck? okCheck;
}
