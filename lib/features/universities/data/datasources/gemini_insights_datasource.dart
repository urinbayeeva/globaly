import '../../../../core/services/gemini_client.dart';
import '../../domain/entities/university.dart';
import '../../domain/entities/university_insights.dart';

export '../../../../core/services/gemini_client.dart'
    show MissingGeminiKey, GeminiRateLimited;

abstract class GeminiInsightsDataSource {
  Future<UniversityInsights> fetchInsights(University u);
}

class GeminiInsightsDataSourceImpl implements GeminiInsightsDataSource {
  GeminiInsightsDataSourceImpl(this._client);
  final GeminiClient _client;

  bool get isConfigured => _client.isConfigured;

  @override
  Future<UniversityInsights> fetchInsights(University u) async {
    final Map<String, dynamic> j = await _client.generateJson(
      prompt: _prompt(u),
      schema: _schema,
    );
    return _toEntity(j);
  }

  String _prompt(University u) {
    final String location = u.stateProvince.isEmpty
        ? u.country
        : '${u.stateProvince}, ${u.country}';
    return '''
You are an admissions data assistant. For the university below, return a
JSON object with realistic, **conservative** estimates of its
international-undergraduate admission profile. Use widely reported public
data; if a value is genuinely unknown, use 0 (numbers) or false (bool).
Do NOT invent precise figures — round to typical thresholds.

University: ${u.name}
Location: $location
Website: ${u.websiteUrl}

Fields:
- acceptsInternational (bool): does it admit non-citizen / non-resident students?
- minIelts (number, 0–9): typical minimum IELTS overall band for undergrad
- minToefl (int, 0–120): typical minimum TOEFL iBT total
- minSat (int, 0–1600): typical SAT total (0 if not required, e.g. UK/EU schools)
- scholarshipAvailable (bool): are merit/need scholarships offered to international students?
- scholarshipPercent (int, 0–100): coverage of the most accessible scholarship; 0 if N/A
- scholarshipName (string): concrete scholarship title (e.g. "President's International Award"); empty string if none
- notes (string, 1–2 sentences): who qualifies for the scholarship and any caveats
''';
  }

  static const Map<String, dynamic> _schema = <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'acceptsInternational': <String, dynamic>{'type': 'boolean'},
      'minIelts': <String, dynamic>{'type': 'number'},
      'minToefl': <String, dynamic>{'type': 'integer'},
      'minSat': <String, dynamic>{'type': 'integer'},
      'scholarshipAvailable': <String, dynamic>{'type': 'boolean'},
      'scholarshipPercent': <String, dynamic>{'type': 'integer'},
      'scholarshipName': <String, dynamic>{'type': 'string'},
      'notes': <String, dynamic>{'type': 'string'},
    },
    'required': <String>[
      'acceptsInternational',
      'minIelts',
      'minToefl',
      'minSat',
      'scholarshipAvailable',
      'scholarshipPercent',
      'scholarshipName',
      'notes',
    ],
  };

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
