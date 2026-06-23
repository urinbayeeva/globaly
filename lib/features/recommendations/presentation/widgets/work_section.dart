import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/url_opener.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../domain/entities/job.dart';
import '../bloc/work_cubit.dart';

class WorkSection extends StatelessWidget {
  const WorkSection({super.key, required this.country});
  final String country;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WorkCubit>(
      create: (_) => sl<WorkCubit>()..hydrate(country),
      child: BlocBuilder<WorkCubit, WorkState>(
        builder: (BuildContext c, WorkState s) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(T.of(context, 'work.title'), style: AppTypography.h3),
              const SizedBox(height: 2),
              Text(
                country.isEmpty
                    ? T.of(context, 'work.subtitleGeneric')
                    : T.of(context, 'work.subtitle').replaceAll('{0}', country),
                style: AppTypography.caption.copyWith(color: AppColors.gray500),
              ),
              const SizedBox(height: 12),
              _Preferences(state: s, cubit: c.read<WorkCubit>()),
              const SizedBox(height: 14),
              _JobsList(state: s),
            ],
          );
        },
      ),
    );
  }
}

class _Preferences extends StatelessWidget {
  const _Preferences({required this.state, required this.cubit});
  final WorkState state;
  final WorkCubit cubit;

  String _langLabel(LanguageProficiency l) {
    switch (l) {
      case LanguageProficiency.english:
        return T.t('work.lang.english');
      case LanguageProficiency.local:
        return T.t('work.lang.local');
      case LanguageProficiency.both:
        return T.t('work.lang.both');
      case LanguageProficiency.none:
        return T.t('work.lang.none');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _RowLabel(T.of(context, 'work.field')),
          const SizedBox(height: 8),
          _ChipPicker<String>(
            options: kWorkFields,
            value: state.field.isEmpty ? null : state.field,
            labelOf: (String f) => f,
            onChanged: cubit.setField,
          ),
          const SizedBox(height: 14),
          _RowLabel(T.of(context, 'work.language')),
          const SizedBox(height: 8),
          _ChipPicker<LanguageProficiency>(
            options: LanguageProficiency.values,
            value: state.language,
            labelOf: (LanguageProficiency l) => _langLabel(l),
            onChanged: cubit.setLanguage,
          ),
          const SizedBox(height: 14),
          _RowLabel(T.of(context, 'work.experience')),
          const SizedBox(height: 8),
          _ChipPicker<int>(
            options: const <int>[0, 1, 2, 3, 5, 8],
            value: state.experienceYears,
            labelOf: (int y) => y == 0
                ? T.t('work.years.none')
                : T.t('work.years.plus').replaceAll('{0}', '$y'),
            onChanged: cubit.setExperience,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  state.field.isEmpty || state.loading ? null : cubit.loadJobs,
              icon: state.loading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.search_rounded, size: 18),
              label: Text(
                state.jobs.isEmpty
                    ? T.of(context, 'work.findJobs')
                    : T.of(context, 'work.refreshJobs'),
                style: AppTypography.bodyL.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand,
                disabledBackgroundColor: AppColors.gray300,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RowLabel extends StatelessWidget {
  const _RowLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTypography.micro.copyWith(
        color: AppColors.gray500,
        fontSize: 11,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _ChipPicker<E> extends StatelessWidget {
  const _ChipPicker({
    required this.options,
    required this.value,
    required this.labelOf,
    required this.onChanged,
  });
  final List<E> options;
  final E? value;
  final String Function(E) labelOf;
  final ValueChanged<E> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: options.map<Widget>((E o) {
        final bool selected = o == value;
        return GestureDetector(
          onTap: () => onChanged(o),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.brand100 : AppColors.gray100,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? AppColors.brand : AppColors.gray200,
              ),
            ),
            child: Text(
              labelOf(o),
              style: AppTypography.bodyM.copyWith(
                color: selected ? AppColors.brand700 : AppColors.gray700,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _JobsList extends StatelessWidget {
  const _JobsList({required this.state});
  final WorkState state;

  @override
  Widget build(BuildContext context) {
    if (state.loading) {
      return Column(
        children: List<Widget>.generate(
          3,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              height: 100,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(color: AppColors.gray200),
              ),
              child: const AppShimmer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ShimmerBox(),
                    SizedBox(height: 8),
                    ShimmerBox(width: 180, height: 10),
                    Spacer(),
                    Row(
                      children: <Widget>[
                        ShimmerBox(width: 70, height: 18, radius: 999),
                        SizedBox(width: 6),
                        ShimmerBox(width: 50, height: 18, radius: 999),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    if (state.jobs.isEmpty) {
      if (state.field.isEmpty) {
        return _MutedNotice(text: T.t('work.pickField'));
      }
      return _MutedNotice(
        text: state.error ?? T.t('work.tapFind'),
      );
    }
    return Column(
      children: <Widget>[
        for (final Job j in state.jobs)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _JobCard(job: j),
          ),
      ],
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job});
  final Job job;

  @override
  Widget build(BuildContext context) {
    final String salary = _formatSalary(job);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => UrlOpener.open(context, job.searchUrl),
        onLongPress: () => UrlOpener.copy(context, job.searchUrl),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          job.title,
                          style: AppTypography.bodyL.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${job.company} · ${job.city}',
                          style: AppTypography.caption
                              .copyWith(color: AppColors.gray500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.open_in_new_rounded,
                    color: AppColors.gray400,
                    size: 18,
                  ),
                ],
              ),
              if (job.summary.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  job.summary,
                  style: AppTypography.bodyM.copyWith(
                    color: AppColors.gray700,
                    height: 18 / 13,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  if (salary.isNotEmpty) _Tag(label: salary, tone: _Tone.ink),
                  if (job.experienceYears > 0)
                    _Tag(
                      label: T
                          .t('work.years.plus')
                          .replaceAll('{0}', '${job.experienceYears}'),
                      tone: _Tone.gray,
                    ),
                  if (job.languageRequirement.isNotEmpty)
                    _Tag(label: job.languageRequirement, tone: _Tone.gray),
                  if (job.visaSponsorship)
                    _Tag(
                      label: T.t('work.visaSponsorship'),
                      tone: _Tone.success,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSalary(Job j) {
    if (j.salaryUsdPerMonthMin == 0 && j.salaryUsdPerMonthMax == 0) return '';
    if (j.salaryUsdPerMonthMin == j.salaryUsdPerMonthMax) {
      return '\$${j.salaryUsdPerMonthMin}/mo';
    }
    return '\$${j.salaryUsdPerMonthMin}–\$${j.salaryUsdPerMonthMax}/mo';
  }
}

enum _Tone { ink, gray, success }

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.tone});
  final String label;
  final _Tone tone;
  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (tone) {
      case _Tone.ink:
        bg = AppColors.gray100;
        fg = AppColors.ink;
        break;
      case _Tone.gray:
        bg = AppColors.gray100;
        fg = AppColors.gray700;
        break;
      case _Tone.success:
        bg = AppColors.success100;
        fg = AppColors.success700;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.micro.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _MutedNotice extends StatelessWidget {
  const _MutedNotice({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.gray500,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyM.copyWith(color: AppColors.gray700),
            ),
          ),
        ],
      ),
    );
  }
}
