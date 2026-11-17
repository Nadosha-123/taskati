import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

class FigmaBackground extends StatelessWidget {
  const FigmaBackground({
    required this.child,
    this.decorationTop = -14,
    this.decorationHeight = 839,
    super.key,
  });

  final Widget child;
  final double decorationTop;
  final double decorationHeight;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            left: -29,
            top: decorationTop,
            width: 451,
            height: decorationHeight,
            child: SvgPicture.asset(
              isDark
                  ? 'assets/vectors/decorations_dark.svg'
                  : 'assets/vectors/decorations_light.svg',
              fit: BoxFit.fill,
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}
