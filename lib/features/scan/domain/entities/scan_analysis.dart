import 'package:equatable/equatable.dart';

enum DocumentType {
  contract('contract', 'contract'),
  passport('passport', 'passport'),
  diploma('diploma', 'diploma'),
  idCard('id_card', 'ID card'),
  transcript('transcript', 'transcript'),
  certificate('certificate', 'certificate'),
  unknown('unknown', 'document');

  const DocumentType(this.code, this.label);
  final String code;
  final String label;
}

enum RiskSeverity { notice, warning, dangerous }

class DetectedRisk extends Equatable {
  const DetectedRisk({
    required this.title,
    required this.severity,
    required this.quote,
    required this.explanation,
  });
  final String title;
  final RiskSeverity severity;
  final String quote;
  final String explanation;

  @override
  List<Object?> get props => <Object?>[title, severity, quote, explanation];
}

class ScanAnalysis extends Equatable {
  const ScanAnalysis({
    required this.rawText,
    required this.type,
    required this.summary,
    required this.risks,
    this.safePoints = const <String>[],
  });

  final String rawText;
  final DocumentType type;
  final String summary;
  final List<DetectedRisk> risks;

  final List<String> safePoints;

  bool get isContract => type == DocumentType.contract;

  @override
  List<Object?> get props =>
      <Object?>[rawText, type, summary, risks, safePoints];
}
