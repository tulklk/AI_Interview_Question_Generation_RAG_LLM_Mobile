import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';

class AppLoadingShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const AppLoadingShimmer({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1F2740) : AppColors.gray100,
      highlightColor: isDark ? const Color(0xFF2D3562) : AppColors.offWhite,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2740) : AppColors.gray100,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class AppCardShimmer extends StatelessWidget {
  const AppCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppLoadingShimmer(width: 44, height: 44, borderRadius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    AppLoadingShimmer(height: 14),
                    SizedBox(height: 6),
                    AppLoadingShimmer(width: 120, height: 12),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const AppLoadingShimmer(height: 12),
          const SizedBox(height: 8),
          const AppLoadingShimmer(width: 200, height: 12),
          const SizedBox(height: 16),
          Row(
            children: const [
              AppLoadingShimmer(width: 64, height: 24, borderRadius: 8),
              SizedBox(width: 8),
              AppLoadingShimmer(width: 64, height: 24, borderRadius: 8),
              SizedBox(width: 8),
              AppLoadingShimmer(width: 64, height: 24, borderRadius: 8),
            ],
          ),
        ],
      ),
    );
  }
}
