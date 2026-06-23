enum Purpose {
  study('study', 'Study', 'University, language school, exchange'),
  work('work', 'Work', 'Job offer or skilled migration'),
  family('family', 'Family', 'Reunification or marriage'),
  tourism('tourism', 'Tourism', 'Short-term travel'),
  business('business', 'Business', 'Investor or entrepreneur');

  const Purpose(this.code, this.label, this.description);
  final String code;
  final String label;
  final String description;

  static Purpose fromCode(String code) => Purpose.values.firstWhere(
        (Purpose p) => p.code == code,
        orElse: () => Purpose.study,
      );
}
