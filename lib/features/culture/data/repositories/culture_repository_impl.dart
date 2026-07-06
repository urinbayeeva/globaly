import '../../domain/culture_briefing.dart';
import '../../domain/culture_repository.dart';
import '../datasources/gemini_culture_datasource.dart';

class CultureRepositoryImpl implements CultureRepository {
  CultureRepositoryImpl(this._ds);

  final CultureDataSource _ds;

  final Map<String, CultureBriefing> _cache = <String, CultureBriefing>{};
  final Map<String, Future<CultureBriefing>> _inflight =
      <String, Future<CultureBriefing>>{};

  @override
  bool get isConfigured => _ds.isConfigured;

  @override
  Future<CultureBriefing> forCountry({
    required String country,
    required String flag,
  }) {
    final String key = country.toLowerCase();
    final CultureBriefing? cached = _cache[key];
    if (cached != null) return Future<CultureBriefing>.value(cached);

    final Future<CultureBriefing>? pending = _inflight[key];
    if (pending != null) return pending;

    final Future<CultureBriefing> task = _fetch(key, country, flag);
    _inflight[key] = task;
    return task;
  }

  Future<CultureBriefing> _fetch(
    String key,
    String country,
    String flag,
  ) async {
    try {
      final CultureBriefing briefing =
          await _ds.briefing(country: country, flag: flag);
      if (!briefing.isEmpty) _cache[key] = briefing;
      return briefing;
    } finally {
      _inflight.remove(key)?.ignore();
    }
  }
}
