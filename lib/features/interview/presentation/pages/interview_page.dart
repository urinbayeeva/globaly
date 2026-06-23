import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_topbar.dart';
import '../../data/services/visa_interview_service.dart';
import '../../domain/entities/interview_turn.dart';
import '../bloc/interview_cubit.dart';

class InterviewPage extends StatelessWidget {
  const InterviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InterviewCubit>(
      create: (_) => sl<InterviewCubit>(),
      child: const _InterviewView(),
    );
  }
}

class _InterviewView extends StatelessWidget {
  const _InterviewView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBg,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<InterviewCubit, InterviewState>(
          builder: (BuildContext c, InterviewState s) {
            final InterviewCubit cubit = c.read<InterviewCubit>();
            return Column(
              children: <Widget>[
                AppTopbar(
                  title: T.of(context, 'interview.title'),
                  subtitle: _subtitleFor(context, s),
                  leading: const _BackButton(),
                ),
                Expanded(child: _Body(state: s, cubit: cubit)),
                if (s.status == InterviewStatus.asking)
                  _AnswerBar(onSend: cubit.answer),
                const SizedBox(height: 8),
              ],
            );
          },
        ),
      ),
    );
  }

  String _subtitleFor(BuildContext context, InterviewState s) {
    switch (s.status) {
      case InterviewStatus.asking:
      case InterviewStatus.thinking:
        return T
            .of(context, 'interview.progress')
            .replaceAll('{0}', '${s.questionNumber}')
            .replaceAll('{1}', '${VisaInterviewService.kTargetQuestions}');
      case InterviewStatus.finished:
        return T.of(context, 'interview.done');
      case InterviewStatus.intro:
      case InterviewStatus.error:
        return T.of(context, 'interview.subtitle');
    }
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state, required this.cubit});
  final InterviewState state;
  final InterviewCubit cubit;

  @override
  Widget build(BuildContext context) {
    if (state.status == InterviewStatus.intro) {
      return _Intro(onStart: cubit.start);
    }
    if (state.status == InterviewStatus.error) {
      return _ErrorView(message: state.message, onRetry: cubit.start);
    }

    final bool thinking = state.status == InterviewStatus.thinking;
    final bool finished = state.status == InterviewStatus.finished;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: <Widget>[
        for (int i = 0; i < state.turns.length; i++)
          _TurnView(turn: state.turns[i], index: i + 1),
        if (thinking)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: _Thinking(),
          ),
        if (finished) ...<Widget>[
          const SizedBox(height: 8),
          _Verdict(state: state),
          const SizedBox(height: 16),
          AppButton(
            label: T.of(context, 'interview.restart'),
            icon: Icons.refresh_rounded,
            variant: AppButtonVariant.secondary,
            onPressed: cubit.start,
          ),
        ],
      ],
    );
  }
}

