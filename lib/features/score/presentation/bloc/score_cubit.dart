import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/prefs.dart';
import '../../../profile/domain/repositories/user_profile_repository.dart';
import '../../../profile_setup/data/datasources/countries_db.dart';
import '../../../profile_setup/domain/entities/country.dart';
import '../../../universities/domain/entities/university.dart';
import '../../../universities/domain/repositories/universities_repository.dart';
import '../../domain/entities/education.dart';
import '../../domain/entities/field_of_study.dart';

class ScoreState extends Equatable {
  const ScoreState({
    this.education = EducationLevel.bachelor,
    this.field = FieldOfStudy.computerScience,
    this.ielts = 6.0,
    this.sat = 1300,
    this.budget = 1200,
    this.experienceYears = 3,
    this.universities = const <University>[],
    this.loadingUniversities = false,
    this.universitiesError,
    this.destinationCountryName = '',
    this.visibleCount = pageSize,
  });

  static const int pageSize = 20;

  final EducationLevel education;
  final FieldOfStudy field;
  final double ielts;
  final int sat;
  final int budget;
  final int experienceYears;
  final List<University> universities;
  final bool loadingUniversities;
  final String? universitiesError;
  final String destinationCountryName;
  final int visibleCount;

  int get score {
    final double base = 60 + (ielts - 5) * 8 + (budget - 800) / 40;
    return base.clamp(0, 100).round();
  }

  List<University> get visibleUniversities {
    if (universities.length <= visibleCount) return universities;
    return universities.sublist(0, visibleCount);
  }

  bool get hasMore => universities.length > visibleCount;
  int get remainingCount => universities.length - visibleCount;

  ScoreState copyWith({
    EducationLevel? education,
    FieldOfStudy? field,
    double? ielts,
    int? sat,
    int? budget,
    int? experienceYears,
    List<University>? universities,
    bool? loadingUniversities,
    Object? universitiesError = _sentinel,
    String? destinationCountryName,
    int? visibleCount,
  }) =>
      ScoreState(
        education: education ?? this.education,
        field: field ?? this.field,
        ielts: ielts ?? this.ielts,
        sat: sat ?? this.sat,
        budget: budget ?? this.budget,
        experienceYears: experienceYears ?? this.experienceYears,
        universities: universities ?? this.universities,
        loadingUniversities: loadingUniversities ?? this.loadingUniversities,
        universitiesError: identical(universitiesError, _sentinel)
            ? this.universitiesError
            : universitiesError as String?,
        destinationCountryName:
            destinationCountryName ?? this.destinationCountryName,
        visibleCount: visibleCount ?? this.visibleCount,
      );

  @override
  List<Object?> get props => <Object?>[
        education,
        field,
        ielts,
        sat,
        budget,
        experienceYears,
        universities,
        loadingUniversities,
        universitiesError,
        destinationCountryName,
        visibleCount,
      ];
}

const Object _sentinel = Object();

class ScoreCubit extends Cubit<ScoreState> {
  ScoreCubit(this._prefs, this._repo, this._countries, this._profile)
      : super(const ScoreState()) {
    _hydrate();
  }

  final Prefs _prefs;
  final UniversitiesRepository _repo;
  final CountriesDb _countries;
  final UserProfileRepository _profile;

  Timer? _ieltsDebounce;
  Timer? _satDebounce;
  static const Duration _writeDebounce = Duration(milliseconds: 600);

  void _hydrate() {
    final EducationLevel ed =
        EducationLevel.fromCode(_prefs.getString(Prefs.kEducationLevel));
    final String? f = _prefs.getString(Prefs.kFieldOfStudy);
    final FieldOfStudy field = FieldOfStudy.values.firstWhere(
      (FieldOfStudy v) => v.label == f,
      orElse: () => FieldOfStudy.computerScience,
    );

    final double? lang = _prefs.getDouble(Prefs.kLanguageScore);
    final bool isSat = lang != null && lang >= 100;
    final double ielts = (lang != null && !isSat)
        ? lang.clamp(4.0, 9.0).toDouble()
        : state.ielts;
    final int sat = isSat ? lang.clamp(400, 1600).round() : state.sat;
    emit(
      state.copyWith(
        education: ed,
        field: field,
        ielts: ielts,
        sat: sat,
      ),
    );
    loadUniversities();
  }

  void setEducation(EducationLevel ed) {
    _prefs.setString(Prefs.kEducationLevel, ed.code);
    _profile.saveEducationLevel(ed.code);
    emit(state.copyWith(education: ed));
  }

  void setField(FieldOfStudy f) {
    _prefs.setString(Prefs.kFieldOfStudy, f.label);
    _profile.saveFieldOfStudy(f.label);
    emit(state.copyWith(field: f));
  }

  void setIelts(double v) {
    _prefs.setDouble(Prefs.kLanguageScore, v);
    emit(state.copyWith(ielts: v));
    _ieltsDebounce?.cancel();
    _ieltsDebounce = Timer(_writeDebounce, () => _profile.saveIelts(v));
  }

  void setSat(int v) {
    _prefs.setDouble(Prefs.kLanguageScore, v.toDouble());
    emit(state.copyWith(sat: v));
    _satDebounce?.cancel();
    _satDebounce = Timer(_writeDebounce, () => _profile.saveSat(v));
  }

  void setBudget(int v) => emit(state.copyWith(budget: v));

  @override
  Future<void> close() {
    _ieltsDebounce?.cancel();
    _satDebounce?.cancel();
    return super.close();
  }

  Future<void> loadUniversities() async {
    final String? destCode = _prefs.getString(Prefs.kDestinationCountry);
    final Country? country =
        destCode == null ? null : _countries.byCode(destCode);
    if (country == null) {
      emit(
        state.copyWith(
          universities: const <University>[],
          loadingUniversities: false,
          universitiesError: 'Pick a destination country first',
          destinationCountryName: '',
          visibleCount: ScoreState.pageSize,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        loadingUniversities: true,
        universitiesError: null,
        destinationCountryName: country.name,
        visibleCount: ScoreState.pageSize,
      ),
    );
    try {
      final List<University> list = await _repo.byCountry(country.name);
      if (isClosed) return;
      emit(
        state.copyWith(
          universities: list,
          loadingUniversities: false,
          universitiesError:
              list.isEmpty ? 'No universities found for ${country.name}' : null,
          visibleCount: ScoreState.pageSize,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          loadingUniversities: false,
          universitiesError: 'Could not load universities. Try again.',
        ),
      );
    }
  }

  void loadMoreUniversities() {
    if (!state.hasMore) return;
    final int next = (state.visibleCount + ScoreState.pageSize)
        .clamp(0, state.universities.length);
    emit(state.copyWith(visibleCount: next));
  }
}
