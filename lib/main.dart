import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/config/env.dart';
import 'core/di/injector.dart';
import 'core/i18n/locale_notifier.dart';
import 'core/router/app_router.dart';
import 'core/services/gemini_client.dart';
import 'core/services/groq_client.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_bloc_observer.dart';
import 'core/utils/app_logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  Bloc.observer = const AppBlocObserver();

  await Env.load();

  try {
    await Firebase.initializeApp();
    appLogger.i('🔥 Firebase initialised');
  } catch (e) {
    appLogger.w('🔥 Firebase init skipped: $e');
  }

  await initDependencies();
  final bool geminiOk = sl<GeminiClient>().hasOwnKey;
  final bool groqOk = sl<GroqClient>().isConfigured;
  appLogger.i(
    '🤖 AI providers — Gemini: ${geminiOk ? 'on' : 'off'} · '
    'Groq: ${groqOk ? 'on' : 'off'}',
  );

  runApp(const GlobalyApp());
}

class GlobalyApp extends StatelessWidget {
  const GlobalyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final LocaleNotifier locale = sl<LocaleNotifier>();
    return ValueListenableBuilder<String>(
      valueListenable: locale,
      builder: (BuildContext c, String code, _) {
        return MaterialApp.router(
          key: ValueKey<String>('app-$code'),
          title: 'Globaly',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          routerConfig: AppRouter.router,
        );
      },
    );
  }
}
