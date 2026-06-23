import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';
import 'app_shimmer.dart';

class AsyncStateView<T> extends StatelessWidget {
  const AsyncStateView({
    super.key,
    required this.isLoading,
    required this.error,
    required this.isEmpty,
    required this.onRetry,
    required this.builder,
    this.emptyLabel = 'Nothing yet.',
    this.loadingHeight = 220,
    this.loadingPlaceholder,
  });

  final bool isLoading;
  final String? error;
  final bool isEmpty;
  final VoidCallback onRetry;
  final WidgetBuilder builder;
  final String emptyLabel;
  final double loadingHeight;
  final WidgetBuilder? loadingPlaceholder;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      if (loadingPlaceholder != null) return loadingPlaceholder!(context);
      return SizedBox(
        height: loadingHeight,
        child: ShimmerCard(height: loadingHeight),
      );
    }
    if (error != null) {
      return _ErrorBox(message: error!, onRetry: onRetry);
    }
    if (isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            emptyLabel,
            style: AppTypography.bodyM.copyWith(color: AppColors.gray500),
          ),
        ),
      );
    }
    return builder(context);
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: <Widget>[
          const Icon(Icons.error_outline, color: AppColors.alert, size: 40),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodyM.copyWith(color: AppColors.alert700),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Try again',
            variant: AppButtonVariant.secondary,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
