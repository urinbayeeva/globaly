import 'package:flutter/foundation.dart';

import '../di/injector.dart';
import '../storage/prefs.dart';

class LocaleNotifier extends ValueNotifier<String> {
  LocaleNotifier() : super(_initial());

  static String _initial() {
    try {
      return sl<Prefs>().getString(Prefs.kAppLocale) ?? 'en';
    } catch (_) {
      return 'en';
    }
  }

  Future<void> setLocale(String code) async {
    await sl<Prefs>().setString(Prefs.kAppLocale, code);
    value = code;
  }
}
