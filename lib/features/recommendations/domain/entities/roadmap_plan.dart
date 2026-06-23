import 'package:equatable/equatable.dart';

class RoadmapPlanStep extends Equatable {
  const RoadmapPlanStep({
    required this.id,
    required this.title,
    required this.description,
    required this.weeks,
  });

  final String id;
  final String title;
  final String description;

  final int weeks;

  @override
  List<Object?> get props => <Object?>[id, title, description, weeks];
}

class RoadmapPlan extends Equatable {
  const RoadmapPlan({
    required this.headline,
    required this.steps,
  });

  final String headline;
  final List<RoadmapPlanStep> steps;

  @override
  List<Object?> get props => <Object?>[headline, steps];
}
