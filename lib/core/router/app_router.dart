import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/sign_in_page.dart';
import '../../features/auth/presentation/pages/sign_up_page.dart';
import '../../features/chat/presentation/pages/chat_page.dart';
import '../../features/cost_of_living/presentation/pages/cost_of_living_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile_setup/presentation/pages/country_picker_page.dart';
import '../../features/profile_setup/presentation/pages/purpose_picker_page.dart';
import '../../features/roadmap/presentation/pages/roadmap_page.dart';
import '../../features/scan/presentation/pages/scan_page.dart';
import '../../features/score/presentation/pages/score_page.dart';
import '../../features/translator/presentation/pages/translator_page.dart';
import '../../features/interview/presentation/pages/interview_page.dart';
import '../../features/shell/presentation/pages/shell_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/chat/presentation/pages/chat_history_page.dart';
import '../../features/recommendations/presentation/pages/explore_page.dart';
import '../../features/recommendations/presentation/pages/opportunity_map_page.dart';
import '../../features/universities/presentation/pages/university_detail_page.dart';
import 'app_routes.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        builder: (_, __) => const SignInPage(),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        builder: (_, __) => const SignUpPage(),
      ),
      GoRoute(
        path: AppRoutes.countryPicker,
        builder: (_, __) => const CountryPickerPage(),
      ),
      GoRoute(
        path: AppRoutes.purposePicker,
        builder: (_, __) => const PurposePickerPage(),
      ),
      GoRoute(
        path: AppRoutes.score,
        builder: (_, __) => const ScorePage(),
      ),
      GoRoute(
        path: AppRoutes.costOfLiving,
        builder: (_, __) => const CostOfLivingPage(),
      ),
      GoRoute(
        path: AppRoutes.universityDetail,
        builder: (_, GoRouterState s) =>
            UniversityDetailPage(id: s.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: AppRoutes.explore,
        builder: (_, GoRouterState s) =>
            ExplorePage(country: s.uri.queryParameters['country'] ?? ''),
      ),
      GoRoute(
        path: AppRoutes.opportunityMap,
        builder: (_, GoRouterState s) => OpportunityMapPage(
          country: s.uri.queryParameters['country'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.chatHistory,
        builder: (_, __) => const ChatHistoryPage(),
      ),
      GoRoute(
        path: AppRoutes.translator,
        builder: (_, __) => const TranslatorPage(),
      ),
      GoRoute(
        path: AppRoutes.interview,
        builder: (_, __) => const InterviewPage(),
      ),
      ShellRoute(
        builder: (BuildContext ctx, GoRouterState state, Widget child) =>
            ShellPage(child: child),
        routes: <RouteBase>[
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (BuildContext c, GoRouterState s) =>
                _fade(s, const HomePage()),
          ),
          GoRoute(
            path: AppRoutes.roadmap,
            pageBuilder: (BuildContext c, GoRouterState s) =>
                _fade(s, const RoadmapPage()),
          ),
          GoRoute(
            path: AppRoutes.scan,
            pageBuilder: (BuildContext c, GoRouterState s) =>
                _fade(s, const ScanPage()),
          ),
          GoRoute(
            path: AppRoutes.chat,
            pageBuilder: (BuildContext c, GoRouterState s) =>
                _fade(s, const ChatPage()),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (BuildContext c, GoRouterState s) =>
                _fade(s, const ProfilePage()),
          ),
        ],
      ),
    ],
  );

  static CustomTransitionPage<void> _fade(GoRouterState s, Widget child) =>
      CustomTransitionPage<void>(
        key: s.pageKey,
        child: child,
        transitionDuration: const Duration(milliseconds: 180),
        transitionsBuilder: (_, Animation<double> anim, __, Widget c) =>
            FadeTransition(opacity: anim, child: c),
      );
}
