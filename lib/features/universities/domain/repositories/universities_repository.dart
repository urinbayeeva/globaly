import '../entities/university.dart';
import '../entities/university_insights.dart';

abstract class UniversitiesRepository {
  Future<List<University>> byCountry(String countryName);

  Future<University?> byId(String id);

  Future<UniversityInsights?> insights(String id);

  bool get aiEnabled;
}
