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
    if (plan == null || plan.steps.isEmpty) {
      return _fallbackPlan(country: country, purposeCode: purposeCode);
    }
    return _fromPlan(plan);
  }

  List<RoadmapStep> buildPlan() =>
      _fallbackPlan(country: '', purposeCode: 'study');

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

  List<RoadmapStep> _fallbackPlan({
    required String country,
    required String purposeCode,
  }) {
    final String where = country.isEmpty ? 'destination' : country;
    return <RoadmapStep>[
      const RoadmapStep(
        id: 'passport',
        title: 'Get a valid international passport',
        description: 'Required first — usually 4 weeks at the office',
        state: StepState.done,
        weeks: 0,
      ),
      RoadmapStep(
        id: 'visa',
        title: 'Apply for the right visa',
        description: 'Visa type depends on $where',
        state: StepState.current,
        weeks: 5,
      ),
      const RoadmapStep(
        id: 'documents',
        title: 'Gather supporting documents',
        description: 'Translations, financial proof, insurance',
        state: StepState.upcoming,
        weeks: 3,
      ),
      const RoadmapStep(
        id: 'flight',
        title: 'Book your flight',
        description: 'Once visa is approved',
        state: StepState.upcoming,
        weeks: 0,
      ),
      const RoadmapStep(
        id: 'register',
        title: 'Register on arrival',
        description: 'Address registration / local ID',
        state: StepState.upcoming,
        weeks: 2,
      ),
      const RoadmapStep(
        id: 'residence',
        title: 'Get residence permit',
        description: 'Long-term legal status',
        state: StepState.upcoming,
        weeks: 6,
      ),
    ];
  }
}
