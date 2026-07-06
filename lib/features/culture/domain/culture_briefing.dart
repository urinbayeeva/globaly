import 'package:equatable/equatable.dart';

enum CultureFactKind {
  greeting,
  tipping,
  punctuality,
  dress,
  other;

  static CultureFactKind fromKey(String? key) {
    switch ((key ?? '').trim().toLowerCase()) {
      case 'greeting':
        return CultureFactKind.greeting;
      case 'tipping':
        return CultureFactKind.tipping;
      case 'punctuality':
        return CultureFactKind.punctuality;
      case 'dress':
        return CultureFactKind.dress;
      default:
        return CultureFactKind.other;
    }
  }
}

class CultureFact extends Equatable {
  const CultureFact({required this.kind, required this.value});

  final CultureFactKind kind;
  final String value;

  @override
  List<Object?> get props => <Object?>[kind, value];
}

class CultureTip extends Equatable {
  const CultureTip({required this.text, required this.isDo});

  final String text;
  final bool isDo;

  @override
  List<Object?> get props => <Object?>[text, isDo];
}

class CultureSection extends Equatable {
  const CultureSection({required this.title, required this.tips});

  final String title;
  final List<CultureTip> tips;

  @override
  List<Object?> get props => <Object?>[title, tips];
}

class CultureScenario extends Equatable {
  const CultureScenario({
    required this.situation,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final String situation;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  bool isCorrect(int option) => option == correctIndex;

  @override
  List<Object?> get props =>
      <Object?>[situation, options, correctIndex, explanation];
}

class CultureBriefing extends Equatable {
  const CultureBriefing({
    required this.country,
    required this.flag,
    required this.headline,
    required this.facts,
    required this.sections,
    required this.scenarios,
  });

  final String country;
  final String flag;
  final String headline;
  final List<CultureFact> facts;
  final List<CultureSection> sections;
  final List<CultureScenario> scenarios;

  bool get isEmpty => sections.isEmpty && facts.isEmpty;

  @override
  List<Object?> get props =>
      <Object?>[country, flag, headline, facts, sections, scenarios];
}
