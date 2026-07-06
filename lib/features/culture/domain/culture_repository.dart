import 'culture_briefing.dart';

abstract class CultureRepository {
  bool get isConfigured;

  Future<CultureBriefing> forCountry({
    required String country,
    required String flag,
  });
}
