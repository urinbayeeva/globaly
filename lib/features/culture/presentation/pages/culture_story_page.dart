import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/i18n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/culture_briefing.dart';
import '../widgets/culture_visuals.dart';

class CultureStoryPage extends StatefulWidget {
  const CultureStoryPage({
    super.key,
    required this.country,
    required this.section,
    required this.index,
  });

  final String country;
  final CultureSection section;
  final int index;

  @override
  State<CultureStoryPage> createState() => _CultureStoryPageState();
}

class _CultureStoryPageState extends State<CultureStoryPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );
  int _slide = 0;

  List<CultureTip> get _tips => widget.section.tips;

  @override
  void initState() {
    super.initState();
    _progress.addStatusListener(_onStatus);
    if (_tips.isNotEmpty) _progress.forward();
  }

  @override
  void dispose() {
    _progress.removeStatusListener(_onStatus);
    _progress.dispose();
    super.dispose();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _next();
  }

  void _restart() => _progress
    ..reset()
    ..forward();

  void _next() {
    if (_slide < _tips.length - 1) {
      setState(() => _slide++);
      _restart();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _prev() {
    if (_slide > 0) setState(() => _slide--);
    _restart();
  }

  void _onTapUp(TapUpDetails details) {
    final double width = MediaQuery.of(context).size.width;
    if (details.globalPosition.dx < width * 0.32) {
      _prev();
    } else {
      _next();
    }
  }

  @override
  Widget build(BuildContext context) {
    final CultureVisual visual =
        cultureVisual(widget.section.title, widget.index);
    final String url = cultureImageUrl(widget.country, widget.section.title);
    final CultureTip? tip = _tips.isEmpty ? null : _tips[_slide];
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: _onTapUp,
        onLongPressStart: (_) => _progress.stop(),
        onLongPressEnd: (_) => _progress.forward(),
        onVerticalDragEnd: (DragEndDetails d) {
          if ((d.primaryVelocity ?? 0) > 220) Navigator.of(context).maybePop();
        },
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            DecoratedBox(decoration: BoxDecoration(gradient: visual.gradient)),
            if (url.isNotEmpty)
              CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 350),
                placeholder: (_, __) => const SizedBox.shrink(),
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            const _StoryScrim(),
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _Segments(
                      count: _tips.length,
                      current: _slide,
                      progress: _progress,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            T.of(context, 'culture.knowLabel').toUpperCase(),
                            style: AppTypography.micro.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).maybePop(),
                          behavior: HitTestBehavior.opaque,
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.section.title,
                      style: AppTypography.h1.copyWith(
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                    if (tip != null) ...<Widget>[
                      const SizedBox(height: 18),
                      _DoChip(isDo: tip.isDo),
                      const SizedBox(height: 16),
                      Text(
                        tip.text,
                        style: AppTypography.h3.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.white.withValues(alpha: 0.55),
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            T.of(context, 'culture.storyDismiss'),
                            style: AppTypography.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Segments extends StatelessWidget {
  const _Segments({
    required this.count,
    required this.current,
    required this.progress,
  });

  final int count;
  final int current;
  final AnimationController progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List<Widget>.generate(count, (int i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == count - 1 ? 0 : 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: 3,
                child: Stack(
                  children: <Widget>[
                    Container(color: Colors.white.withValues(alpha: 0.3)),
                    if (i < current)
                      Container(color: Colors.white)
                    else if (i == current)
                      AnimatedBuilder(
                        animation: progress,
                        builder: (_, __) => FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress.value,
                          child: Container(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _DoChip extends StatelessWidget {
  const _DoChip({required this.isDo});

  final bool isDo;

  @override
  Widget build(BuildContext context) {
    final Color tone = isDo ? AppColors.success : AppColors.alert;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            isDo ? Icons.check_rounded : Icons.close_rounded,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            T.of(context, isDo ? 'culture.do' : 'culture.avoid').toUpperCase(),
            style: AppTypography.micro.copyWith(
              color: Colors.white,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryScrim extends StatelessWidget {
  const _StoryScrim();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xCC000000),
            Color(0x59000000),
            Color(0xE6000000),
          ],
          stops: <double>[0.0, 0.45, 1.0],
        ),
      ),
    );
  }
}
