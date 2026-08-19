import '../../../../core/services/backend_api.dart';
import '../../domain/culture_briefing.dart';

abstract class CultureDataSource {
  bool get isConfigured;

  Future<CultureBriefing> briefing({
    required String country,
    required String flag,
  });
}

class GeminiCultureDataSource implements CultureDataSource {
  GeminiCultureDataSource(this._api);

  final BackendApi _api;

  @override
  bool get isConfigured => _api.isConfigured;

  @override
  Future<CultureBriefing> briefing({
    required String country,
    required String flag,
  }) async {
    final Map<String, dynamic> json = await _api.post(
      '/v1/culture',
      <String, dynamic>{'country': country},
    );
    return _toBriefing(json, country, flag);
  }

  CultureBriefing _toBriefing(
    Map<String, dynamic> j,
    String country,
    String flag,
  ) {
    final List<CultureFact> facts = _list(j['facts'])
        .map(
          (Map<String, dynamic> f) => CultureFact(
            kind: CultureFactKind.fromKey(_str(f['kind'])),
            value: _str(f['value']),
          ),
        )
        .where((CultureFact f) => f.value.isNotEmpty)
        .toList();

    final List<CultureSection> sections = _list(j['sections'])
        .map(
          (Map<String, dynamic> s) => CultureSection(
            title: _str(s['title']),
            tips: _list(s['tips'])
                .map(
                  (Map<String, dynamic> t) => CultureTip(
                    text: _str(t['text']),
                    isDo: t['isDo'] == true,
                  ),
                )
                .where((CultureTip t) => t.text.isNotEmpty)
                .toList(),
          ),
        )
        .where(
          (CultureSection s) => s.title.isNotEmpty && s.tips.isNotEmpty,
        )
        .toList();

    final List<CultureScenario> scenarios = _list(j['scenarios'])
        .map((Map<String, dynamic> s) {
          final List<String> options =
              ((s['options'] as List<dynamic>?) ?? <dynamic>[])
                  .map((dynamic e) => _str(e))
                  .where((String o) => o.isNotEmpty)
                  .toList();
          return CultureScenario(
            situation: _str(s['situation']),
            options: options,
            correctIndex: _int(s['correctIndex']).clamp(
              0,
              options.isEmpty ? 0 : options.length - 1,
            ),
            explanation: _str(s['explanation']),
          );
        })
        .where(
          (CultureScenario s) =>
              s.situation.isNotEmpty && s.options.length >= 2,
        )
        .toList();

    return CultureBriefing(
      country: country,
      flag: flag,
      headline: _str(j['headline']),
      facts: facts,
      sections: sections,
      scenarios: scenarios,
    );
  }

  static List<Map<String, dynamic>> _list(Object? v) =>
      ((v as List<dynamic>?) ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList();

  static String _str(Object? v) => v is String ? v.trim() : '';
  static int _int(Object? v) =>
      v is int ? v : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);
}
