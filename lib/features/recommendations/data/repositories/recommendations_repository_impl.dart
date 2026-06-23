import 'dart:async';

import '../../../../core/services/gemini_client.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/business_opportunity.dart';
import '../../domain/entities/destination.dart';
import '../../domain/entities/document_brief.dart';
import '../../domain/entities/hotel.dart';
import '../../domain/entities/job.dart';
import '../../domain/entities/roadmap_plan.dart';
import '../../domain/entities/visa_info.dart';
import '../../domain/repositories/recommendations_repository.dart';
import '../datasources/gemini_recommendations_datasource.dart';

class RecommendationsRepositoryImpl implements RecommendationsRepository {
  RecommendationsRepositoryImpl(this._ds);

  final GeminiRecommendationsDataSource _ds;

  final Map<String, List<Destination>> _destinationsByCountry =
      <String, List<Destination>>{};
  final Map<String, List<Hotel>> _hotelsByKey = <String, List<Hotel>>{};
  final Map<String, List<Job>> _jobsByKey = <String, List<Job>>{};
  final Map<String, List<BusinessOpportunity>> _businessByCountry =
      <String, List<BusinessOpportunity>>{};
  final Map<String, VisaInfo> _visaByKey = <String, VisaInfo>{};
  final Map<String, RoadmapPlan> _roadmapByKey = <String, RoadmapPlan>{};
  final Map<String, List<DocumentBrief>> _docsByKey =
      <String, List<DocumentBrief>>{};

  final Map<String, Future<Object?>> _inflight = <String, Future<Object?>>{};

  DateTime? _rateLimitedUntil;

  static const Duration _failureTtl = Duration(seconds: 30);
  final Map<String, DateTime> _failedAt = <String, DateTime>{};

  bool _isInRateLimitCooldown() {
    final DateTime? until = _rateLimitedUntil;
    if (until == null) return false;
    if (DateTime.now().isBefore(until)) return true;
    _rateLimitedUntil = null;
    return false;
  }

  bool _isRecentlyFailed(String key) {
    final DateTime? at = _failedAt[key];
    if (at == null) return false;
    if (DateTime.now().difference(at) < _failureTtl) return true;
    _failedAt.remove(key);
    return false;
  }

  Future<T> _guarded<T>({
    required String method,
    required String key,
    required T empty,
    required Future<T> Function() fetch,
    required void Function(T value) onSuccess,
  }) async {
    if (!aiEnabled) return empty;
    if (_isInRateLimitCooldown()) {
      appLogger.w('⏳ $method($key) skipped — Gemini cool-down active');
      return empty;
    }
    if (_isRecentlyFailed('$method:$key')) {
      return empty;
    }
    final String inflightKey = '$method:$key';
    final Future<Object?>? pending = _inflight[inflightKey];
    if (pending != null) return await pending as T;
    final Future<T> future = () async {
      try {
        final T value = await fetch();
        onSuccess(value);
        return value;
      } on GeminiRateLimited catch (e) {
        final Duration clamped = e.retryAfter > const Duration(seconds: 60)
            ? const Duration(seconds: 60)
            : e.retryAfter;
        _rateLimitedUntil = DateTime.now().add(clamped);
        appLogger.w(
          '⏳ $method($key) rate-limited; Gemini cool-down ${clamped.inSeconds}s',
        );
        return empty;
      } catch (e) {
        _failedAt['$method:$key'] = DateTime.now();
        appLogger.w('⚠️ $method($key) failed: $e');
        return empty;
      } finally {
        unawaited(_inflight.remove(inflightKey));
      }
    }();
    _inflight[inflightKey] = future;
    return future;
  }

  @override
  bool get aiEnabled {
    final dynamic ds = _ds;
    return ds is GeminiRecommendationsDataSourceImpl && ds.isConfigured;
  }

  @override
  Future<List<Destination>> destinations(String country) async {
    final String key = country.toLowerCase().trim();
    final List<Destination>? cached = _destinationsByCountry[key];
    if (cached != null) return cached;
    return _guarded<List<Destination>>(
      method: '🌍 destinations',
      key: key,
      empty: const <Destination>[],
      fetch: () => _ds.destinations(country),
      onSuccess: (List<Destination> list) => _destinationsByCountry[key] = list,
    );
  }

