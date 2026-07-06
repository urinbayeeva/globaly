import '../../../../core/services/backend_api.dart';
import '../../domain/entities/business_opportunity.dart';
import '../../domain/entities/destination.dart';
import '../../domain/entities/document_brief.dart';
import '../../domain/entities/hotel.dart';
import '../../domain/entities/job.dart';
import '../../domain/entities/roadmap_plan.dart';
import '../../domain/entities/visa_info.dart';

abstract class GeminiRecommendationsDataSource {
  Future<List<Destination>> destinations(String country);
  Future<List<Hotel>> hotels(String country, {String city = ''});
  Future<List<Job>> jobs({
    required String country,
    required String field,
    required String language,
    required int experienceYears,
  });
  Future<List<BusinessOpportunity>> businessOpportunities(String country);
  Future<VisaInfo> visaInfo({
    required String country,
    required String purposeCode,
  });
  Future<RoadmapPlan> roadmap({
    required String country,
    required String purposeCode,
  });
  Future<List<DocumentBrief>> documents({
    required String country,
    required String purposeCode,
    required String originCountry,
  });
}

class GeminiRecommendationsDataSourceImpl
    implements GeminiRecommendationsDataSource {
  GeminiRecommendationsDataSourceImpl(this._api);
  final BackendApi _api;

  bool get isConfigured => _api.isConfigured;

  List<Map<String, dynamic>> _items(Map<String, dynamic> j) =>
      ((j['items'] as List<dynamic>?) ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList();

  @override
  Future<List<Destination>> destinations(String country) async {
    final Map<String, dynamic> j = await _api.post(
      '/v1/recommendations/destinations',
      <String, dynamic>{'country': country},
    );
    return _items(j).map(_toDestination).toList();
  }

  Destination _toDestination(Map<String, dynamic> j) => Destination(
        name: _str(j['name']),
        region: _str(j['region']),
        summary: _str(j['summary']),
        bestSeason: _str(j['bestSeason']),
      );

  @override
  Future<List<Hotel>> hotels(String country, {String city = ''}) async {
    final Map<String, dynamic> j = await _api.post(
      '/v1/recommendations/hotels',
      <String, dynamic>{'country': country, 'city': city},
    );
    return _items(j).map(_toHotel).toList();
  }

  Hotel _toHotel(Map<String, dynamic> j) => Hotel(
        name: _str(j['name']),
        city: _str(j['city']),
        priceUsdPerNight: _int(j['priceUsdPerNight']),
        stars: _int(j['stars']).clamp(0, 5),
        rating: _dbl(j['rating']).clamp(0, 10).toDouble(),
        summary: _str(j['summary']),
        bookingHint: _str(j['bookingHint']),
        photoQuery: _str(j['photoQuery']),
      );

  @override
  Future<List<Job>> jobs({
    required String country,
    required String field,
    required String language,
    required int experienceYears,
  }) async {
    final Map<String, dynamic> j = await _api.post(
      '/v1/recommendations/jobs',
      <String, dynamic>{
        'country': country,
        'field': field,
        'language': language,
        'experience_years': experienceYears,
      },
    );
    return _items(j).map(_toJob).toList();
  }

  Job _toJob(Map<String, dynamic> j) => Job(
        title: _str(j['title']),
        company: _str(j['company']),
        city: _str(j['city']),
        salaryUsdPerMonthMin: _int(j['salaryUsdPerMonthMin']),
        salaryUsdPerMonthMax: _int(j['salaryUsdPerMonthMax']),
        experienceYears: _int(j['experienceYears']),
        languageRequirement: _str(j['languageRequirement']),
        visaSponsorship: j['visaSponsorship'] == true,
        summary: _str(j['summary']),
        searchUrl: _str(j['searchUrl']),
      );

  @override
  Future<List<BusinessOpportunity>> businessOpportunities(
    String country,
  ) async {
    final Map<String, dynamic> j = await _api.post(
      '/v1/recommendations/business',
      <String, dynamic>{'country': country},
    );
    return _items(j)
        .map(_toBusiness)
        .where((BusinessOpportunity b) => b.lat != 0 || b.lng != 0)
        .toList();
  }

  BusinessOpportunity _toBusiness(Map<String, dynamic> j) {
    final List<dynamic> rawIdeas =
        (j['ideas'] as List<dynamic>?) ?? <dynamic>[];
    final List<String> ideas = rawIdeas
        .map((dynamic e) => e?.toString().trim() ?? '')
        .where((String s) => s.isNotEmpty)
        .toList();
    return BusinessOpportunity(
      city: _str(j['city']),
      region: _str(j['region']),
      lat: _dbl(j['lat']),
      lng: _dbl(j['lng']),
      summary: _str(j['summary']),
      ideas: ideas,
      demandLevel: _str(j['demandLevel']).toLowerCase(),
    );
  }

  @override
  Future<VisaInfo> visaInfo({
    required String country,
    required String purposeCode,
  }) async {
    final Map<String, dynamic> j = await _api.post(
      '/v1/recommendations/visa-info',
      <String, dynamic>{'country': country, 'purpose': purposeCode},
    );
    return VisaInfo(
      visaTypeName: _str(j['visaTypeName']),
      visaTypeCode: _str(j['visaTypeCode']),
      processingWeeks: _int(j['processingWeeks']),
      applicationFeeUsd: _int(j['applicationFeeUsd']),
      totalCostUsd: _int(j['totalCostUsd']),
      notes: _str(j['notes']),
    );
  }

  @override
  Future<RoadmapPlan> roadmap({
    required String country,
    required String purposeCode,
  }) async {
    final Map<String, dynamic> j = await _api.post(
      '/v1/recommendations/roadmap',
      <String, dynamic>{'country': country, 'purpose': purposeCode},
    );
    final List<RoadmapPlanStep> steps = ((j['steps'] as List<dynamic>?) ??
            <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(
          (Map<String, dynamic> s) => RoadmapPlanStep(
            id: _str(s['id']),
            title: _str(s['title']),
            description: _str(s['description']),
            weeks: _int(s['weeks']),
          ),
        )
        .toList();
    return RoadmapPlan(headline: _str(j['headline']), steps: steps);
  }

  @override
  Future<List<DocumentBrief>> documents({
    required String country,
    required String purposeCode,
    required String originCountry,
  }) async {
    final Map<String, dynamic> j = await _api.post(
      '/v1/recommendations/documents',
      <String, dynamic>{
        'country': country,
        'purpose': purposeCode,
        'origin_country': originCountry,
      },
    );
    return _items(j)
        .map(_toDocumentBrief)
        .where((DocumentBrief d) => d.title.isNotEmpty)
        .toList();
  }

  DocumentBrief _toDocumentBrief(Map<String, dynamic> j) {
    final List<dynamic> rawNotes =
        (j['notes'] as List<dynamic>?) ?? <dynamic>[];
    final List<String> notes = rawNotes
        .map((dynamic e) => e?.toString().trim() ?? '')
        .where((String s) => s.isNotEmpty)
        .toList();
    return DocumentBrief(
      id: _str(j['id']),
      title: _str(j['title']),
      issuer: _str(j['issuer']),
      statusCode: _str(j['statusCode']).toLowerCase(),
      iconHint: _str(j['iconHint']).toLowerCase(),
      description: _str(j['description']),
      validityYears: _int(j['validityYears']),
      costUsd: _int(j['costUsd']),
      notes: notes,
    );
  }

  static String _str(Object? v) => v is String ? v.trim() : '';
  static int _int(Object? v) =>
      v is int ? v : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);
  static double _dbl(Object? v) =>
      v is double ? v : (v is num ? v.toDouble() : double.tryParse('$v') ?? 0);
}
