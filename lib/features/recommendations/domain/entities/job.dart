import 'package:equatable/equatable.dart';

class Job extends Equatable {
  const Job({
    required this.title,
    required this.company,
    required this.city,
    required this.salaryUsdPerMonthMin,
    required this.salaryUsdPerMonthMax,
    required this.experienceYears,
    required this.languageRequirement,
    required this.visaSponsorship,
    required this.summary,
    required this.searchUrl,
  });

  final String title;
  final String company;
  final String city;
  final int salaryUsdPerMonthMin;
  final int salaryUsdPerMonthMax;

  final int experienceYears;

  final String languageRequirement;
  final bool visaSponsorship;
  final String summary;

  final String searchUrl;

  @override
  List<Object?> get props => <Object?>[
        title,
        company,
        city,
        salaryUsdPerMonthMin,
        salaryUsdPerMonthMax,
        experienceYears,
        languageRequirement,
        visaSponsorship,
        summary,
        searchUrl,
      ];
}

enum LanguageProficiency {
  english('English'),
  local('Local language'),
  both('Both'),
  none('None');

  const LanguageProficiency(this.label);
  final String label;
}
