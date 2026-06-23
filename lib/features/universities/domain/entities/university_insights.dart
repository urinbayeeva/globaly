import 'package:equatable/equatable.dart';

class UniversityInsights extends Equatable {
  const UniversityInsights({
    required this.acceptsInternational,
    required this.minIelts,
    required this.minToefl,
    required this.minSat,
    required this.scholarshipAvailable,
    required this.scholarshipPercent,
    required this.scholarshipName,
    required this.notes,
  });

  final bool acceptsInternational;

  final double minIelts;
  final int minToefl;
  final int minSat;

  final bool scholarshipAvailable;

  final int scholarshipPercent;

  final String scholarshipName;

  final String notes;

  @override
  List<Object?> get props => <Object?>[
        acceptsInternational,
        minIelts,
        minToefl,
        minSat,
        scholarshipAvailable,
        scholarshipPercent,
        scholarshipName,
        notes,
      ];
}
