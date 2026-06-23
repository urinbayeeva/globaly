import '../entities/business_opportunity.dart';
import '../entities/destination.dart';
import '../entities/document_brief.dart';
import '../entities/hotel.dart';
import '../entities/job.dart';
import '../entities/roadmap_plan.dart';
import '../entities/visa_info.dart';

abstract class RecommendationsRepository {
  bool get aiEnabled;

  Future<List<Destination>> destinations(String country);

  Future<List<Hotel>> hotels(String country, {String city = ''});

  Future<List<Job>> jobs({
    required String country,
    required String field,
    required String language,
    required int experienceYears,
  });

  Future<List<BusinessOpportunity>> businessOpportunities(String country);

  Future<VisaInfo?> visaInfo({
    required String country,
    required String purposeCode,
  });

  Future<RoadmapPlan?> roadmap({
    required String country,
    required String purposeCode,
  });

  Future<List<DocumentBrief>> documents({
    required String country,
    required String purposeCode,
    required String originCountry,
  });
}
