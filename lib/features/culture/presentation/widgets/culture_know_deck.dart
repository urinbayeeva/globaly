import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/i18n/app_strings.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/culture_briefing.dart';
import '../pages/culture_story_page.dart';
import 'culture_visuals.dart';

class CultureKnowDeck extends StatefulWidget {
  const CultureKnowDeck({
    super.key,
    required this.country,
    required this.sections,
  });

  final String country;
  final List<CultureSection> sections;

  @override
  State<CultureKnowDeck> createState() => _CultureKnowDeckState();
}

class _CultureKnowDeckState extends State<CultureKnowDeck>
    with SingleTickerProviderStateMixin {
  static const double _deckHeight = 480;
  static const double _maxBehind = 3;
  static const double _maxAhead = 2;
  static const double _stripGap = 16;
  static const double _peekGap = 30;
  static const double _activeTop = _maxBehind * _stripGap;
  static const double _cardHeight = _deckHeight - _activeTop - _peekGap * _maxAhead;
  static const double _insetPer = 7;
  static const double _dimPer = 0.08;

  late final PageController _controller =
      PageController(viewportFraction: 0.32);
  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _bounce.dispose();
    _controller.dispose();
    super.dispose();
  }

  double get _page {
    if (_controller.hasClients && _controller.position.haveDimensions) {
      return _controller.page ?? 0;
    }
    return 0;
  }

  void _openActive() {
    _open(_page.round().clamp(0, widget.sections.length - 1));
  }

  void _open(int index) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, __, ___) => CultureStoryPage(
          country: widget.country,
          section: widget.sections[index],
          index: index,
        ),
        transitionsBuilder:
            (_, Animation<double> animation, __, Widget child) =>
                FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _deckHeight,
      child: Stack(
        children: <Widget>[
          PageView.builder(
            controller: _controller,
            scrollDirection: Axis.vertical,
            itemCount: widget.sections.length,
            itemBuilder: (_, __) => const SizedBox.expand(),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (_, __) => _buildStack(),
              ),
            ),
          ),
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _openActive,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStack() {
    final double pg = _page;
    final int total = widget.sections.length;
    final List<int> order = <int>[];
    for (int i = 0; i < total; i++) {
      final double p = i - pg;
      if (p >= -_maxBehind - 1 && p <= _maxAhead + 1) order.add(i);
    }
    order.sort((int a, int b) => (b - pg).abs().compareTo((a - pg).abs()));
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        ...order.map((int i) => _card(i, pg)),
        _dots(pg, total),
        _hint(pg, total),
      ],
    );
  }

  Widget _card(int i, double pg) {
    final double p = i - pg;
    final double magnitude = p.abs().clamp(0.0, _maxBehind).toDouble();
    final double clamped = p.clamp(-_maxBehind, _maxAhead).toDouble();
    final double dy = clamped <= 0 ? _stripGap * clamped : _peekGap * clamped;
    final double inset = _insetPer * magnitude;

    double edgeFade = 1;
    if (p > _maxAhead) {
      edgeFade = (1 - (p - _maxAhead)).clamp(0.0, 1.0).toDouble();
    } else if (p < -_maxBehind) {
      edgeFade = (1 - (-p - _maxBehind)).clamp(0.0, 1.0).toDouble();
    }
    final double opacity =
        ((1 - _dimPer * magnitude) * edgeFade).clamp(0.0, 1.0).toDouble();

    return Positioned(
      top: _activeTop + dy,
      left: inset,
      right: inset,
      height: _cardHeight,
      child: Opacity(
        opacity: opacity,
        child: _DeckCard(
          country: widget.country,
          section: widget.sections[i],
          index: i,
        ),
      ),
    );
  }

  Widget _dots(double pg, int total) {
    if (total <= 1) return const SizedBox.shrink();
    final int active = pg.round().clamp(0, total - 1);
    return Positioned(
      right: 12,
      top: _activeTop,
      height: _cardHeight,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(total, (int i) {
            final bool on = i == active;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(vertical: 3),
              width: 5,
              height: on ? 20 : 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: on ? 0.95 : 0.4),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _hint(double pg, int total) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 12,
      child: IgnorePointer(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: total > 1 && pg < 0.08 ? 1 : 0,
          child: Center(
            child: AnimatedBuilder(
              animation: _bounce,
              builder: (_, Widget? child) => Transform.translate(
                offset: Offset(0, -5 * _bounce.value),
                child: child,
              ),
              child: _HintPill(text: T.of(context, 'culture.deckHint')),
            ),
          ),
        ),
      ),
    );
  }
}

class _HintPill extends StatelessWidget {
  const _HintPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.keyboard_arrow_up_rounded,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTypography.micro.copyWith(
              color: Colors.white,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeckCard extends StatelessWidget {
  const _DeckCard({
    required this.country,
    required this.section,
    required this.index,
  });

  final String country;
  final CultureSection section;
  final int index;

  @override
  Widget build(BuildContext context) {
    final CultureVisual visual = cultureVisual(section.title, index);
    final String url = cultureImageUrl(country, section.title);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.xxl),
        gradient: visual.gradient,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (url.isNotEmpty)
            CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 350),
              placeholder: (_, __) => const SizedBox.shrink(),
              errorWidget: (_, __, ___) => const SizedBox.shrink(),
            ),
          const _CardScrim(),
          Positioned(
            top: 18,
            right: 18,
            child: Icon(
              visual.icon,
              color: Colors.white.withValues(alpha: 0.26),
              size: 48,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _LabelChip(text: T.of(context, 'culture.knowLabel')),
                const Spacer(),
                Text(
                  section.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.h1.copyWith(
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.play_circle_fill_rounded,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 20,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      T
                          .of(context, 'culture.storyCount')
                          .replaceAll('{0}', '${section.tips.length}'),
                      style: AppTypography.bodyM.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LabelChip extends StatelessWidget {
  const _LabelChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.micro.copyWith(
          color: Colors.white,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _CardScrim extends StatelessWidget {
  const _CardScrim();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0x33000000),
            Color(0x00000000),
            Color(0xB3000000),
          ],
          stops: <double>[0.0, 0.4, 1.0],
        ),
      ),
    );
  }
}
