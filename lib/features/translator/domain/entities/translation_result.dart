import 'package:equatable/equatable.dart';

class TranslationResult extends Equatable {
  const TranslationResult({
    required this.detectedLanguage,
    required this.documentType,
    required this.translation,
    required this.summary,
    this.nextSteps = const <String>[],
  });

  final String detectedLanguage;
  final String documentType;
  final String translation;
  final String summary;
  final List<String> nextSteps;

  bool get isUnreadable => translation.trim().isEmpty;

  @override
  List<Object?> get props => <Object?>[
        detectedLanguage,
        documentType,
        translation,
        summary,
        nextSteps,
      ];
}
