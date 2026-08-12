import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_logo.dart';

/// HireGen AI brand mark for drawer / sidebar headers.
class HireGenBrandMark extends StatelessWidget {
  final String tagline;
  final double iconSize;
  final double titleSize;
  final bool forceLightText;
  final bool showIcon;

  const HireGenBrandMark({
    super.key,
    this.tagline = 'AI-Powered Interview Practice',
    this.iconSize = 36,
    this.titleSize = 20,
    this.forceLightText = true,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameColor = forceLightText
        ? Colors.white
        : (isDark ? Colors.white : AppColors.nearBlack);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (showIcon) ...[
              AppLogoImage(size: iconSize),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: RichText(
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'HireGen ',
                      style: TextStyle(
                        color: nameColor,
                        fontSize: titleSize,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    TextSpan(
                      text: 'AI',
                      style: TextStyle(
                        color: AppColors.brandPurple,
                        fontSize: titleSize,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (tagline.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            tagline,
            style: TextStyle(
              color: forceLightText
                  ? const Color(0xFF9CA3AF)
                  : (isDark ? const Color(0xFF9CA3AF) : AppColors.gray500),
              fontSize: 11,
              height: 1.2,
            ),
          ),
        ],
      ],
    );
  }
}
