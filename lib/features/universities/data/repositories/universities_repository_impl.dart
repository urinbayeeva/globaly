import 'dart:math';

import '../../../../core/utils/app_logger.dart';
import '../../../profile_setup/data/datasources/countries_db.dart';
import '../../../profile_setup/domain/entities/country.dart';
import '../../domain/entities/university.dart';
import '../../domain/entities/university_insights.dart';
import '../../domain/repositories/universities_repository.dart';
import '../datasources/gemini_insights_datasource.dart'
    show
        GeminiInsightsDataSource,
        GeminiInsightsDataSourceImpl,
        AiRateLimited;
import '../datasources/hipolabs_datasource.dart';
import '../datasources/wikipedia_datasource.dart';

class UniversitiesRepositoryImpl implements UniversitiesRepository {
  UniversitiesRepositoryImpl(
    this._hipolabs,
    this._wiki,
    this._gemini,
    this._countries,
  );

  final HipolabsDataSource _hipolabs;
  final WikipediaDataSource _wiki;
  final GeminiInsightsDataSource _gemini;
  final CountriesDb _countries;

  final Map<String, UniversityInsights> _insights =
      <String, UniversityInsights>{};
  final Map<String, Future<UniversityInsights?>> _insightsInFlight =
      <String, Future<UniversityInsights?>>{};

  final Map<String, DateTime> _insightsRateLimitedUntil = <String, DateTime>{};

  DateTime? _aiGlobalCooldownUntil;

  final Map<String, List<University>> _byCountry = <String, List<University>>{};

  final Map<String, University> _byId = <String, University>{};

  @override
  Future<List<University>> byCountry(String countryName) async {
    final String key = countryName.toLowerCase().trim();
    final List<University>? cached = _byCountry[key];
    if (cached != null) return cached;

    final List<HipolabsUniversity> raw =
        await _hipolabs.searchByCountry(countryName);
    final List<University> list = raw
        .map((HipolabsUniversity u) => _toEntity(u))
        .fold<Map<String, University>>(<String, University>{},
            (Map<String, University> acc, University u) {
          acc.putIfAbsent(u.id, () => u);
          return acc;
        })
        .values
        .toList();

    final Random rng = Random(key.hashCode);
    list.shuffle(rng);

    _byCountry[key] = list;
    for (final University u in list) {
      _byId.putIfAbsent(u.id, () => u);
    }
    appLogger
        .i('🎓 Hipolabs returned ${list.length} universities for $countryName');
    return list;
  }

  @override
  Future<University?> byId(String id) async {
    final University? cached = _byId[id];
    if (cached == null) return null;

    if (cached.about.isNotEmpty || cached.imageUrl.isNotEmpty) return cached;

    final WikipediaSummary s = await _wiki.summary(cached.name);
    final University enriched = cached.copyWith(
      about: s.extract,
      imageUrl: s.imageUrl,
    );
    _byId[id] = enriched;
    return enriched;
  }

  @override
  bool get aiEnabled {
    final dynamic g = _gemini;
    return g is GeminiInsightsDataSourceImpl && g.isConfigured;
  }

  @override
  Future<UniversityInsights?> insights(String id) async {
    if (!aiEnabled) return null;
    final UniversityInsights? cached = _insights[id];
    if (cached != null) return cached;

    final DateTime now = DateTime.now();

    if (_aiGlobalCooldownUntil != null &&
        now.isBefore(_aiGlobalCooldownUntil!)) {
      return null;
    }

    final DateTime? until = _insightsRateLimitedUntil[id];
    if (until != null && now.isBefore(until)) return null;

    final Future<UniversityInsights?>? inFlight = _insightsInFlight[id];
    if (inFlight != null) return inFlight;

    final University? u = _byId[id];
    if (u == null) return null;

    final Future<UniversityInsights?> task = _gemini
        .fetchInsights(u)
        .then<UniversityInsights?>((UniversityInsights value) {
      _insights[id] = value;
      return value;
    }).catchError((Object e) {
      if (e is AiRateLimited) {
        final DateTime expires = DateTime.now().add(e.retryAfter);
        _insightsRateLimitedUntil[id] = expires;
        _aiGlobalCooldownUntil = expires;
        appLogger.w(
          '🤖 Gemini rate-limited for ${u.name} — backing off ${e.retryAfter.inSeconds}s',
        );
      } else {
        appLogger.w('🤖 Gemini insights failed for ${u.name}: $e');
      }
      return null;
    }).whenComplete(() {
      _insightsInFlight.remove(id);
    });
    _insightsInFlight[id] = task;
    return task;
  }

  University _toEntity(HipolabsUniversity h) {
    final Country? c = _countries.byCode(h.alphaTwoCode);
    final String flag = c?.flagEmoji ?? '';
    final String websiteUrl = h.webPage.isNotEmpty
        ? h.webPage
        : (h.domain.isEmpty ? '' : 'https://${h.domain}');
    final String logoUrl = h.domain.isEmpty
        ? ''
        : 'https://logo.clearbit.com/${h.domain}?size=128';
    return University(
      id: _id(h),
      name: h.name,
      country: h.country,
      countryCode: h.alphaTwoCode,
      flag: flag,
      stateProvince: h.stateProvince,
      domain: h.domain,
      websiteUrl: websiteUrl,
      imageUrl: '',
      logoUrl: logoUrl,
      about: '',
    );
  }

  String _id(HipolabsUniversity h) {
    final String input = '${h.name}|${h.alphaTwoCode}|${h.domain}';
    int hash = 0xcbf29ce484222325;
    const int prime = 0x100000001b3;
    for (int i = 0; i < input.length; i++) {
      hash ^= input.codeUnitAt(i);
      hash = (hash * prime) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }
}
