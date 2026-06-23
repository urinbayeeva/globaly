import 'dart:io';

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
import '../../../../core/widgets/section_label.dart';
import '../../domain/entities/translation_result.dart';
import '../bloc/translator_cubit.dart';

class TranslatorPage extends StatelessWidget {
  const TranslatorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TranslatorCubit>(
      create: (_) => sl<TranslatorCubit>(),
      child: const _TranslatorView(),
    );
  }
}

class _TranslatorView extends StatelessWidget {
  const _TranslatorView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBg,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<TranslatorCubit, TranslatorState>(
          builder: (BuildContext c, TranslatorState s) {
            final TranslatorCubit cubit = c.read<TranslatorCubit>();
            final bool busy = s.status == TranslateStatus.translating;
            return ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: <Widget>[
                AppTopbar(
                  title: T.of(context, 'translator.title'),
                  subtitle: busy
                      ? T.of(context, 'translator.translating')
                      : T.of(context, 'translator.subtitle'),
                  leading: const _BackButton(),
                ),
                if (s.imagePath != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                    child: _Preview(path: s.imagePath!, busy: busy),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 6, 20, 0),
                    child: _EmptyHint(),
                  ),
                const SizedBox(height: 16),
                if (!busy && s.result == null)
                  _CaptureButtons(cubit: cubit)
                else if (s.result != null) ...<Widget>[
                  _ResultView(result: s.result!),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: AppButton(
                      label: T.of(context, 'translator.another'),
                      icon: Icons.refresh_rounded,
                      variant: AppButtonVariant.secondary,
                      onPressed: cubit.reset,
                    ),
                  ),
                ],
                if (s.message != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Text(
                      s.message!,
                      style: AppTypography.bodyM
                          .copyWith(color: AppColors.alert700),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CaptureButtons extends StatelessWidget {
  const _CaptureButtons({required this.cubit});
  final TranslatorCubit cubit;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: <Widget>[
          Expanded(
            child: AppButton(
              label: T.of(context, 'translator.camera'),
              icon: Icons.camera_alt_outlined,
              onPressed: cubit.capture,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AppButton(
              label: T.of(context, 'translator.gallery'),
              icon: Icons.photo_library_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: cubit.pickFromGallery,
            ),
          ),
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.path, required this.busy});
  final String path;
  final bool busy;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Stack(
        children: <Widget>[
          Image.file(
            File(path),
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
          ),
          if (busy)
            Positioned.fill(
              child: ColoredBox(
                color: const Color(0x99000000),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        T.of(context, 'translator.translating'),
                        style:
                            AppTypography.bodyM.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.brand100,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: <Widget>[
          const Icon(
            PhosphorIconsDuotone.translate,
            color: AppColors.brand,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            T.of(context, 'translator.hint'),
            textAlign: TextAlign.center,
            style: AppTypography.bodyL.copyWith(
              color: AppColors.gray700,
              height: 22 / 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.result});
  final TranslationResult result;

  @override
  Widget build(BuildContext context) {
    if (result.isUnreadable) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _Card(
          icon: Icons.info_outline_rounded,
          tint: AppColors.warning100,
          fg: AppColors.warning,
          child: Text(
            result.summary,
            style: AppTypography.bodyL
                .copyWith(color: AppColors.warning700, height: 22 / 14),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (result.detectedLanguage.isNotEmpty ||
            result.documentType.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: _MetaRow(result: result),
          ),
        if (result.summary.isNotEmpty) ...<Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _Card(
              icon: Icons.auto_awesome_rounded,
              tint: Colors.white,
              fg: AppColors.brand,
              child: Text(
                result.summary,
                style: AppTypography.bodyL
                    .copyWith(color: AppColors.gray800, height: 22 / 14),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: SectionLabel(T.of(context, 'translator.translation')),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _Card(
            icon: PhosphorIconsRegular.textAa,
            tint: Colors.white,
            fg: AppColors.gray700,
            child: SelectableText(
              result.translation,
              style: AppTypography.bodyL
                  .copyWith(color: AppColors.ink, height: 23 / 15),
            ),
          ),
        ),
        if (result.nextSteps.isNotEmpty) ...<Widget>[
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: SectionLabel(T.of(context, 'translator.nextSteps')),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _Card(
              icon: Icons.checklist_rounded,
              tint: AppColors.success100,
              fg: AppColors.success,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (int i = 0; i < result.nextSteps.length; i++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: i == result.nextSteps.length - 1 ? 0 : 8,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '${i + 1}.',
                            style: AppTypography.bodyL.copyWith(
                              color: AppColors.success700,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              result.nextSteps[i],
                              style: AppTypography.bodyL.copyWith(
                                color: AppColors.gray800,
                                height: 22 / 14,
                              ),
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
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.result});
  final TranslationResult result;
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        if (result.documentType.isNotEmpty && result.documentType != 'unknown')
          _Chip(
            icon: PhosphorIconsRegular.fileText,
            label: result.documentType,
          ),
        if (result.detectedLanguage.isNotEmpty)
          _Chip(
            icon: PhosphorIconsRegular.globe,
            label: T
                .of(context, 'translator.fromLang')
                .replaceAll('{0}', result.detectedLanguage),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.brand100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: AppColors.brand),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.brand700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.icon,
    required this.tint,
    required this.fg,
    required this.child,
  });
  final IconData icon;
  final Color tint;
  final Color fg;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final bool plain = tint == Colors.white;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: plain ? Colors.white : tint,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: plain ? AppColors.gray200 : tint,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: fg, size: 18),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
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
