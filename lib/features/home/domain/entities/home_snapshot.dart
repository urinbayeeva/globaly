import 'package:equatable/equatable.dart';

class HomeSnapshot extends Equatable {
  const HomeSnapshot({
    required this.greeting,
    required this.userName,
    required this.destinationLabel,
    required this.destinationFlag,
    required this.destinationCountryName,
    required this.destinationSelected,
    required this.purposeCode,
    required this.scoreValue,
    required this.hasLanguageScore,
    required this.languageScoreIsSat,
    required this.nbaStepLabel,
    required this.nbaTitle,
    required this.nbaTimeEstimate,
  });

  final String greeting;
  final String userName;
  final String destinationLabel;
  final String destinationFlag;
  final String destinationCountryName;
  final bool destinationSelected;
  final String purposeCode;
  final double scoreValue;
  final bool hasLanguageScore;
  final bool languageScoreIsSat;
  final String nbaStepLabel;
  final String nbaTitle;
  final String nbaTimeEstimate;

  @override
  List<Object?> get props => <Object?>[
        greeting,
        userName,
        destinationLabel,
        destinationFlag,
        destinationCountryName,
        destinationSelected,
        purposeCode,
        scoreValue,
        hasLanguageScore,
        languageScoreIsSat,
        nbaStepLabel,
        nbaTitle,
        nbaTimeEstimate,
      ];
}