class _TurnView extends StatelessWidget {
  const _TurnView({required this.turn, required this.index});
  final InterviewTurn turn;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _Bubble(
          text: turn.question,
          me: false,
          label:
              T.of(context, 'interview.officerQ').replaceAll('{0}', '$index'),
        ),
        if (turn.isAnswered) ...<Widget>[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: _Bubble(text: turn.answer, me: true),
          ),
        ],
        if (turn.feedback.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          _FeedbackChip(text: turn.feedback),
        ],
        const SizedBox(height: 14),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.me, this.label});
  final String text;
  final bool me;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final double maxW = MediaQuery.sizeOf(context).width * 0.82;
    return Align(
      alignment: me ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: Column(
          crossAxisAlignment:
              me ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: <Widget>[
            if (label != null)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Text(
                  label!.toUpperCase(),
                  style: AppTypography.micro.copyWith(
                    color: AppColors.gray500,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: me ? AppColors.brand : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(me ? 18 : 6),
                  bottomRight: Radius.circular(me ? 6 : 18),
                ),
                border: me ? null : Border.all(color: AppColors.gray200),
              ),
              child: Text(
                text,
                style: AppTypography.bodyL.copyWith(
                  color: me ? Colors.white : AppColors.ink,
                  height: 21 / 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackChip extends StatelessWidget {
  const _FeedbackChip({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.brand100,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.lightbulb_outline_rounded,
            color: AppColors.brand,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyM.copyWith(
                color: AppColors.brand700,
                height: 19 / 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Thinking extends StatelessWidget {
  const _Thinking();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.brand,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          T.of(context, 'interview.thinking'),
          style: AppTypography.bodyM.copyWith(color: AppColors.gray500),
        ),
      ],
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.onStart});
  final VoidCallback onStart;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppColors.brand100,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              PhosphorIconsDuotone.userFocus,
              color: AppColors.brand,
              size: 44,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            T.of(context, 'interview.introTitle'),
            textAlign: TextAlign.center,
            style: AppTypography.h2.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            T.of(context, 'interview.introBody'),
            textAlign: TextAlign.center,
            style: AppTypography.bodyL.copyWith(
              color: AppColors.gray700,
              height: 23 / 15,
            ),
          ),
          const SizedBox(height: 28),
          AppButton(
            label: T.of(context, 'interview.start'),
            icon: Icons.play_arrow_rounded,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}

class _Verdict extends StatelessWidget {
  const _Verdict({required this.state});
  final InterviewState state;

  Color get _tone {
    if (state.score >= 75) return AppColors.success;
    if (state.score >= 50) return AppColors.warning;
    return AppColors.alert;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
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
              _ScoreDial(score: state.score, tone: _tone),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      T.of(context, 'interview.readiness'),
                      style: AppTypography.micro.copyWith(
                        color: AppColors.gray500,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.assessment,
                      style: AppTypography.bodyL.copyWith(
                        color: AppColors.gray800,
                        height: 21 / 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (state.tips.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            Text(
              T.of(context, 'interview.tips').toUpperCase(),
              style: AppTypography.micro.copyWith(
                color: AppColors.gray500,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 8),
            for (final String tip in state.tips)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppColors.success,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tip,
                        style: AppTypography.bodyL.copyWith(
                          color: AppColors.gray800,
                          height: 21 / 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ScoreDial extends StatelessWidget {
  const _ScoreDial({required this.score, required this.tone});
  final int score;
  final Color tone;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: tone, width: 2),
      ),
      child: Center(
        child: Text(
          '$score',
          style: AppTypography.h2.copyWith(
            color: tone,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String? message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.alert,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            message ?? T.of(context, 'interview.error'),
            textAlign: TextAlign.center,
            style: AppTypography.bodyL.copyWith(color: AppColors.gray700),
          ),
          const SizedBox(height: 20),
          AppButton(
            label: T.of(context, 'interview.start'),
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _AnswerBar extends StatefulWidget {
  const _AnswerBar({required this.onSend});
  final ValueChanged<String> onSend;
  @override
  State<_AnswerBar> createState() => _AnswerBarState();
}

class _AnswerBarState extends State<_AnswerBar> {
  final TextEditingController _c = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _c.addListener(() {
      final bool next = _c.text.trim().isNotEmpty;
      if (next != _hasText) setState(() => _hasText = next);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _send() {
    final String t = _c.text.trim();
    if (t.isEmpty) return;
    widget.onSend(t);
    _c.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.gray200),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x140D1424),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _c,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                style: AppTypography.bodyL.copyWith(
                  color: AppColors.ink,
                  height: 22 / 15,
                ),
                cursorColor: AppColors.brand,
                decoration: InputDecoration(
                  hintText: T.of(context, 'interview.answerHint'),
                  hintStyle:
                      AppTypography.bodyL.copyWith(color: AppColors.gray500),
                  filled: false,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: _hasText ? AppColors.brand : AppColors.gray200,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _hasText ? _send : null,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    color: _hasText ? Colors.white : AppColors.gray500,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();
  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.brand100,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.pop(),
        child: const SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            PhosphorIconsRegular.caretLeft,
            color: AppColors.brand,
            size: 18,
          ),
        ),
      ),
    );
  }
}
