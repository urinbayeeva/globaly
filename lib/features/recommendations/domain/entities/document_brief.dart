import 'package:equatable/equatable.dart';

class DocumentBrief extends Equatable {
  const DocumentBrief({
    required this.id,
    required this.title,
    required this.issuer,
    required this.statusCode,
    required this.iconHint,
    required this.description,
    required this.validityYears,
    required this.costUsd,
    required this.notes,
  });

  final String id;
  final String title;

  final String issuer;

  final String statusCode;

  final String iconHint;

  final String description;

  final int validityYears;

  final int costUsd;

  final List<String> notes;

  @override
  List<Object?> get props => <Object?>[
        id,
        title,
        issuer,
        statusCode,
        iconHint,
        description,
        validityYears,
        costUsd,
        notes,
      ];
}
