import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  Prefs(this._prefs);
  final SharedPreferences _prefs;

  static const String kOnboardingDone = 'onboarding_done';
  static const String kOriginCountry = 'origin_country';
  static const String kOriginCachedAt = 'origin_cached_at';
  static const String kDestinationCountry = 'destination_country';
  static const String kPurpose = 'purpose';
  static const String kEducationLevel = 'education_level';
  static const String kFieldOfStudy = 'field_of_study';
  static const String kLanguageScore = 'language_score';

  static const String kWorkField = 'work_field';
  static const String kWorkLanguage = 'work_language';
  static const String kWorkExperienceYears = 'work_experience_years';

  static const String kAppLocale = 'app_locale';

  static const String kNotifications = 'notifications_on';

  static const String kTourDone = 'tour_done';

  String? getString(String key) => _prefs.getString(key);
  Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);
  bool? getBool(String key) => _prefs.getBool(key);
  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);
  int? getInt(String key) => _prefs.getInt(key);
  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);
  double? getDouble(String key) => _prefs.getDouble(key);
  Future<bool> setDouble(String key, double value) =>
      _prefs.setDouble(key, value);
  Future<bool> remove(String key) => _prefs.remove(key);
}
