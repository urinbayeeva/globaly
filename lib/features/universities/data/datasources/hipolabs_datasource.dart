import 'dart:convert';
import 'package:dio/dio.dart';

import '../../../../core/utils/app_logger.dart';

class HipolabsUniversity {
  HipolabsUniversity({
    required this.name,
    required this.country,
    required this.alphaTwoCode,
    required this.stateProvince,
    required this.domain,
    required this.webPage,
  });

  factory HipolabsUniversity.fromJson(Map<String, dynamic> j) {
    final List<String> domains = _stringList(j['domains']);
    final List<String> webPages = _stringList(j['web_pages']);
    return HipolabsUniversity(
      name: (j['name'] as String?)?.trim() ?? '',
      country: (j['country'] as String?)?.trim() ?? '',
      alphaTwoCode: (j['alpha_two_code'] as String?)?.trim() ?? '',
      stateProvince: (j['state-province'] as String?)?.trim() ?? '',
      domain: domains.isEmpty ? '' : domains.first,
      webPage: webPages.isEmpty ? '' : webPages.first,
    );
  }

  final String name;
  final String country;
  final String alphaTwoCode;
  final String stateProvince;
  final String domain;
  final String webPage;

  static List<String> _stringList(Object? v) {
    if (v is List) {
      return v
          .map((dynamic e) => e?.toString().trim() ?? '')
          .where((String s) => s.isNotEmpty)
          .toList();
    }
    return const <String>[];
  }
}

abstract class HipolabsDataSource {
  Future<List<HipolabsUniversity>> searchByCountry(String countryName);
}

class HipolabsDataSourceImpl implements HipolabsDataSource {
  HipolabsDataSourceImpl(this._dio);
  final Dio _dio;

  static const String _liveEndpoint =
      'https://universities.hipolabs.com/search';

  static const String _githubMirror =
      'https://raw.githubusercontent.com/Hipo/university-domains-list/master/world_universities_and_domains.json';

  List<HipolabsUniversity>? _allFromMirror;

  @override
  Future<List<HipolabsUniversity>> searchByCountry(String countryName) async {
    try {
      return await _searchLive(countryName);
    } catch (e) {
      appLogger.w('🎓 Hipolabs live API failed → trying GitHub mirror: $e');
      return _searchMirror(countryName);
    }
  }

  Future<List<HipolabsUniversity>> _searchLive(String countryName) async {
    final Response<dynamic> res = await _dio.get<dynamic>(
      _liveEndpoint,
      queryParameters: <String, dynamic>{'country': countryName},
      options: Options(
        receiveTimeout: const Duration(seconds: 8),
        sendTimeout: const Duration(seconds: 8),
        responseType: ResponseType.plain,
      ),
    );
    final List<dynamic> raw = jsonDecode(res.data as String) as List<dynamic>;
    return raw
        .whereType<Map<String, dynamic>>()
        .map(HipolabsUniversity.fromJson)
        .where((HipolabsUniversity u) => u.name.isNotEmpty)
        .toList();
  }

  Future<List<HipolabsUniversity>> _searchMirror(String countryName) async {
    _allFromMirror ??= await _fetchMirror();
    final String target = countryName.toLowerCase();
    return _allFromMirror!
        .where((HipolabsUniversity u) => u.country.toLowerCase() == target)
        .toList();
  }

  Future<List<HipolabsUniversity>> _fetchMirror() async {
    final Response<dynamic> res = await _dio.get<dynamic>(
      _githubMirror,
      options: Options(
        receiveTimeout: const Duration(seconds: 30),
        responseType: ResponseType.plain,
      ),
    );
    final List<dynamic> raw = jsonDecode(res.data as String) as List<dynamic>;
    final List<HipolabsUniversity> list = raw
        .whereType<Map<String, dynamic>>()
        .map(HipolabsUniversity.fromJson)
        .where((HipolabsUniversity u) => u.name.isNotEmpty)
        .toList();
    appLogger.i(
      '🎓 GitHub mirror loaded: ${list.length} universities (cached for session)',
    );
    return list;
  }
}
