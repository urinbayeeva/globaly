import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/prefs.dart';
import '../../../profile_setup/data/datasources/countries_db.dart';
import '../../../profile_setup/domain/entities/country.dart';
import '../../../profile_setup/domain/entities/purpose.dart';
import '../../data/roadmap_repository.dart';
import '../../domain/entities/roadmap_step.dart';

class RoadmapState extends Equatable {
  const RoadmapState({
    this.steps = const <RoadmapStep>[],
    this.loading = false,
    this.country = '',
    this.purposeLabel = '',
  });

  final List<RoadmapStep> steps;
  final bool loading;
  final String country;
  final String purposeLabel;

  double get progress {
    if (steps.isEmpty) return 0;
    final int done =
        steps.where((RoadmapStep s) => s.state == StepState.done).length;
    return done / steps.length;
  }

  int get doneCount =>
      steps.where((RoadmapStep s) => s.state == StepState.done).length;

  RoadmapState copyWith({
    List<RoadmapStep>? steps,
    bool? loading,
    String? country,
    String? purposeLabel,
  }) =>
      RoadmapState(
        steps: steps ?? this.steps,
        loading: loading ?? this.loading,
        country: country ?? this.country,
        purposeLabel: purposeLabel ?? this.purposeLabel,
      );

  @override
  List<Object?> get props => <Object?>[steps, loading, country, purposeLabel];
}

class RoadmapCubit extends Cubit<RoadmapState> {
  RoadmapCubit(this._repo, this._prefs, this._countries)
      : super(const RoadmapState());

  final RoadmapRepository _repo;
  final Prefs _prefs;
  final CountriesDb _countries;

  String? _loadedKey;
  bool _inFlight = false;

  Future<void> ensureLoaded() async {
    final String? destCode = _prefs.getString(Prefs.kDestinationCountry);
    final String purposeCode =
        _prefs.getString(Prefs.kPurpose) ?? Purpose.study.code;
    final String key = '${destCode ?? ''}|$purposeCode';
    if (_loadedKey == key && state.steps.isNotEmpty) return;
    await _load(destCode, purposeCode, key);
  }

  Future<void> refresh() {
    _loadedKey = null;
    return ensureLoaded();
  }

  Future<void> _load(String? destCode, String purposeCode, String key) async {
    if (_inFlight) return;
    _inFlight = true;

    final Country? country =
        destCode == null ? null : _countries.byCode(destCode);
    final Purpose purpose = Purpose.fromCode(purposeCode);

    emit(
      RoadmapState(
        steps: state.steps,
        loading: true,
        country: country?.name ?? '',
        purposeLabel: purpose.label,
      ),
    );

    if (country == null) {
      _loadedKey = key;
      _inFlight = false;
      emit(state.copyWith(steps: _repo.buildPlan(), loading: false));
      return;
    }

    final List<RoadmapStep> ai = await _repo.buildPlanFor(
      country: country.name,
      purposeCode: purpose.code,
    );
    _inFlight = false;
    if (isClosed) return;
    _loadedKey = key;
    emit(state.copyWith(steps: ai, loading: false));
  }
}
