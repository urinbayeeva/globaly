import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/storage/prefs.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/url_opener.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../domain/entities/university.dart';
import '../../domain/entities/university_insights.dart';
import '../../domain/repositories/universities_repository.dart';

class UniversityDetailPage extends StatelessWidget {
  const UniversityDetailPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBg,
      body: FutureBuilder<University?>(
        future: sl<UniversitiesRepository>().byId(id),
        builder: (BuildContext c, AsyncSnapshot<University?> snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const _UniversityDetailSkeleton();
          }
          final University? u = snap.data;
          if (u == null) {
            return Scaffold(
              backgroundColor: AppColors.appBg,
              appBar: AppBar(
                backgroundColor: AppColors.appBg,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: AppColors.ink,
                  ),
                  onPressed: () => context.pop(),
                ),
              ),
              body: const Center(child: Text('University not found')),
            );
          }
          return _DetailView(university: u);
        },
      ),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView({required this.university});
  final University university;

  @override
  Widget build(BuildContext context) {
    final bool hasHero = university.imageUrl.isNotEmpty;
    return CustomScrollView(
      slivers: <Widget>[
        if (hasHero)
          _HeroAppBar(university: university, onBack: () => context.pop())
        else
          _PlainAppBar(onBack: () => context.pop()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _TitleBlock(university: university),
                if (university.about.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 22),
                  const Text('About', style: AppTypography.h3),
                  const SizedBox(height: 8),
                  Text(
                    university.about,
                    style: AppTypography.bodyL.copyWith(
                      color: AppColors.gray800,
                      height: 22 / 14,
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                const Text('Details', style: AppTypography.h3),
                const SizedBox(height: 10),
                _DetailsCard(university: university),
                const SizedBox(height: 22),
                _AiInsightsSection(university: university),
                const SizedBox(height: 22),
                const Text('Apply online', style: AppTypography.h3),
                const SizedBox(height: 8),
                if (university.websiteUrl.isNotEmpty)
                  _LinkCard(
                    title: 'Official website',
                    url: university.websiteUrl,
                  )
                else
                  const _MutedNotice(
                    text:
                        'No official application URL was returned by the directory.',
                  ),
                if (university.websiteUrl.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 18),
                  AppButton(
                    label: 'Open website',
                    icon: Icons.open_in_new_rounded,
                    onPressed: () => _open(context, university.websiteUrl),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroAppBar extends StatelessWidget {
  const _HeroAppBar({required this.university, required this.onBack});
  final University university;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.appBg,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.ink,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      title: Text(
        university.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.bodyL.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
      ),
      titleSpacing: 0,
      centerTitle: false,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
        child: GestureDetector(
          onTap: onBack,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: const SizedBox.shrink(),
        background: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            CachedNetworkImage(
              imageUrl: university.imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: AppColors.gray200),
              errorWidget: (_, __, ___) => Container(
                color: AppColors.gray200,
                child: const Icon(
                  Icons.school_rounded,
                  color: AppColors.gray400,
                  size: 56,
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Color(0x00000000),
                    Color(0x66000000),
                    Color(0xAA000000),
                  ],
                  stops: <double>[0.3, 0.75, 1],
                ),
              ),
              child: SizedBox.expand(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlainAppBar extends StatelessWidget {
  const _PlainAppBar({required this.onBack});
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.appBg,
      elevation: 0,
      foregroundColor: AppColors.ink,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        onPressed: onBack,
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.university});
  final University university;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  if (university.flag.isNotEmpty) ...<Widget>[
                    Text(
                      university.flag,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      _location(university),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                university.name,
                style: AppTypography.h2.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        if (university.logoUrl.isNotEmpty)
          Container(
            width: 56,
            height: 56,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: AppColors.gray200),
            ),
            child: CachedNetworkImage(
              imageUrl: university.logoUrl,
              fit: BoxFit.contain,
              errorWidget: (_, __, ___) => const Icon(
                Icons.school_rounded,
                color: AppColors.gray400,
              ),
            ),
          ),
      ],
    );
  }

  String _location(University u) {
    if (u.stateProvince.isNotEmpty) {
      return '${u.stateProvince}, ${u.country}';
    }
    return u.country;
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.university});
  final University university;

  @override
  Widget build(BuildContext context) {
    final List<_DetailRow> rows = <_DetailRow>[
      _DetailRow('Country', university.country),
      if (university.stateProvince.isNotEmpty)
        _DetailRow('State / region', university.stateProvince),
      if (university.domain.isNotEmpty) _DetailRow('Domain', university.domain),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        children: <Widget>[
          for (int i = 0; i < rows.length; i++) ...<Widget>[
            if (i > 0) const Divider(height: 18, color: AppColors.gray100),
            _Row(label: rows[i].label, value: rows[i].value),
          ],
        ],
      ),
    );
  }
}

class _DetailRow {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyM.copyWith(color: AppColors.gray700),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            style: AppTypography.bodyL.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _LinkCard extends StatelessWidget {
  const _LinkCard({required this.title, required this.url});
  final String title;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: () => _open(context, url),
        onLongPress: () => _copy(context, url),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.brand100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.language_rounded,
                  color: AppColors.brand,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: AppTypography.bodyM.copyWith(
                        color: AppColors.gray700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      url,
                      style: AppTypography.bodyL.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
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

Future<void> _open(BuildContext context, String url) =>
    UrlOpener.open(context, url);

Future<void> _copy(BuildContext context, String url) =>
    UrlOpener.copy(context, url);

class _AiInsightsSection extends StatelessWidget {
  const _AiInsightsSection({required this.university});
  final University university;

  @override
  Widget build(BuildContext context) {
    final UniversitiesRepository repo = sl<UniversitiesRepository>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              'Requirements',
              style: AppTypography.h2.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 10),
            const _AiChip(),
          ],
        ),
        const SizedBox(height: 14),
        if (!repo.aiEnabled)
          _AiKeyMissingHint()
        else
          FutureBuilder<UniversityInsights?>(
            future: repo.insights(university.id),
            builder: (BuildContext c, AsyncSnapshot<UniversityInsights?> snap) {
              final bool loading =
                  snap.connectionState == ConnectionState.waiting;
              final UniversityInsights? data = snap.data;
              if (loading) return const _RequirementsSkeleton();
              if (data == null) {
                return const _MutedNotice(
                  text:
                      'Could not fetch AI insights right now. Pull to refresh later.',
                );
              }
              return _RequirementsView(insights: data);
            },
          ),
      ],
    );
  }
}

