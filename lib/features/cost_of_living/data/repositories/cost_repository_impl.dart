import '../../domain/city_cost.dart';
import '../../domain/cost_repository.dart';
import '../datasources/gemini_cost_datasource.dart';

class CostRepositoryImpl implements CostRepository {
  CostRepositoryImpl(this._ds);

  final CostDataSource _ds;

  final Map<String, List<CityCost>> _cache = <String, List<CityCost>>{};
  final Map<String, Future<List<CityCost>>> _inflight =
      <String, Future<List<CityCost>>>{};

  @override
  Future<List<CityCost>> forCountry({
    required String country,
    required String flag,
  }) {
    final String key = country.toLowerCase();
    final List<CityCost>? cached = _cache[key];
    if (cached != null) return Future<List<CityCost>>.value(cached);

    final Future<List<CityCost>>? pending = _inflight[key];
    if (pending != null) return pending;

    final Future<List<CityCost>> task = _fetch(key, country, flag);
    _inflight[key] = task;
    return task;
  }

  Future<List<CityCost>> _fetch(
    String key,
    String country,
    String flag,
  ) async {
    try {
      final List<CityCost> cities =
          await _ds.cities(country: country, flag: flag);
      if (cities.isNotEmpty) _cache[key] = cities;
      return cities;
    } finally {
      _inflight.remove(key)?.ignore();
    }
  }
}
