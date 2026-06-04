import 'package:flutter/material.dart';

import '../models/power_up.dart';
import '../theme/app_images.dart';
import '../theme/game_colors.dart';

/// Shows a PNG art asset at [size], falling back to [fallback] (or nothing) if
/// the file isn't present yet. This lets us reference art paths before the
/// real files have been dropped into `assets/images/` without crashing.
class AppImage extends StatelessWidget {
  const AppImage(
    this.asset, {
    super.key,
    required this.size,
    this.fallback,
    this.fit = BoxFit.contain,
  });

  final String asset;
  final double size;
  final Widget? fallback;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    // Decode at ~3× the display size (cap for high-DPI screens) instead of the
    // source resolution, so a large PNG doesn't blow up memory for a tiny icon.
    // Only cacheWidth is set so the aspect ratio is preserved on decode.
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: fit,
      filterQuality: FilterQuality.medium,
      cacheWidth: (size * 3).round(),
      errorBuilder: (_, __, ___) =>
          fallback ?? SizedBox(width: size, height: size),
    );
  }
}

/// The glossy star-coin, with the original Flutter-drawn coin as a fallback.
class CoinIcon extends StatelessWidget {
  const CoinIcon({super.key, this.size = 22});
  final double size;

  @override
  Widget build(BuildContext context) {
    return AppImage(
      AppImages.coin,
      size: size,
      fallback: _DrawnCoin(size: size),
    );
  }
}

/// Full red heart (lives). Falls back to a Material heart.
class HeartIcon extends StatelessWidget {
  const HeartIcon({super.key, this.size = 20});
  final double size;

  @override
  Widget build(BuildContext context) {
    return AppImage(
      AppImages.heart,
      size: size,
      fallback: Icon(Icons.favorite_rounded,
          size: size, color: GameColors.heart),
    );
  }
}

/// Cracked heart (fail / out of lives). Falls back to a Material broken heart.
class HeartBrokenIcon extends StatelessWidget {
  const HeartBrokenIcon({super.key, this.size = 56});
  final double size;

  @override
  Widget build(BuildContext context) {
    return AppImage(
      AppImages.heartBroken,
      size: size,
      fallback: Icon(Icons.heart_broken_rounded,
          size: size, color: GameColors.heart),
    );
  }
}

/// Gold star ([filled]) or empty grey star. Falls back to a Material star.
class StarIcon extends StatelessWidget {
  const StarIcon({super.key, this.size = 18, this.filled = true});
  final double size;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return AppImage(
      filled ? AppImages.star : AppImages.starEmpty,
      size: size,
      fallback: Icon(
        Icons.star_rounded,
        size: size,
        color: filled ? GameColors.star : const Color(0xFFC9D4E4),
      ),
    );
  }
}

/// A power-up's 3D icon, falling back to the matching Material glyph + colour.
class PowerIcon extends StatelessWidget {
  const PowerIcon(this.power, {super.key, this.size = 22});
  final PowerUp power;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (String asset, IconData icon, Color color) = switch (power) {
      PowerUp.hint => (
          AppImages.powerHint,
          Icons.lightbulb_rounded,
          const Color(0xFFFFD23F)
        ),
      PowerUp.eraser => (
          AppImages.powerEraser,
          Icons.cleaning_services_rounded,
          const Color(0xFFFF7A7A)
        ),
      PowerUp.magic => (
          AppImages.powerMagic,
          Icons.auto_awesome_rounded,
          const Color(0xFF8E8EF6)
        ),
      PowerUp.undo => (
          AppImages.powerUndo,
          Icons.undo_rounded,
          const Color(0xFF36C58E)
        ),
    };
    return AppImage(
      asset,
      size: size,
      fallback: Icon(icon, size: size, color: color),
    );
  }
}

/// Vector fallback matching the gold star-coin until the PNG is added.
class _DrawnCoin extends StatelessWidget {
  const _DrawnCoin({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [GameColors.lighten(GameColors.coin, 0.12), GameColors.coin],
        ),
        border: Border.all(color: GameColors.coinDark, width: size * 0.07),
      ),
      child: Icon(Icons.star_rounded,
          size: size * 0.6, color: GameColors.coinDark),
    );
  }
}
