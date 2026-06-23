import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/i18n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../widgets/glass_bottom_nav.dart';

class ShellPage extends StatelessWidget {
  const ShellPage({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final List<NavItem> items = <NavItem>[
      NavItem(
        icon: PhosphorIconsRegular.house,
        label: T.of(context, 'tab.home'),
        path: AppRoutes.home,
      ),
      NavItem(
        icon: PhosphorIconsRegular.path,
        label: T.of(context, 'tab.roadmap'),
        path: AppRoutes.roadmap,
      ),
      NavItem(
        icon: PhosphorIconsRegular.scan,
        label: T.of(context, 'tab.scan'),
        path: AppRoutes.scan,
      ),
      NavItem(
        icon: PhosphorIconsRegular.chatCircle,
        label: T.of(context, 'tab.chat'),
        path: AppRoutes.chat,
      ),
      NavItem(
        icon: PhosphorIconsRegular.user,
        label: T.of(context, 'tab.profile'),
        path: AppRoutes.profile,
      ),
    ];
    final String location = GoRouterState.of(context).matchedLocation;
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: <Widget>[
          Positioned.fill(child: child),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              bottom: false,
              child: GlassBottomNav(
                items: items,
                currentPath: location,
                onTap: (NavItem item) {
                  if (item.path != location) context.go(item.path);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
