import '../../../../core/services/backend_api.dart';
import '../../../../core/storage/prefs.dart';
import '../../../profile_setup/data/datasources/countries_db.dart';
import '../../../profile_setup/domain/entities/country.dart';
import '../../../profile_setup/domain/entities/purpose.dart';
import '../../domain/entities/interview_turn.dart';

class VisaInterviewService {
  VisaInterviewService(this._api, this._prefs, this._countries);

  final BackendApi _api;
  final Prefs _prefs;
  final CountriesDb _countries;

  static const int kTargetQuestions = 5;

  bool get isConfigured => _api.isConfigured;

  Future<InterviewExchange> next({
    required List<InterviewTurn> turns,
    String latestAnswer = '',
  }) async {
    final Map<String, dynamic> json = await _api.post(
      '/v1/interview/next',
      <String, dynamic>{
        'turns': <Map<String, String>>[
          for (final InterviewTurn t in turns)
            <String, String>{'question': t.question, 'answer': t.answer},
        ],
        'latest_answer': latestAnswer,
        'country': _destinationLabel(),
        'purpose': _purpose().code,
      },
    );
    return _toEntity(json);
  }

  String _destinationLabel() {
    final String? code = _prefs.getString(Prefs.kDestinationCountry);
    final Country? country = code == null ? null : _countries.byCode(code);
    return country?.name ?? '';
  }

  Purpose _purpose() => Purpose.fromCode(
        _prefs.getString(Prefs.kPurpose) ?? Purpose.study.code,
      );

  InterviewExchange _toEntity(Map<String, dynamic> j) {
    final List<String> tips = ((j['tips'] as List<dynamic>?) ?? <dynamic>[])
        .map((dynamic e) => e?.toString().trim() ?? '')
        .where((String s) => s.isNotEmpty)
        .toList();
    return InterviewExchange(
      feedback: _str(j['feedback']),
      question: _str(j['question']),
      done: j['done'] == true,
      assessment: _str(j['assessment']),
      score: _int(j['score']).clamp(0, 100),
      tips: tips,
    );
  }

  static String _str(Object? v) => v is String ? v.trim() : '';
  static int _int(Object? v) {
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}
