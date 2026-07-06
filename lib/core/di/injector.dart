import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/dio_client.dart';
import '../network/network_info.dart';
import '../i18n/locale_notifier.dart';
import '../services/backend_api.dart';
import '../services/backend_auth.dart';
import '../services/currency_service.dart';
import '../services/email_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../storage/prefs.dart';
import '../storage/secure_storage.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/datasources/email_verification_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_cubit.dart';
import '../../features/auth/presentation/bloc/email_verification_cubit.dart';
import '../../features/chat/data/datasources/gemini_chat_datasource.dart';
import '../../features/chat/data/repositories/chat_repository.dart';
import '../../features/chat/presentation/bloc/chat_cubit.dart';
import '../../features/documents/data/repositories/documents_repository_impl.dart';
import '../../features/documents/domain/repositories/documents_repository.dart';
import '../../features/documents/presentation/bloc/required_docs_cubit.dart';
import '../../features/home/data/datasources/home_local_datasource.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/home/presentation/bloc/home_cubit.dart';
import '../../features/onboarding/data/datasources/onboarding_local_datasource.dart';
import '../../features/onboarding/presentation/bloc/onboarding_cubit.dart';
import '../../features/profile_setup/data/datasources/countries_db.dart';
import '../../features/profile_setup/presentation/bloc/profile_setup_cubit.dart';
import '../../features/roadmap/data/roadmap_repository.dart';
import '../../features/roadmap/presentation/bloc/roadmap_cubit.dart';
import '../../features/scan/data/services/gemini_contract_analyzer.dart';
import '../../features/translator/data/services/document_translator.dart';
import '../../features/translator/presentation/bloc/translator_cubit.dart';
import '../../features/interview/data/services/visa_interview_service.dart';
import '../../features/cost_of_living/data/datasources/gemini_cost_datasource.dart';
import '../../features/cost_of_living/data/repositories/cost_repository_impl.dart';
import '../../features/cost_of_living/domain/cost_repository.dart';
import '../../features/cost_of_living/presentation/bloc/cost_cubit.dart';
import '../../features/culture/data/datasources/gemini_culture_datasource.dart';
import '../../features/culture/data/repositories/culture_repository_impl.dart';
import '../../features/culture/domain/culture_repository.dart';
import '../../features/culture/presentation/bloc/culture_cubit.dart';
import '../../features/interview/presentation/bloc/interview_cubit.dart';
import '../../features/profile/data/repositories/user_profile_repository_impl.dart';
import '../../features/profile/domain/repositories/user_profile_repository.dart';
import '../../features/recommendations/data/datasources/gemini_recommendations_datasource.dart';
import '../../features/recommendations/data/repositories/recommendations_repository_impl.dart';
import '../../features/recommendations/domain/repositories/recommendations_repository.dart';
import '../../features/recommendations/presentation/bloc/business_cubit.dart';
import '../../features/recommendations/presentation/bloc/travel_cubit.dart';
import '../../features/recommendations/presentation/bloc/visa_info_cubit.dart';
import '../../features/recommendations/presentation/bloc/work_cubit.dart';
import '../../features/scan/presentation/bloc/scan_cubit.dart';
import '../../features/score/presentation/bloc/score_cubit.dart';
import '../../features/universities/data/datasources/gemini_insights_datasource.dart';
import '../../features/universities/data/datasources/hipolabs_datasource.dart';
import '../../features/universities/data/datasources/wikipedia_datasource.dart';
import '../../features/universities/data/repositories/universities_repository_impl.dart';
import '../../features/universities/domain/repositories/universities_repository.dart';

final GetIt sl = GetIt.instance;

