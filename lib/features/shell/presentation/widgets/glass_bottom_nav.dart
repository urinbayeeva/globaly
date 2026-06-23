import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_panel.dart';

class NavItem {
  const NavItem({required this.icon, required this.label, required this.path});

  final IconData icon;
  final String label;
  final String path;
}

class GlassBottomNav extends StatelessWidget {
  const GlassBottomNav({
    super.key,
    required this.items,
    required this.currentPath,
    required this.onTap,
  });

  final List<NavItem> items;
  final String currentPath;
  final ValueChanged<NavItem> onTap;

  static const double _height = 70;
  static const double _sideMargin = 12;
  static const double _gap = 10;
  static const double _opacity = 0.88;

  bool _isActive(String path) =>
      currentPath == path || currentPath.startsWith('$path/');

  @override
  Widget build(BuildContext context) {
    final bool hasTrailing = items.length > 1;
    final List<NavItem> primary =
        hasTrailing ? items.sublist(0, items.length - 1) : items;

    return Padding(
      padding: const EdgeInsets.fromLTRB(_sideMargin, 0, _sideMargin, 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: GlassPanel(
              borderRadius: 30,
              opacity: _opacity,
              child: SizedBox(
                height: _height,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: <Widget>[
                      for (final NavItem item in primary)
                        Expanded(
                          child: _NavTab(
                            item: item,
                            active: _isActive(item.path),
                            onTap: () => onTap(item),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (hasTrailing) ...<Widget>[
            const SizedBox(width: _gap),
            GlassPanel(
              borderRadius: _height / 2,
              opacity: _opacity,
              child: _DetachedTab(
                item: items.last,
                active: _isActive(items.last.path),
                onTap: () => onTap(items.last),
                size: _height,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final NavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color foreground = active ? AppColors.brand : AppColors.ink;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: active ? AppColors.brand100 : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(item.icon, size: 23, color: foreground),
            const SizedBox(height: 4),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.micro.copyWith(
                color: foreground,
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetachedTab extends StatelessWidget {
  const _DetachedTab({
    required this.item,
    required this.active,
    required this.onTap,
    required this.size,
  });

  final NavItem item;
  final bool active;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox.square(
        dimension: size,
        child: Center(
          child: AnimatedScale(
            scale: active ? 1.1 : 1,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: Icon(
              item.icon,
              size: 25,
              color: active ? AppColors.brand : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