class _AiChip extends StatelessWidget {
  const _AiChip();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.brand100,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.brand200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.auto_awesome_rounded,
            size: 13,
            color: AppColors.brand,
          ),
          const SizedBox(width: 4),
          Text(
            'AI',
            style: AppTypography.micro.copyWith(
              color: AppColors.brand,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiKeyMissingHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.gray500,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'AI requirements disabled. Run the app with '
              '--dart-define=GEMINI_API_KEY=YOUR_KEY to enable them.',
              style: AppTypography.bodyM.copyWith(color: AppColors.gray700),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequirementsView extends StatelessWidget {
  const _RequirementsView({required this.insights});
  final UniversityInsights insights;

  @override
  Widget build(BuildContext context) {
    final Prefs prefs = sl<Prefs>();
    final double? langScore = prefs.getDouble(Prefs.kLanguageScore);
    final bool langIsSat = langScore != null && langScore >= 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _StatCard(
                icon: Icons.public_rounded,
                iconBg: AppColors.success100,
                iconColor: AppColors.success,
                chipText: insights.acceptsInternational ? 'Accepted' : 'Closed',
                chipBg: insights.acceptsInternational
                    ? AppColors.success100
                    : AppColors.gray100,
                chipFg: insights.acceptsInternational
                    ? AppColors.success700
                    : AppColors.gray700,
                label: 'Foreign students',
                value: insights.acceptsInternational ? 'Yes' : 'No',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.star_outline_rounded,
                iconBg: AppColors.gray100,
                iconColor: AppColors.gray500,
                chipText: insights.scholarshipAvailable ? 'Award' : 'None',
                chipBg: AppColors.gray100,
                chipFg: AppColors.gray700,
                label: 'Scholarship',
                value: insights.scholarshipAvailable
                    ? (insights.scholarshipPercent > 0
                        ? 'Up to ${insights.scholarshipPercent}%'
                        : 'Available')
                    : 'Not offered',
              ),
            ),
          ],
        ),
        if (insights.minIelts > 0 ||
            insights.minToefl > 0 ||
            insights.minSat > 0) ...<Widget>[
          const SizedBox(height: 12),
          _TestsCard(
            ielts: insights.minIelts,
            toefl: insights.minToefl,
            sat: insights.minSat,
            userIelts: langIsSat ? null : langScore,
            userSat: langIsSat ? langScore : null,
          ),
        ],
        if (insights.scholarshipAvailable &&
            (insights.scholarshipName.isNotEmpty ||
                insights.notes.isNotEmpty)) ...<Widget>[
          const SizedBox(height: 12),
          _ScholarshipDetailCard(
            name: insights.scholarshipName,
            description: insights.notes,
            percent: insights.scholarshipPercent,
          ),
        ],
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(
              Icons.info_outline_rounded,
              size: 14,
              color: AppColors.gray400,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Estimates by AI — verify on the official website before applying.',
                style: AppTypography.caption.copyWith(color: AppColors.gray500),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.chipText,
    required this.chipBg,
    required this.chipFg,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String chipText;
  final Color chipBg;
  final Color chipFg;
  final String label;
  final String value;

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
          Row(
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  chipText,
                  style: AppTypography.micro.copyWith(
                    color: chipFg,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: AppTypography.caption.copyWith(color: AppColors.gray500),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.h2.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _TestsCard extends StatelessWidget {
  const _TestsCard({
    required this.ielts,
    required this.toefl,
    required this.sat,
    required this.userIelts,
    required this.userSat,
  });
  final double ielts;
  final int toefl;
  final int sat;
  final double? userIelts;
  final double? userSat;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[];
    if (ielts > 0) {
      rows.add(
        _TestRow(
          tag: 'IELTS',
          label: 'Overall / Band',
          required: ielts,
          user: userIelts,
          scaleMin: 0,
          scaleMax: 9,
          format: (double v) => v.toStringAsFixed(1),
        ),
      );
    }
    if (toefl > 0) {
      if (rows.isNotEmpty) rows.add(const _TestDivider());
      rows.add(
        _TestRow(
          tag: 'TOEFL iBT',
          label: 'Minimum score',
          required: toefl.toDouble(),
          user: null,
          scaleMin: 0,
          scaleMax: 120,
          format: (double v) => v.toInt().toString(),
        ),
      );
    }
    if (sat > 0) {
      if (rows.isNotEmpty) rows.add(const _TestDivider());
      rows.add(
        _TestRow(
          tag: 'SAT',
          label: 'Minimum score',
          required: sat.toDouble(),
          user: userSat,
          scaleMin: 400,
          scaleMax: 1600,
          format: (double v) => v.toInt().toString(),
        ),
      );
    }
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
          Row(
            children: <Widget>[
              const Icon(
                Icons.assignment_outlined,
                size: 18,
                color: AppColors.ink,
              ),
              const SizedBox(width: 8),
              Text(
                'Language & admission tests',
                style: AppTypography.bodyL.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...rows,
        ],
      ),
    );
  }
}

class _TestDivider extends StatelessWidget {
  const _TestDivider();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Divider(height: 1, color: AppColors.gray100),
    );
  }
}

class _TestRow extends StatelessWidget {
  const _TestRow({
    required this.tag,
    required this.label,
    required this.required,
    required this.user,
    required this.scaleMin,
    required this.scaleMax,
    required this.format,
  });
  final String tag;
  final String label;
  final double required;
  final double? user;
  final double scaleMin;
  final double scaleMax;
  final String Function(double) format;

  @override
  Widget build(BuildContext context) {
    final double barValue = user ?? required;
    final double pct = ((barValue - scaleMin) / (scaleMax - scaleMin))
        .clamp(0.0, 1.0)
        .toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tag,
                style: AppTypography.micro.copyWith(
                  color: AppColors.gray700,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyM.copyWith(color: AppColors.gray700),
              ),
            ),
            Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  TextSpan(
                    text: format(user ?? required),
                    style: AppTypography.h2.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      height: 1,
                    ),
                  ),
                  TextSpan(
                    text: user == null
                        ? ' / ${format(scaleMax)}'
                        : ' / ${format(required)}',
                    style: AppTypography.bodyL.copyWith(
                      color: AppColors.gray400,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: AppColors.gray100,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.ink),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              format(scaleMin),
              style: AppTypography.caption.copyWith(color: AppColors.gray500),
            ),
            Text(
              format(scaleMax),
              style: AppTypography.caption.copyWith(color: AppColors.gray500),
            ),
          ],
        ),
      ],
    );
  }
}

