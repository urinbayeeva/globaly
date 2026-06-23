import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/i18n/app_strings.dart';
import '../../../../core/storage/prefs.dart';
import '../../../profile/domain/repositories/user_profile_repository.dart';
import '../../domain/entities/job.dart';
import '../../domain/repositories/recommendations_repository.dart';

const List<String> kWorkFields = <String>[
  'IT / Software',
  'Engineering',
  'Healthcare',
  'Education',
  'Hospitality',
  'Construction',
  'Logistics / Driving',
  'Sales / Marketing',
  'Finance',
  'Creative / Design',
];

class WorkState extends Equatable {
  const WorkState({
    this.country = '',
    this.field = '',
    this.language = LanguageProficiency.english,
    this.experienceYears = 0,
    this.jobs = const <Job>[],
    this.loading = false,
    this.error,
  });

  final String country;
  final String field;
  final LanguageProficiency language;
  final int experienceYears;
  final List<Job> jobs;
  final bool loading;
  final String? error;

  bool get hasPrefs => field.isNotEmpty;

  WorkState copyWith({
    String? country,
    String? field,
    LanguageProficiency? language,
    int? experienceYears,
    List<Job>? jobs,
    bool? loading,
    Object? error = _sentinel,
  }) =>
      WorkState(
        country: country ?? this.country,
        field: field ?? this.field,
        language: language ?? this.language,
        experienceYears: experienceYears ?? this.experienceYears,
        jobs: jobs ?? this.jobs,
        loading: loading ?? this.loading,
        error: identical(error, _sentinel) ? this.error : error as String?,
      );

  @override
  List<Object?> get props => <Object?>[
        country,
        field,
        language,
        experienceYears,
        jobs,
        loading,
        error,
      ];
}

const Object _sentinel = Object();

class WorkCubit extends Cubit<WorkState> {
  WorkCubit(this._prefs, this._repo, this._profile) : super(const WorkState());

  final Prefs _prefs;
  final RecommendationsRepository _repo;
  final UserProfileRepository _profile;

  void hydrate(String country) {
    final String field = _prefs.getString(Prefs.kWorkField) ?? '';
    final String langStr = _prefs.getString(Prefs.kWorkLanguage) ?? '';
    final LanguageProficiency lang = LanguageProficiency.values.firstWhere(
      (LanguageProficiency v) => v.name == langStr,
      orElse: () => LanguageProficiency.english,
    );
    final int xp = _prefs.getInt(Prefs.kWorkExperienceYears) ?? 0;
    emit(
      state.copyWith(
        country: country,
        field: field,
        language: lang,
        experienceYears: xp,
      ),
    );
    if (field.isNotEmpty) loadJobs();
  }

  void setField(String f) {
    _prefs.setString(Prefs.kWorkField, f);
    _profile.saveFieldOfStudy(f);
    emit(state.copyWith(field: f));
  }

  void setLanguage(LanguageProficiency l) {
    _prefs.setString(Prefs.kWorkLanguage, l.name);
    emit(state.copyWith(language: l));
  }

  void setExperience(int years) {
    _prefs.setInt(Prefs.kWorkExperienceYears, years);
    emit(state.copyWith(experienceYears: years));
  }

  Future<void> loadJobs() async {
    if (state.country.isEmpty || state.field.isEmpty) return;
    emit(state.copyWith(loading: true, error: null));
    try {
      final List<Job> list = await _repo.jobs(
        country: state.country,
        field: state.field,
        language: state.language.label,
        experienceYears: state.experienceYears,
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          jobs: list,
          loading: false,
          error: list.isEmpty ? T.t('work.noMatches') : null,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          loading: false,
          error: T.t('work.error'),
        ),
      );
    }
  }
}
