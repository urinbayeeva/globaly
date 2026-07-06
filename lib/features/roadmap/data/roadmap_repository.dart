import '../../recommendations/domain/entities/roadmap_plan.dart';
import '../../recommendations/domain/repositories/recommendations_repository.dart';
import '../domain/entities/roadmap_step.dart';

class RoadmapRepository {
  RoadmapRepository(this._recs);

  final RecommendationsRepository _recs;

  Future<List<RoadmapStep>> buildPlanFor({
    required String country,
    required String purposeCode,
  }) async {
    final RoadmapPlan? plan = await _recs.roadmap(
      country: country,
      purposeCode: purposeCode,
    );
    if (plan == null || plan.steps.isEmpty) return const <RoadmapStep>[];
    return _fromPlan(plan);
  }

  List<RoadmapStep> _fromPlan(RoadmapPlan plan) {
    final List<RoadmapStep> out = <RoadmapStep>[];
    for (int i = 0; i < plan.steps.length; i++) {
      final RoadmapPlanStep p = plan.steps[i];
      final StepState state = i == 0
          ? StepState.done
          : (i == 1 ? StepState.current : StepState.upcoming);
      final String desc = p.weeks > 0
          ? '${p.description} · ~${p.weeks} ${p.weeks == 1 ? 'week' : 'weeks'}'
          : p.description;
      out.add(
        RoadmapStep(
          id: p.id.isEmpty ? 'step_$i' : p.id,
          title: p.title,
          description: desc,
          state: state,
          weeks: p.weeks,
        ),
      );
    }
    return out;
  }
}
