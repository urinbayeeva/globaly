import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/home_snapshot.dart';

class HomeGreetingHeader extends StatelessWidget {
  const HomeGreetingHeader({super.key, required this.snapshot});
  final HomeSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: const BoxDecoration(gradient: AppColors.brandWash),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      snapshot.userName.isEmpty
                          ? snapshot.greeting
                          : '${snapshot.greeting},',
                      style: AppTypography.bodyM
                          .copyWith(color: AppColors.gray700, fontSize: 13),
                    ),
                    if (snapshot.userName.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        snapshot.userName,
                        style: AppTypography.h1.copyWith(fontSize: 22),
                      ),
                    ],
                  ],
                ),
              ),
              const _BellButton(),
            ],
          ),
          const SizedBox(height: 18),
          _DestinationCard(snapshot: snapshot),
        ],
      ),
    );
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton();

  Future<void> _onTap(BuildContext context) async {
    final NotificationService notifications = sl<NotificationService>();
    if (!notifications.enabled) {
      context.showSnack(T.of(context, 'notif.disabledHint'));
      return;
    }
    await notifications.requestPermission();
    await notifications.show(
      title: T.t('notif.reminderTitle'),
      body: T.t('notif.reminderBody'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _onTap(context),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x0A0D1424),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.ink,
              size: 20,
            ),
            Positioned(
              top: 9,
              right: 11,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.alert,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({required this.snapshot});
  final HomeSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(AppRoutes.countryPicker),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x0A0D1424),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              _FlagBadge(flag: snapshot.destinationFlag),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      T.of(context, 'greet.goingTo'),
                      style: AppTypography.micro.copyWith(
                        color: AppColors.gray500,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      snapshot.destinationLabel,
                      style: AppTypography.title.copyWith(fontSize: 15),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.gray400,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlagBadge extends StatelessWidget {
  const _FlagBadge({required this.flag});
  final String flag;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppColors.gray300),
      ),
      child: flag.isEmpty
          ? const Icon(
              Icons.public_rounded,
              size: 14,
              color: AppColors.gray500,
            )
          : Text(flag, style: const TextStyle(fontSize: 18)),
    );
  }
}
