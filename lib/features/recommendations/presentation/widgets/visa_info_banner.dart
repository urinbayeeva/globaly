import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../core/storage/prefs.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../domain/entities/visa_info.dart';
import '../bloc/visa_info_cubit.dart';

class VisaInfoBanner extends StatelessWidget {
  const VisaInfoBanner({
    super.key,
    required this.country,
    required this.purposeCode,
  });

  final String country;
  final String purposeCode;

  @override
  Widget build(BuildContext context) {
    if (country.isEmpty) return const SizedBox.shrink();
    return BlocProvider<VisaInfoCubit>(
      create: (_) =>
          sl<VisaInfoCubit>()..load(country: country, purposeCode: purposeCode),
      child: BlocBuilder<VisaInfoCubit, VisaInfoState>(
        builder: (BuildContext c, VisaInfoState s) {
          if (s.loading) return const _Skeleton();
          if (s.info == null) {
            return _RetryCard(
              onRetry: () => c.read<VisaInfoCubit>().load(
                    country: country,
                    purposeCode: purposeCode,
                  ),
            );
          }
          return _Card(info: s.info!);
        },
      ),
    );
  }
}

class _RetryCard extends StatelessWidget {
  const _RetryCard({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        color: Colors.white,
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.gray500,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  T.of(context, 'visa.title'),
                  style: AppTypography.bodyL.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  T.of(context, 'common.aiUnavailable'),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.brand,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(T.of(context, 'common.retry')),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.info});
  final VisaInfo info;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        color: Colors.white,
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.brand100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.badge_outlined,
                  color: AppColors.brand,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            info.visaTypeName.isEmpty
                                ? T.of(context, 'visa.title')
                                : info.visaTypeName,
                            style: AppTypography.bodyL.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (info.visaTypeCode.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.brand100,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              info.visaTypeCode,
                              style: AppTypography.micro.copyWith(
                                color: AppColors.brand700,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (info.notes.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        info.notes,
                        style: AppTypography.caption
                            .copyWith(color: AppColors.gray500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              if (info.applicationFeeUsd > 0)
                Expanded(
                  child: _PriceStat(
                    label: T.of(context, 'visa.application'),
                    usd: info.applicationFeeUsd.toDouble(),
                  ),
                ),
              if (info.applicationFeeUsd > 0 && info.totalCostUsd > 0)
                const SizedBox(width: 10),
              if (info.totalCostUsd > 0)
                Expanded(
                  child: _PriceStat(
                    label: T.of(context, 'visa.totalEst'),
                    usd: info.totalCostUsd.toDouble(),
                  ),
                ),
              if ((info.applicationFeeUsd > 0 || info.totalCostUsd > 0) &&
                  info.processingWeeks > 0)
                const SizedBox(width: 10),
              if (info.processingWeeks > 0)
                Expanded(
                  child: _Stat(
                    label: T.of(context, 'visa.processing'),
                    value:
                        '${info.processingWeeks} ${T.of(context, 'visa.wks')}',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(
                Icons.auto_awesome_rounded,
                size: 12,
                color: AppColors.brand,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  T.of(context, 'common.estimates'),
                  style: AppTypography.caption
                      .copyWith(color: AppColors.gray500, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.appBg,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: AppTypography.micro.copyWith(
              color: AppColors.gray500,
              fontSize: 10,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.bodyL.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PriceStat extends StatelessWidget {
  const _PriceStat({required this.label, required this.usd});
  final String label;
  final double usd;

  @override
  Widget build(BuildContext context) {
    final CurrencyService fx = sl<CurrencyService>();
    final Prefs prefs = sl<Prefs>();
    final String destCode = prefs.getString(Prefs.kDestinationCountry) ?? '';
    final String originCode = prefs.getString(Prefs.kOriginCountry) ?? '';
    final String? destCcy = fx.currencyFor(destCode);
    final String? originCcy = fx.currencyFor(originCode);

    return FutureBuilder<List<double?>>(
      future: Future.wait<double?>(<Future<double?>>[
        destCcy == null ? Future<double?>.value() : fx.rate('USD', destCcy),
        originCcy == null ? Future<double?>.value() : fx.rate('USD', originCcy),
      ]),
      builder: (BuildContext c, AsyncSnapshot<List<double?>> snap) {
        final double? destRate =
            (snap.data != null && snap.data!.isNotEmpty) ? snap.data![0] : null;
        final double? originRate =
            (snap.data != null && snap.data!.length > 1) ? snap.data![1] : null;

        final String primary = (destCcy != null && destRate != null)
            ? fx.format(usd * destRate, destCcy)
            : fx.format(usd, 'USD');
        final String? secondary =
            (originCcy != null && originRate != null && originCcy != destCcy)
                ? fx.format(usd * originRate, originCcy)
                : null;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.appBg,
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: AppTypography.micro.copyWith(
                  color: AppColors.gray500,
                  fontSize: 10,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                primary,
                style: AppTypography.bodyL.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (secondary != null) ...<Widget>[
                const SizedBox(height: 1),
                Text(
                  '≈ $secondary',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.gray500,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        color: Colors.white,
        border: Border.all(color: AppColors.gray200),
      ),
      child: const AppShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                ShimmerBox(width: 36, height: 36, radius: 10),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      ShimmerBox(),
                      SizedBox(height: 6),
                      ShimmerBox(width: 140, height: 10),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(child: ShimmerBox(height: 42, radius: 10)),
                SizedBox(width: 10),
                Expanded(child: ShimmerBox(height: 42, radius: 10)),
                SizedBox(width: 10),
                Expanded(child: ShimmerBox(height: 42, radius: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
