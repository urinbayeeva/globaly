import '../../../../core/services/backend_api.dart';
import '../../domain/entities/university.dart';
import '../../domain/entities/university_insights.dart';

export '../../../../core/services/backend_api.dart'
    show MissingBackendUrl, AiRateLimited;

abstract class GeminiInsightsDataSource {
  Future<UniversityInsights> fetchInsights(University u);
}

class GeminiInsightsDataSourceImpl implements GeminiInsightsDataSource {
  GeminiInsightsDataSourceImpl(this._api);
  final BackendApi _api;

  bool get isConfigured => _api.isConfigured;

  @override
  Future<UniversityInsights> fetchInsights(University u) async {
    final String location = u.stateProvince.isEmpty
        ? u.country
        : '${u.stateProvince}, ${u.country}';
    final Map<String, dynamic> j =
        await _api.post('/v1/universities/insights', <String, dynamic>{
      'name': u.name,
      'location': location,
      'website': u.websiteUrl,
    });
    return _toEntity(j);
  }

  UniversityInsights _toEntity(Map<String, dynamic> j) {
    double dbl(Object? v) => v is num ? v.toDouble() : 0.0;
    int integer(Object? v) => v is num ? v.toInt() : 0;
    return UniversityInsights(
      acceptsInternational: j['acceptsInternational'] == true,
      minIelts: dbl(j['minIelts']),
      minToefl: integer(j['minToefl']),
      minSat: integer(j['minSat']),
      scholarshipAvailable: j['scholarshipAvailable'] == true,
      scholarshipPercent: integer(j['scholarshipPercent']).clamp(0, 100),
      scholarshipName: (j['scholarshipName'] as String?)?.trim() ?? '',
      notes: (j['notes'] as String?)?.trim() ?? '',
    );
  }
}