  @override
  Future<List<Hotel>> hotels(String country, {String city = ''}) async {
    final String key = '${country.toLowerCase()}|${city.toLowerCase()}';
    final List<Hotel>? cached = _hotelsByKey[key];
    if (cached != null) return cached;
    return _guarded<List<Hotel>>(
      method: '🏨 hotels',
      key: key,
      empty: const <Hotel>[],
      fetch: () => _ds.hotels(country, city: city),
      onSuccess: (List<Hotel> list) => _hotelsByKey[key] = list,
    );
  }

  @override
  Future<List<Job>> jobs({
    required String country,
    required String field,
    required String language,
    required int experienceYears,
  }) async {
    final String key =
        '${country.toLowerCase()}|${field.toLowerCase()}|${language.toLowerCase()}|$experienceYears';
    final List<Job>? cached = _jobsByKey[key];
    if (cached != null) return cached;
    return _guarded<List<Job>>(
      method: '💼 jobs',
      key: key,
      empty: const <Job>[],
      fetch: () => _ds.jobs(
        country: country,
        field: field,
        language: language,
        experienceYears: experienceYears,
      ),
      onSuccess: (List<Job> list) => _jobsByKey[key] = list,
    );
  }

  @override
  Future<List<BusinessOpportunity>> businessOpportunities(
    String country,
  ) async {
    final String key = country.toLowerCase().trim();
    final List<BusinessOpportunity>? cached = _businessByCountry[key];
    if (cached != null) return cached;
    return _guarded<List<BusinessOpportunity>>(
      method: '💼 businessOpportunities',
      key: key,
      empty: const <BusinessOpportunity>[],
      fetch: () => _ds.businessOpportunities(country),
      onSuccess: (List<BusinessOpportunity> list) =>
          _businessByCountry[key] = list,
    );
  }

  @override
  Future<VisaInfo?> visaInfo({
    required String country,
    required String purposeCode,
  }) async {
    if (country.isEmpty) return null;
    final String key = '${country.toLowerCase()}|$purposeCode';
    final VisaInfo? cached = _visaByKey[key];
    if (cached != null) return cached;
    return _guarded<VisaInfo?>(
      method: '📄 visaInfo',
      key: key,
      empty: null,
      fetch: () => _ds.visaInfo(country: country, purposeCode: purposeCode),
      onSuccess: (VisaInfo? info) {
        if (info != null) _visaByKey[key] = info;
      },
    );
  }

  @override
  Future<RoadmapPlan?> roadmap({
    required String country,
    required String purposeCode,
  }) async {
    if (country.isEmpty) return null;
    final String key = '${country.toLowerCase()}|$purposeCode';
    final RoadmapPlan? cached = _roadmapByKey[key];
    if (cached != null) return cached;
    return _guarded<RoadmapPlan?>(
      method: '🗺️ roadmap',
      key: key,
      empty: null,
      fetch: () => _ds.roadmap(country: country, purposeCode: purposeCode),
      onSuccess: (RoadmapPlan? plan) {
        if (plan != null) _roadmapByKey[key] = plan;
      },
    );
  }

  @override
  Future<List<DocumentBrief>> documents({
    required String country,
    required String purposeCode,
    required String originCountry,
  }) async {
    if (country.isEmpty) return const <DocumentBrief>[];
    final String key =
        '${country.toLowerCase()}|$purposeCode|${originCountry.toLowerCase()}';
    final List<DocumentBrief>? cached = _docsByKey[key];
    if (cached != null) return cached;
    return _guarded<List<DocumentBrief>>(
      method: '📑 documents',
      key: key,
      empty: const <DocumentBrief>[],
      fetch: () => _ds.documents(
        country: country,
        purposeCode: purposeCode,
        originCountry: originCountry,
      ),
      onSuccess: (List<DocumentBrief> list) => _docsByKey[key] = list,
    );
  }
}
