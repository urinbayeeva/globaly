import '../../../../core/services/gemini_client.dart';
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
  GeminiRecommendationsDataSourceImpl(this._client);
  final GeminiClient _client;

  bool get isConfigured => _client.isConfigured;

  @override
  Future<List<Destination>> destinations(String country) async {
    final Map<String, dynamic> j = await _client.generateJson(
      prompt: _destinationsPrompt(country),
      schema: _destinationsSchema,
    );
    final List<dynamic> items = (j['items'] as List<dynamic>?) ?? <dynamic>[];
    return items.whereType<Map<String, dynamic>>().map(_toDestination).toList();
  }

  String _destinationsPrompt(String country) => '''
List the 6 most popular travel destinations in $country for an international
visitor. Mix iconic cities, scenic regions, and at least one off-the-beaten-path
spot. Be concrete (specific city / region names — not "the south coast").

Return an "items" array. For each destination:
- name (string): the place
- region (string): broader area (e.g. "Bavaria", "Catalonia"); empty if not relevant
- summary (string, 1 sentence): why a foreigner would visit
- bestSeason (string): season window like "May–September"; empty if year-round
''';

  static const Map<String, dynamic> _destinationsSchema = <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'items': <String, dynamic>{
        'type': 'array',
        'items': <String, dynamic>{
          'type': 'object',
          'properties': <String, dynamic>{
            'name': <String, dynamic>{'type': 'string'},
            'region': <String, dynamic>{'type': 'string'},
            'summary': <String, dynamic>{'type': 'string'},
            'bestSeason': <String, dynamic>{'type': 'string'},
          },
          'required': <String>['name', 'region', 'summary', 'bestSeason'],
        },
      },
    },
    'required': <String>['items'],
  };

  Destination _toDestination(Map<String, dynamic> j) => Destination(
        name: _str(j['name']),
        region: _str(j['region']),
        summary: _str(j['summary']),
        bestSeason: _str(j['bestSeason']),
      );

  @override
  Future<List<Hotel>> hotels(String country, {String city = ''}) async {
    final Map<String, dynamic> j = await _client.generateJson(
      prompt: _hotelsPrompt(country, city),
      schema: _hotelsSchema,
    );
    final List<dynamic> items = (j['items'] as List<dynamic>?) ?? <dynamic>[];
    return items.whereType<Map<String, dynamic>>().map(_toHotel).toList();
  }

  String _hotelsPrompt(String country, String city) {
    final String scope = city.isEmpty ? country : '$city, $country';
    return '''
Suggest 6 real, well-reviewed hotels in $scope for international travellers,
mixing budget (\$, 2–3 stars), mid-range (\$\$, 3–4 stars), and premium
(\$\$\$, 4–5 stars). Use real hotel names that travellers would find on major
booking sites. Conservative numeric estimates only.

Return an "items" array. For each hotel:
- name (string): real hotel name
- city (string): city it's located in
- priceUsdPerNight (int): typical USD/night for a standard double
- stars (int, 1–5): rating
- rating (number, 0–10): typical guest rating (e.g. 8.6)
- summary (string, 1 sentence): why it's a good fit (location / amenities / value)
- bookingHint (string): a comma-separated list of booking platforms (e.g. "Booking.com, Hotels.com, Expedia")
- photoQuery (string): 2–4 word search query that finds a representative photo on Unsplash, e.g. "burj khalifa dubai" or "ritz paris facade"
''';
  }

  static const Map<String, dynamic> _hotelsSchema = <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'items': <String, dynamic>{
        'type': 'array',
        'items': <String, dynamic>{
          'type': 'object',
          'properties': <String, dynamic>{
            'name': <String, dynamic>{'type': 'string'},
            'city': <String, dynamic>{'type': 'string'},
            'priceUsdPerNight': <String, dynamic>{'type': 'integer'},
            'stars': <String, dynamic>{'type': 'integer'},
            'rating': <String, dynamic>{'type': 'number'},
            'summary': <String, dynamic>{'type': 'string'},
            'bookingHint': <String, dynamic>{'type': 'string'},
            'photoQuery': <String, dynamic>{'type': 'string'},
          },
          'required': <String>[
            'name',
            'city',
            'priceUsdPerNight',
            'stars',
            'rating',
            'summary',
            'bookingHint',
            'photoQuery',
          ],
        },
      },
    },
    'required': <String>['items'],
  };

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
    final Map<String, dynamic> j = await _client.generateJson(
      prompt: _jobsPrompt(country, field, language, experienceYears),
      schema: _jobsSchema,
    );
    final List<dynamic> items = (j['items'] as List<dynamic>?) ?? <dynamic>[];
    return items.whereType<Map<String, dynamic>>().map(_toJob).toList();
  }

  String _jobsPrompt(
    String country,
    String field,
    String language,
    int experienceYears,
  ) =>
      '''
Suggest 6 realistic job opportunities for a foreigner relocating to $country.
Filter strictly by:
- Field: $field
- Spoken language: $language
- Years of experience: $experienceYears

Mix entry-level and senior roles within the filter. Prefer real companies that
historically sponsor visas in $country. For salaries use conservative USD/month
ranges typical of the country and role.

Return an "items" array. For each job:
- title (string): role title
- company (string): real or representative company
- city (string): main location
- salaryUsdPerMonthMin (int)
- salaryUsdPerMonthMax (int)
- experienceYears (int): typical minimum years required
- languageRequirement (string): "English", "Local language", "Both", or "None"
- visaSponsorship (bool): does the role typically sponsor work visas?
- summary (string, 1 sentence): what makes the role a fit
- searchUrl (string): a real job-board search URL that surfaces similar listings
  (e.g. https://www.linkedin.com/jobs/search/?keywords=ROLE&location=$country)
''';

  static const Map<String, dynamic> _jobsSchema = <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'items': <String, dynamic>{
        'type': 'array',
        'items': <String, dynamic>{
          'type': 'object',
          'properties': <String, dynamic>{
            'title': <String, dynamic>{'type': 'string'},
            'company': <String, dynamic>{'type': 'string'},
            'city': <String, dynamic>{'type': 'string'},
            'salaryUsdPerMonthMin': <String, dynamic>{'type': 'integer'},
            'salaryUsdPerMonthMax': <String, dynamic>{'type': 'integer'},
            'experienceYears': <String, dynamic>{'type': 'integer'},
            'languageRequirement': <String, dynamic>{'type': 'string'},
            'visaSponsorship': <String, dynamic>{'type': 'boolean'},
            'summary': <String, dynamic>{'type': 'string'},
            'searchUrl': <String, dynamic>{'type': 'string'},
          },
          'required': <String>[
            'title',
            'company',
            'city',
            'salaryUsdPerMonthMin',
            'salaryUsdPerMonthMax',
            'experienceYears',
            'languageRequirement',
            'visaSponsorship',
            'summary',
            'searchUrl',
          ],
        },
      },
    },
    'required': <String>['items'],
  };

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
    final Map<String, dynamic> j = await _client.generateJson(
      prompt: _businessPrompt(country),
      schema: _businessSchema,
    );
    final List<dynamic> items = (j['items'] as List<dynamic>?) ?? <dynamic>[];
    return items
        .whereType<Map<String, dynamic>>()
        .map(_toBusiness)
        .where((BusinessOpportunity b) => b.lat != 0 || b.lng != 0)
        .toList();
  }

  String _businessPrompt(String country) => '''
List 6 cities or districts in $country where a foreign entrepreneur could start
a venture. Spread them across the country (mix capital + regional hubs).

For each city return:
- city (string): city or district name
- region (string): broader administrative region; empty if unknown
- lat (number): WGS84 latitude
- lng (number): WGS84 longitude
- summary (string, 1 sentence): why this city is good for business
- ideas (array of strings, 3–5 items): concrete venture ideas suited to the city
  (e.g. "Co-working space for remote workers", "Halal export-oriented food brand")
- demandLevel (string): one of "low" | "medium" | "high"

Only include cities you can locate with reasonable accuracy. Do NOT invent
coordinates — return 0 for both lat and lng if unsure.
''';

  static const Map<String, dynamic> _businessSchema = <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'items': <String, dynamic>{
        'type': 'array',
        'items': <String, dynamic>{
          'type': 'object',
          'properties': <String, dynamic>{
            'city': <String, dynamic>{'type': 'string'},
            'region': <String, dynamic>{'type': 'string'},
            'lat': <String, dynamic>{'type': 'number'},
            'lng': <String, dynamic>{'type': 'number'},
            'summary': <String, dynamic>{'type': 'string'},
            'ideas': <String, dynamic>{
              'type': 'array',
              'items': <String, dynamic>{'type': 'string'},
            },
            'demandLevel': <String, dynamic>{'type': 'string'},
          },
          'required': <String>[
            'city',
            'region',
            'lat',
            'lng',
            'summary',
            'ideas',
            'demandLevel',
          ],
        },
      },
    },
    'required': <String>['items'],
  };

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
    final Map<String, dynamic> j = await _client.generateJson(
      prompt: _visaPrompt(country, purposeCode),
      schema: _visaSchema,
    );
    return _toVisaInfo(j);
  }

  String _visaPrompt(String country, String purposeCode) => '''
You are an immigration data assistant. For someone entering $country with
purpose "$purposeCode" (one of: study | work | family | tourism | business),
return the typical visa pathway as JSON. Use widely reported public figures;
if a value is unknown use 0 (numbers) or empty string (strings).

Fields:
- visaTypeName (string): human-readable name, e.g. "Student Visa (Type D)" / "Skilled Worker Visa"
- visaTypeCode (string): official short code, e.g. "F-1", "Tier 4", "Type D"; empty if none
- processingWeeks (int): typical processing time end-to-end
- applicationFeeUsd (int): government application fee in USD
- totalCostUsd (int): full end-to-end cost (fees + translations + insurance + medical + courier)
- notes (string, 1 short sentence): what's included or any caveat
''';

  static const Map<String, dynamic> _visaSchema = <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'visaTypeName': <String, dynamic>{'type': 'string'},
      'visaTypeCode': <String, dynamic>{'type': 'string'},
      'processingWeeks': <String, dynamic>{'type': 'integer'},
      'applicationFeeUsd': <String, dynamic>{'type': 'integer'},
      'totalCostUsd': <String, dynamic>{'type': 'integer'},
      'notes': <String, dynamic>{'type': 'string'},
    },
    'required': <String>[
      'visaTypeName',
      'visaTypeCode',
      'processingWeeks',
      'applicationFeeUsd',
      'totalCostUsd',
      'notes',
    ],
  };

  VisaInfo _toVisaInfo(Map<String, dynamic> j) => VisaInfo(
        visaTypeName: _str(j['visaTypeName']),
        visaTypeCode: _str(j['visaTypeCode']),
        processingWeeks: _int(j['processingWeeks']),
        applicationFeeUsd: _int(j['applicationFeeUsd']),
        totalCostUsd: _int(j['totalCostUsd']),
        notes: _str(j['notes']),
      );

  @override
  Future<RoadmapPlan> roadmap({
    required String country,
    required String purposeCode,
  }) async {
    final Map<String, dynamic> j = await _client.generateJson(
      prompt: _roadmapPrompt(country, purposeCode),
      schema: _roadmapSchema,
    );
    final List<dynamic> items = (j['steps'] as List<dynamic>?) ?? <dynamic>[];
    final List<RoadmapPlanStep> steps =
        items.whereType<Map<String, dynamic>>().map(_toRoadmapStep).toList();
    return RoadmapPlan(
      headline: _str(j['headline']),
      steps: steps,
    );
  }

  String _roadmapPrompt(String country, String purposeCode) => '''
You are a migration planner. For someone moving to $country with purpose
"$purposeCode" (one of: study | work | family | tourism | business), build a
realistic step-by-step roadmap.

Constraints:
- Return 8–10 steps in chronological order (earliest first).
- Include country-specific procedures (e.g. "Anmeldung" in Germany,
  "SSN application" in the US, "PR check-in" in Canada).
- Steps must be actionable, not generic ("Apply for X visa", not "Prepare visa").
- Each step gets a short id (lower_snake_case), title, 1-sentence description,
  and weeks (integer estimate of duration).

Return:
- headline (string): short subtitle like "$country · $purposeCode · ~14 weeks"
- steps (array): the ordered steps
''';

  static const Map<String, dynamic> _roadmapSchema = <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'headline': <String, dynamic>{'type': 'string'},
      'steps': <String, dynamic>{
        'type': 'array',
        'items': <String, dynamic>{
          'type': 'object',
          'properties': <String, dynamic>{
            'id': <String, dynamic>{'type': 'string'},
            'title': <String, dynamic>{'type': 'string'},
            'description': <String, dynamic>{'type': 'string'},
            'weeks': <String, dynamic>{'type': 'integer'},
          },
          'required': <String>['id', 'title', 'description', 'weeks'],
        },
      },
    },
    'required': <String>['headline', 'steps'],
  };

  RoadmapPlanStep _toRoadmapStep(Map<String, dynamic> j) => RoadmapPlanStep(
        id: _str(j['id']),
        title: _str(j['title']),
        description: _str(j['description']),
        weeks: _int(j['weeks']),
      );

  @override
  Future<List<DocumentBrief>> documents({
    required String country,
    required String purposeCode,
    required String originCountry,
  }) async {
    final Map<String, dynamic> j = await _client.generateJson(
      prompt: _documentsPrompt(country, purposeCode, originCountry),
      schema: _documentsSchema,
    );
    final List<dynamic> items = (j['items'] as List<dynamic>?) ?? <dynamic>[];
    return items
        .whereType<Map<String, dynamic>>()
        .map(_toDocumentBrief)
        .where((DocumentBrief d) => d.title.isNotEmpty)
        .toList();
  }

  String _documentsPrompt(
    String country,
    String purposeCode,
    String originCountry,
  ) =>
      '''
You are an immigration paperwork expert. Given a person moving from
$originCountry to $country with purpose "$purposeCode" (one of:
study | work | family | tourism | business), return the full list of
documents and permits they will need.

Constraints:
- Return 6–12 items, ordered by importance (passport + visa first).
- Be SPECIFIC to $country. Use the real names of $country's documents
  and procedures. Examples (NEVER skip these when applicable to the
  destination):
    • Russia (work): Russian work patent (патент на работу) + monthly
      patent tax payment; migration card; notification of arrival;
      Russian language test (РКТ); HIV / medical certificate; voluntary
      health insurance (ДМС); INN tax number.
    • Germany: Anmeldung (address registration); Schufa; blocked account.
    • United States: SEVIS I-901; DS-160; SSN application; I-94.
    • United Kingdom: BRP / eVisa share code; ATAS (sensitive subjects);
      TB test (some countries).
    • Saudi Arabia / UAE: Emirates ID; medical fitness test; attestation
      of certificates by MoFA.
- Include RECURRING fees (monthly / yearly taxes, residence-card renewal
  fees, mandatory insurance) as separate items where applicable, with
  the monthly cost reflected in notes (e.g. "Monthly patent fee ~6000
  RUB" for Russia).
- Pick statusCode honestly: "required" if it's mandatory, "recommended" if
  consulates ask for it often, "optional" otherwise.

Per item return:
- id (string, lower_snake_case): stable identifier
- title (string): exact local-language-friendly name (e.g. "Work patent
  (патент на работу)" for Russia)
- issuer (string): who issues it (e.g. "Embassy / VFS", "GUVM",
  "MFA attestation", "You")
- statusCode (string): "required" | "recommended" | "optional"
- iconHint (string): ONE of: passport, id, visa, diploma, transcript,
  language, motivation, finance, cv, contract, criminal, family,
  business_plan, translate, other
- description (string, 1–2 sentences): plain-English explanation of what
  it is and the headline thing to get right
- validityYears (int): years of validity, 0 if N/A
- costUsd (int): approximate UPFRONT cost in USD, 0 if free/unknown.
  For recurring fees use the monthly amount and mention "(monthly)" in
  notes.
- notes (array of 0–3 short strings): caveats, where to apply, monthly /
  yearly costs, deadlines.
''';

  static const Map<String, dynamic> _documentsSchema = <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'items': <String, dynamic>{
        'type': 'array',
        'items': <String, dynamic>{
          'type': 'object',
          'properties': <String, dynamic>{
            'id': <String, dynamic>{'type': 'string'},
            'title': <String, dynamic>{'type': 'string'},
            'issuer': <String, dynamic>{'type': 'string'},
            'statusCode': <String, dynamic>{'type': 'string'},
            'iconHint': <String, dynamic>{'type': 'string'},
            'description': <String, dynamic>{'type': 'string'},
            'validityYears': <String, dynamic>{'type': 'integer'},
            'costUsd': <String, dynamic>{'type': 'integer'},
            'notes': <String, dynamic>{
              'type': 'array',
              'items': <String, dynamic>{'type': 'string'},
            },
          },
          'required': <String>[
            'id',
            'title',
            'issuer',
            'statusCode',
            'iconHint',
            'description',
            'validityYears',
            'costUsd',
            'notes',
          ],
        },
      },
    },
    'required': <String>['items'],
  };

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
