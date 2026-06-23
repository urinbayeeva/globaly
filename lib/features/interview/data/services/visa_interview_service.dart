import '../../../../core/services/gemini_client.dart';
import '../../../../core/storage/prefs.dart';
import '../../../profile_setup/data/datasources/countries_db.dart';
import '../../../profile_setup/domain/entities/country.dart';
import '../../../profile_setup/domain/entities/purpose.dart';
import '../../domain/entities/interview_turn.dart';

class VisaInterviewService {
  VisaInterviewService(this._client, this._prefs, this._countries);

  final GeminiClient _client;
  final Prefs _prefs;
  final CountriesDb _countries;

  static const int kTargetQuestions = 5;

  bool get isConfigured => _client.isConfigured;

  Future<InterviewExchange> next({
    required List<InterviewTurn> turns,
    String latestAnswer = '',
  }) async {
    final Map<String, dynamic> json = await _client.generateJson(
      prompt: _buildPrompt(turns, latestAnswer),
      schema: _schema,
      temperature: 0.6,
    );
    return _toEntity(json);
  }

  String _destinationLabel() {
    final String? code = _prefs.getString(Prefs.kDestinationCountry);
    final Country? country = code == null ? null : _countries.byCode(code);
    return country?.name ?? 'your destination country';
  }

  Purpose _purpose() => Purpose.fromCode(
        _prefs.getString(Prefs.kPurpose) ?? Purpose.study.code,
      );

  String _buildPrompt(List<InterviewTurn> turns, String latestAnswer) {
    final String country = _destinationLabel();
    final Purpose purpose = _purpose();
    final int asked = turns.length;

    final StringBuffer transcript = StringBuffer();
    for (int i = 0; i < turns.length; i++) {
      transcript.writeln('Officer Q${i + 1}: ${turns[i].question}');
      final String a = turns[i].answer.trim().isEmpty
          ? '(not answered yet)'
          : turns[i].answer;
      transcript.writeln('Applicant A${i + 1}: $a');
    }
    if (latestAnswer.trim().isNotEmpty && turns.isNotEmpty) {
      transcript
        ..writeln('Latest applicant answer to Q$asked:')
        ..writeln(latestAnswer.trim());
    }

    return '''
You are a realistic but encouraging visa officer conducting a mock
${purpose.label.toLowerCase()} visa interview for an applicant who wants to go
to $country. Your goal is to help them practise and improve.

Rules:
- Ask common, realistic interview questions ONE at a time. Keep each question
  to 1–2 short sentences. Tailor them to a ${purpose.label.toLowerCase()} visa.
- Aim for about $kTargetQuestions questions total. You have asked $asked so far.
- After each applicant answer, put one short, constructive sentence in
  "feedback" (what was good and one thing to improve). For the very first
  question, leave "feedback" empty.
- While the interview continues: set "done" to false, put the next question in
  "question", and leave "assessment" empty and "score" 0.
- Once you have asked about $kTargetQuestions questions AND received answers,
  finish: set "done" to true, leave "question" empty, write a 2–3 sentence
  overall "assessment", give an integer "score" 0–100 for interview
  readiness, and up to 3 short "tips" for improvement.
- Be specific and practical. Never invent the applicant's personal facts.

Conversation so far:
${transcript.isEmpty ? '(none yet — ask the first question)' : transcript.toString().trim()}

Return only the next exchange as JSON.
''';
  }

  static const Map<String, dynamic> _schema = <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'feedback': <String, dynamic>{'type': 'string'},
      'question': <String, dynamic>{'type': 'string'},
      'done': <String, dynamic>{'type': 'boolean'},
      'assessment': <String, dynamic>{'type': 'string'},
      'score': <String, dynamic>{'type': 'integer'},
      'tips': <String, dynamic>{
        'type': 'array',
        'items': <String, dynamic>{'type': 'string'},
      },
    },
    'required': <String>[
      'feedback',
      'question',
      'done',
      'assessment',
      'score',
      'tips',
    ],
  };

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
