import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/i18n/app_strings.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/culture_briefing.dart';
import '../../domain/culture_repository.dart';

enum CultureStatus { loading, ready, error }

class CultureState extends Equatable {
  const CultureState({
    this.status = CultureStatus.loading,
    this.country = '',
    this.briefing,
    this.error,
    this.answers = const <int, int>{},
  });

  final CultureStatus status;
  final String country;
  final CultureBriefing? briefing;
  final String? error;
  final Map<int, int> answers;

  int get totalScenarios => briefing?.scenarios.length ?? 0;
  int get answeredScenarios => answers.length;
  bool get quizComplete =>
      totalScenarios > 0 && answeredScenarios >= totalScenarios;

  int get correctScenarios {
    final CultureBriefing? b = briefing;
    if (b == null) return 0;
    int hits = 0;
    answers.forEach((int index, int option) {
      if (index < b.scenarios.length && b.scenarios[index].isCorrect(option)) {
        hits++;
      }
    });
    return hits;
  }

  CultureState copyWith({
    CultureStatus? status,
    String? country,
    Object? briefing = _sentinel,
    Object? error = _sentinel,
    Map<int, int>? answers,
  }) =>
      CultureState(
        status: status ?? this.status,
        country: country ?? this.country,
        briefing: identical(briefing, _sentinel)
            ? this.briefing
            : briefing as CultureBriefing?,
        error: identical(error, _sentinel) ? this.error : error as String?,
        answers: answers ?? this.answers,
      );

  @override
  List<Object?> get props =>
      <Object?>[status, country, briefing, error, answers];
}

const Object _sentinel = Object();

class CultureCubit extends Cubit<CultureState> {
  CultureCubit(this._repo) : super(const CultureState());

  final CultureRepository _repo;

  Future<void> load({required String country, required String flag}) async {
    if (country.isEmpty) {
      emit(
        CultureState(
          status: CultureStatus.error,
          error: T.t('culture.noDestination'),
        ),
      );
      return;
    }
    if (!_repo.isConfigured) {
      emit(
        CultureState(
          status: CultureStatus.error,
          country: country,
          error: T.t('culture.noAi'),
        ),
      );
      return;
    }
    if (state.country == country && state.briefing != null) return;

    emit(CultureState(country: country));
    try {
      final CultureBriefing briefing =
          await _repo.forCountry(country: country, flag: flag);
      if (isClosed || state.country != country) return;
      if (briefing.isEmpty) {
        emit(
          state.copyWith(
            status: CultureStatus.error,
            error: T.t('culture.error'),
          ),
        );
        return;
      }
      emit(
        CultureState(
          status: CultureStatus.ready,
          country: country,
          briefing: briefing,
        ),
      );
    } catch (e, st) {
      appLogger.e('culture load failed', error: e, stackTrace: st);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: CultureStatus.error,
          error: T.t('culture.error'),
        ),
      );
    }
  }

  void selectAnswer(int scenarioIndex, int option) {
    if (state.briefing == null || state.answers.containsKey(scenarioIndex)) {
      return;
    }
    final Map<int, int> next = Map<int, int>.of(state.answers)
      ..[scenarioIndex] = option;
    emit(state.copyWith(answers: next));
  }

  void retakeQuiz() => emit(state.copyWith(answers: const <int, int>{}));
}
