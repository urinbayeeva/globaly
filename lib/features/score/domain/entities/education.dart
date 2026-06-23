enum EducationLevel {
  highSchool('high_school', 'High school'),
  bachelor('bachelor', 'Bachelor'),
  master('master', 'Master'),
  phd('phd', 'PhD');

  const EducationLevel(this.code, this.label);
  final String code;
  final String label;

  bool get expectsSat => this == EducationLevel.highSchool;

  static EducationLevel fromCode(String? c) => EducationLevel.values.firstWhere(
        (EducationLevel e) => e.code == c,
        orElse: () => EducationLevel.bachelor,
      );
}
