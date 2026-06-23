import 'package:equatable/equatable.dart';

class InterviewTurn extends Equatable {
  const InterviewTurn({
    required this.question,
    this.answer = '',
    this.feedback = '',
  });

  final String question;
  final String answer;
  final String feedback;

  bool get isAnswered => answer.trim().isNotEmpty;

  InterviewTurn copyWith({String? answer, String? feedback}) => InterviewTurn(
        question: question,
        answer: answer ?? this.answer,
        feedback: feedback ?? this.feedback,
      );

  @override
  List<Object?> get props => <Object?>[question, answer, feedback];
}

class InterviewExchange extends Equatable {
  const InterviewExchange({
    this.feedback = '',
    this.question = '',
    this.done = false,
    this.assessment = '',
    this.score = 0,
    this.tips = const <String>[],
  });

  final String feedback;
  final String question;
  final bool done;
  final String assessment;
  final int score;
  final List<String> tips;

  @override
  List<Object?> get props =>
      <Object?>[feedback, question, done, assessment, score, tips];
}
