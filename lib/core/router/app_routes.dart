class AppRoutes {
  AppRoutes._();
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String countryPicker = '/country-picker';
  static const String purposePicker = '/purpose-picker';

  static const String home = '/home';
  static const String roadmap = '/roadmap';
  static const String scan = '/scan';
  static const String chat = '/chat';
  static const String profile = '/profile';

  static const String score = '/score';
  static const String costOfLiving = '/cost-of-living';
  static const String universities = '/universities';
  static const String universityDetail = '/universities/:id';
  static const String explore = '/explore';
  static const String opportunityMap = '/opportunity-map';
  static const String chatHistory = '/chat-history';
  static const String translator = '/translator';
  static const String interview = '/interview';

  static String universityDetailPath(String id) => '/universities/$id';
  static String explorePath(String country) =>
      '/explore?country=${Uri.encodeQueryComponent(country)}';
  static String opportunityMapPath(String country) =>
      '/opportunity-map?country=${Uri.encodeQueryComponent(country)}';
}
