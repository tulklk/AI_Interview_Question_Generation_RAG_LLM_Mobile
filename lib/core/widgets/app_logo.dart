import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// App brand logo image from [AppConstants.logoAsset].
class AppLogoImage extends StatelessWidget {
  final double size;
  final List<BoxShadow>? boxShadow;

  const AppLogoImage({
    super.key,
    this.size = 72,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(boxShadow: boxShadow),
        child: Image.asset(
          AppConstants.logoAsset,
          width: size,
          height: size,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => Icon(
            Icons.image_not_supported_outlined,
            size: size * 0.5,
            color: Colors.redAccent,
          ),
        ),
      ),
    );
  }
}
