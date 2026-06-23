import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/purpose.dart';
import '../bloc/profile_setup_cubit.dart';
import '../widgets/purpose_card.dart';

class PurposePickerPage extends StatelessWidget {
  const PurposePickerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileSetupCubit>(
      create: (_) => sl<ProfileSetupCubit>(),
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<ProfileSetupCubit, ProfileSetupState>(
          builder: (BuildContext c, ProfileSetupState s) {
            final ProfileSetupCubit cubit = c.read<ProfileSetupCubit>();
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
              children: <Widget>[
                Text(
                  T.of(context, 'purpose.title'),
                  style: AppTypography.display.copyWith(fontSize: 28),
                ),
                const SizedBox(height: 6),
                Text(
                  T.of(context, 'purpose.subtitle'),
                  style: AppTypography.bodyM.copyWith(color: AppColors.gray500),
                ),
                const SizedBox(height: 22),
                ...Purpose.values.map(
                  (Purpose p) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: PurposeCard(
                      purpose: p,
                      selected: s.selectedPurpose == p,
                      onTap: () => cubit.selectPurpose(p),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: BlocBuilder<ProfileSetupCubit, ProfileSetupState>(
          buildWhen: (a, b) => a.selectedPurpose != b.selectedPurpose,
          builder: (BuildContext bc, ProfileSetupState s) => AppButton(
            label: T.of(bc, 'purpose.startJourney'),
            onPressed: s.selectedPurpose == null
                ? null
                : () => context.go(AppRoutes.home),
          ),
        ),
      ),
    );
  }
}
