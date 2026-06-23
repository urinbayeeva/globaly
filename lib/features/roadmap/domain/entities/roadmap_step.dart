import 'package:equatable/equatable.dart';

enum StepState { done, current, upcoming }

class RoadmapStep extends Equatable {
  const RoadmapStep({
    required this.id,
    required this.title,
    required this.description,
    required this.state,
    required this.weeks,
  });

  final String id;
  final String title;
  final String description;
  final StepState state;
  final int weeks;

  @override
  List<Object?> get props => <Object?>[id, title, description, state, weeks];
}
