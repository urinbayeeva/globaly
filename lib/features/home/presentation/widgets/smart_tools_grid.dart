import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/i18n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';

class _Tool {
  const _Tool(this.nameKey, this.icon, this.tint, this.fg, [this.route]);
  final String nameKey;
  final IconData icon;
  final Color tint;
  final Color fg;
  final String? route;
}

class SmartToolsGrid extends StatelessWidget {
  const SmartToolsGrid({super.key, required this.purposeCode});

  final String purposeCode;

  static const _Tool _costOfLiving = _Tool(
    'home.costOfLiving',
    PhosphorIconsDuotone.currencyDollar,
    AppColors.success100,
    AppColors.success,
    AppRoutes.costOfLiving,
  );
  static const _Tool _universityFinder = _Tool(
    'home.universityFinder',
    PhosphorIconsDuotone.graduationCap,
    AppColors.brand100,
    AppColors.brand,
    AppRoutes.score,
  );
  static const _Tool _translator = _Tool(
    'home.translator',
    PhosphorIconsDuotone.translate,
    AppColors.info100,
    AppColors.info,
    AppRoutes.translator,
  );
  static const _Tool _interview = _Tool(
    'home.interview',
    PhosphorIconsDuotone.userFocus,
    AppColors.warning100,
    AppColors.warning,
    AppRoutes.interview,
  );

  List<_Tool> _toolsFor(String purpose) {
    switch (purpose) {
      case 'study':
        return const <_Tool>[
          _costOfLiving,
          _universityFinder,
          _translator,
          _interview,
        ];
      case 'work':
      case 'tourism':
      case 'business':
      case 'family':
      default:
        return const <_Tool>[_costOfLiving, _translator, _interview];
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<_Tool> tools = _toolsFor(purposeCode);
    if (tools.length == 1) {
      return _WideTile(tool: tools.first);
    }
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: tools.map<Widget>((_Tool t) => _GridTile(tool: t)).toList(),
    );
  }
}

class _GridTile extends StatelessWidget {
  const _GridTile({required this.tool});
  final _Tool tool;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: tool.route == null ? null : () => context.push(tool.route!),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _IconBadge(tool: tool),
          const SizedBox(height: 10),
          Text(
            T.of(context, tool.nameKey),
            style: AppTypography.bodyL.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            T.of(context, 'home.openTool'),
            style: AppTypography.caption.copyWith(color: AppColors.gray500),
          ),
        ],
      ),
    );
  }
}

class _WideTile extends StatelessWidget {
  const _WideTile({required this.tool});
  final _Tool tool;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: tool.route == null ? null : () => context.push(tool.route!),
      child: Row(
        children: <Widget>[
          _IconBadge(tool: tool),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  T.of(context, tool.nameKey),
                  style: AppTypography.bodyL.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  T.of(context, 'home.openTool'),
                  style:
                      AppTypography.caption.copyWith(color: AppColors.gray500),
                ),
              ],
            ),
          ),
          const Icon(
            PhosphorIconsRegular.caretRight,
            color: AppColors.gray400,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.tool});
  final _Tool tool;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: tool.tint,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Icon(tool.icon, color: tool.fg, size: 22),
    );
  }
}
