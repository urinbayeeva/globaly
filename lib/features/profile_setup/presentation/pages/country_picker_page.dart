import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/profile_setup_cubit.dart';
import '../widgets/country_tile.dart';

class CountryPickerPage extends StatelessWidget {
  const CountryPickerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileSetupCubit>(
      create: (_) => sl<ProfileSetupCubit>(),
      child: const _View(),
    );
  }
}

class _View extends StatefulWidget {
  const _View();
  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  final TextEditingController _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<ProfileSetupCubit, ProfileSetupState>(
          builder: (BuildContext c, ProfileSetupState s) {
            final ProfileSetupCubit cubit = c.read<ProfileSetupCubit>();
            return Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        T.of(context, 'country.title'),
                        style: AppTypography.display.copyWith(fontSize: 28),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        T.of(context, 'country.subtitle'),
                        style: AppTypography.bodyM
                            .copyWith(color: AppColors.gray500),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _q,
                        hint: T.of(context, 'country.search'),
                        prefixIcon: Icons.search_rounded,
                        onChanged: cubit.search,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (_) => false,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                      itemCount: s.filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, int i) {
                        final country = s.filtered[i];
                        return CountryTile(
                          country: country,
                          selected: s.selectedCountry?.code == country.code,
                          onTap: () => cubit.selectCountry(country),
                        );
                      },
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
          buildWhen: (a, b) => a.selectedCountry != b.selectedCountry,
          builder: (BuildContext bc, ProfileSetupState s) => AppButton(
            label: T.of(bc, 'common.continue'),
            onPressed: s.selectedCountry == null
                ? null
                : () => context.go(AppRoutes.purposePicker),
          ),
        ),
      ),
    );
  }
}