class _ScholarshipDetailCard extends StatelessWidget {
  const _ScholarshipDetailCard({
    required this.name,
    required this.description,
    required this.percent,
  });
  final String name;
  final String description;
  final int percent;

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
          Row(
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.brand100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.school_outlined,
                  color: AppColors.brand,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Scholarship details',
                  style: AppTypography.bodyL.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (percent > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success100,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Up to $percent%',
                    style: AppTypography.micro.copyWith(
                      color: AppColors.success700,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          if (name.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              name,
              style: AppTypography.bodyL.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
          if (description.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              description,
              style: AppTypography.bodyM.copyWith(
                color: AppColors.gray700,
                height: 20 / 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RequirementsSkeleton extends StatelessWidget {
  const _RequirementsSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget block({double height = 80}) => AppShimmer(
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: AppColors.gray200),
            ),
          ),
        );
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: block()),
            const SizedBox(width: 10),
            Expanded(child: block()),
          ],
        ),
        const SizedBox(height: 12),
        block(height: 180),
        const SizedBox(height: 12),
        block(height: 100),
      ],
    );
  }
}

class _UniversityDetailSkeleton extends StatelessWidget {
  const _UniversityDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: const <Widget>[
        AppShimmer(
          child: SizedBox(
            height: 220,
            child: ColoredBox(color: Colors.white),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AppShimmer(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          ShimmerBox(width: 120, height: 12),
                          SizedBox(height: 8),
                          ShimmerBox(height: 22),
                          SizedBox(height: 6),
                          ShimmerBox(width: 200, height: 22),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    ShimmerBox(width: 56, height: 56, radius: 12),
                  ],
                ),
              ),
              SizedBox(height: 22),
              _RequirementsSkeleton(),
            ],
          ),
        ),
      ],
    );
  }
}