Future<void> initDependencies() async {
  final SharedPreferences sp = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sp);
  sl.registerLazySingleton<Prefs>(() => Prefs(sl<SharedPreferences>()));
  sl.registerLazySingleton<SecureStorage>(SecureStorage.new);
  sl.registerLazySingleton<DioClient>(DioClient.new);
  sl.registerLazySingleton<Dio>(() => sl<DioClient>().instance);
  sl.registerLazySingleton<InternetConnection>(InternetConnection.new);
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(sl<InternetConnection>()),
  );

  sl.registerLazySingleton<LocationService>(
    () => LocationService(sl<DioClient>(), sl<Prefs>()),
  );
  Future<String?> firebaseIdToken() async {
    try {
      return await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (_) {
      return null;
    }
  }

  sl.registerLazySingleton<AuthTokenProvider>(() => firebaseIdToken);

  sl.registerLazySingleton<BackendApi>(
    () => BackendApi(sl<Dio>(), tokenProvider: sl<AuthTokenProvider>()),
  );
  sl.registerLazySingleton<CurrencyService>(() => CurrencyService(sl<Dio>()));
  sl.registerLazySingleton<LocaleNotifier>(LocaleNotifier.new);
  sl.registerLazySingleton<NotificationService>(
    () => NotificationService(sl<Prefs>()),
  );

  sl.registerLazySingleton<EmailService>(
    () => EmailService(sl<Dio>(), tokenProvider: sl<AuthTokenProvider>()),
  );
  sl.registerLazySingleton<AuthRemoteDataSource>(AuthRemoteDataSourceImpl.new);
  sl.registerLazySingleton<EmailVerificationDataSource>(
    () => EmailVerificationDataSourceImpl(
      sl<EmailService>(),
      sl<FirebaseFirestore>(),
    ),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      sl<AuthRemoteDataSource>(),
      sl<EmailVerificationDataSource>(),
      sl<SecureStorage>(),
    ),
  );
  sl.registerFactory<AuthCubit>(() => AuthCubit(sl<AuthRepository>()));
  sl.registerFactory<EmailVerificationCubit>(
    () => EmailVerificationCubit(sl<AuthRepository>()),
  );

  sl.registerLazySingleton<OnboardingLocalDataSource>(
    () => OnboardingLocalDataSourceImpl(sl<Prefs>()),
  );
  sl.registerFactory<OnboardingCubit>(
    () => OnboardingCubit(sl<OnboardingLocalDataSource>()),
  );

  sl.registerLazySingleton<CountriesDb>(CountriesDb.new);
  sl.registerFactory<ProfileSetupCubit>(
    () => ProfileSetupCubit(
      sl<Prefs>(),
      sl<CountriesDb>(),
      sl<UserProfileRepository>(),
    ),
  );

  sl.registerLazySingleton<DocumentsRepository>(
    () => DocumentsRepositoryImpl(
      sl<RecommendationsRepository>(),
      sl<CountriesDb>(),
    ),
  );

  sl.registerLazySingleton<RequiredDocsCubit>(
    () => RequiredDocsCubit(
      sl<DocumentsRepository>(),
      sl<LocationService>(),
      sl<Prefs>(),
    ),
  );

  sl.registerLazySingleton<HomeLocalDataSource>(HomeLocalDataSourceImpl.new);
  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(sl<HomeLocalDataSource>()),
  );
  sl.registerFactory<HomeCubit>(
    () => HomeCubit(sl<HomeRepository>(), sl<Prefs>()),
  );

  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<UserProfileRepository>(
    () => UserProfileRepositoryImpl(
      sl<FirebaseFirestore>(),
      sl<AuthRepository>(),
    ),
  );

  sl.registerLazySingleton<GeminiRecommendationsDataSource>(
    () => GeminiRecommendationsDataSourceImpl(sl<BackendApi>()),
  );
  sl.registerLazySingleton<RecommendationsRepository>(
    () => RecommendationsRepositoryImpl(sl<GeminiRecommendationsDataSource>()),
  );
  sl.registerFactory<TravelCubit>(
    () => TravelCubit(sl<RecommendationsRepository>()),
  );
  sl.registerFactory<WorkCubit>(
    () => WorkCubit(
      sl<Prefs>(),
      sl<RecommendationsRepository>(),
      sl<UserProfileRepository>(),
    ),
  );
  sl.registerFactory<BusinessCubit>(
    () => BusinessCubit(sl<RecommendationsRepository>()),
  );
  sl.registerFactory<VisaInfoCubit>(
    () => VisaInfoCubit(sl<RecommendationsRepository>()),
  );

  // ─── Feature: cost of living ───
  sl.registerLazySingleton<CostDataSource>(
    () => GeminiCostDataSource(sl<BackendApi>()),
  );
  sl.registerLazySingleton<CostRepository>(
    () => CostRepositoryImpl(sl<CostDataSource>()),
  );
  sl.registerFactory<CostCubit>(() => CostCubit(sl<CostRepository>()));

  sl.registerLazySingleton<CultureDataSource>(
    () => GeminiCultureDataSource(sl<BackendApi>()),
  );
  sl.registerLazySingleton<CultureRepository>(
    () => CultureRepositoryImpl(sl<CultureDataSource>()),
  );
  sl.registerFactory<CultureCubit>(() => CultureCubit(sl<CultureRepository>()));

  sl.registerLazySingleton<HipolabsDataSource>(
    () => HipolabsDataSourceImpl(sl<Dio>()),
  );
  sl.registerLazySingleton<WikipediaDataSource>(
    () => WikipediaDataSourceImpl(sl<Dio>()),
  );
  sl.registerLazySingleton<GeminiInsightsDataSource>(
    () => GeminiInsightsDataSourceImpl(sl<BackendApi>()),
  );
  sl.registerLazySingleton<UniversitiesRepository>(
    () => UniversitiesRepositoryImpl(
      sl<HipolabsDataSource>(),
      sl<WikipediaDataSource>(),
      sl<GeminiInsightsDataSource>(),
      sl<CountriesDb>(),
    ),
  );

  sl.registerFactory<ScoreCubit>(
    () => ScoreCubit(
      sl<Prefs>(),
      sl<UniversitiesRepository>(),
      sl<CountriesDb>(),
      sl<UserProfileRepository>(),
    ),
  );

  sl.registerLazySingleton<GeminiContractAnalyzer>(
    () => GeminiContractAnalyzer(sl<BackendApi>()),
  );
  sl.registerFactory<ScanCubit>(
    () => ScanCubit(sl<GeminiContractAnalyzer>()),
  );

  sl.registerLazySingleton<DocumentTranslator>(
    () => DocumentTranslator(sl<BackendApi>()),
  );
  sl.registerFactory<TranslatorCubit>(
    () => TranslatorCubit(sl<DocumentTranslator>()),
  );

  sl.registerLazySingleton<VisaInterviewService>(
    () => VisaInterviewService(
      sl<BackendApi>(),
      sl<Prefs>(),
      sl<CountriesDb>(),
    ),
  );
  sl.registerFactory<InterviewCubit>(
    () => InterviewCubit(sl<VisaInterviewService>()),
  );

  sl.registerLazySingleton<RoadmapRepository>(
    () => RoadmapRepository(sl<RecommendationsRepository>()),
  );

  sl.registerLazySingleton<RoadmapCubit>(
    () => RoadmapCubit(
      sl<RoadmapRepository>(),
      sl<Prefs>(),
      sl<CountriesDb>(),
    ),
  );

  sl.registerLazySingleton<ChatDataSource>(
    () => GeminiChatDataSource(
      sl<BackendApi>(),
      sl<Prefs>(),
      sl<CountriesDb>(),
    ),
  );
  sl.registerLazySingleton<ChatRepository>(() => ChatRepository(sl<Prefs>()));

  sl.registerLazySingleton<ChatCubit>(
    () => ChatCubit(sl<ChatDataSource>(), sl<ChatRepository>()),
  );
}
