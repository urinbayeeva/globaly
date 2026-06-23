import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/i18n/app_strings.dart';
import '../../../../core/utils/app_logger.dart';
import '../../data/services/visa_interview_service.dart';
import '../../domain/entities/interview_turn.dart';

enum InterviewStatus {
  intro,
  thinking,
  asking,
  finished,
  error,
}

class InterviewState extends Equatable {
  const InterviewState({
    this.status = InterviewStatus.intro,
    this.turns = const <InterviewTurn>[],
    this.assessment = '',
    this.score = 0,
    this.tips = const <String>[],
    this.message,
  });

  final InterviewStatus status;
  final List<InterviewTurn> turns;
  final String assessment;
  final int score;
  final List<String> tips;
  final String? message;

  int get questionNumber => turns.length;

  InterviewState copyWith({
    InterviewStatus? status,
    List<InterviewTurn>? turns,
    String? assessment,
    int? score,
    List<String>? tips,
    Object? message = _sentinel,
  }) =>
      InterviewState(
        status: status ?? this.status,
        turns: turns ?? this.turns,
        assessment: assessment ?? this.assessment,
        score: score ?? this.score,
        tips: tips ?? this.tips,
        message:
            identical(message, _sentinel) ? this.message : message as String?,
      );

  @override
  List<Object?> get props =>
      <Object?>[status, turns, assessment, score, tips, message];
}

const Object _sentinel = Object();

class InterviewCubit extends Cubit<InterviewState> {
  InterviewCubit(this._service) : super(const InterviewState());

  final VisaInterviewService _service;

  Future<void> start() async {
    if (!_service.isConfigured) {
      emit(
        state.copyWith(
          status: InterviewStatus.error,
          message: T.t('interview.noAi'),
        ),
      );
      return;
    }
    emit(const InterviewState(status: InterviewStatus.thinking));
    try {
      final InterviewExchange ex = await _service.next(
        turns: const <InterviewTurn>[],
      );
      if (isClosed) return;
      emit(
        InterviewState(
          status: InterviewStatus.asking,
          turns: <InterviewTurn>[InterviewTurn(question: ex.question)],
        ),
      );
    } catch (e, st) {
      _fail(e, st);
    }
  }

  Future<void> answer(String text) async {
    final String trimmed = text.trim();
    if (trimmed.isEmpty ||
        state.status != InterviewStatus.asking ||
        state.turns.isEmpty) {
      return;
    }

    final List<InterviewTurn> answered = List<InterviewTurn>.of(state.turns);
    answered[answered.length - 1] = answered.last.copyWith(answer: trimmed);
    emit(state.copyWith(status: InterviewStatus.thinking, turns: answered));

    try {
      final InterviewExchange ex = await _service.next(
        turns: answered,
        latestAnswer: trimmed,
      );
      if (isClosed) return;

      final List<InterviewTurn> withFeedback = List<InterviewTurn>.of(answered);
      if (ex.feedback.isNotEmpty) {
        withFeedback[withFeedback.length - 1] =
            withFeedback.last.copyWith(feedback: ex.feedback);
      }

      if (ex.done || ex.question.isEmpty) {
        emit(
          state.copyWith(
            status: InterviewStatus.finished,
            turns: withFeedback,
            assessment: ex.assessment,
            score: ex.score,
            tips: ex.tips,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: InterviewStatus.asking,
            turns: <InterviewTurn>[
              ...withFeedback,
              InterviewTurn(question: ex.question),
            ],
          ),
        );
      }
    } catch (e, st) {
      _fail(e, st);
    }
  }

  void _fail(Object e, StackTrace st) {
    appLogger.e('interview step failed', error: e, stackTrace: st);
    if (isClosed) return;
    emit(
      state.copyWith(
        status: InterviewStatus.error,
        message: T.t('interview.error'),
      ),
    );
  }

  void reset() => emit(const InterviewState());
}
