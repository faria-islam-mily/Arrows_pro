import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../state/app_scope.dart';
import '../theme/app_images.dart';
import '../theme/game_colors.dart';
import 'app_image.dart';

/// The top resource bar: avatar, coins (with a "+" on the coin), lives (number
/// inside the heart + regen timer), star total, and a settings gear. Big 3D
/// icons; the whole pill content is wrapped in a FittedBox so it can never
/// overflow on narrow screens.
class TopHud extends StatefulWidget {
  const TopHud({
    super.key,
    this.onCoins,
    this.onLives,
    this.onStars,
    this.onProfile,
    this.onSettings,
  });

  final VoidCallback? onCoins;
  final VoidCallback? onLives;
  final VoidCallback? onStars;
  final VoidCallback? onProfile;
  final VoidCallback? onSettings;

  @override
  State<TopHud> createState() => _TopHudState();
}

class _TopHudState extends State<TopHud> {
  Timer? _timer;
  static const double _icon = 46; // all HUD icons share one size — balanced

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      AppScope.read(context).tick();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.appState;

    final String lifeRight;
    if (state.hasInfiniteLives) {
      lifeRight = _fmt(state.infiniteRemaining ?? Duration.zero);
    } else {
      final t = state.timeToNextLife;
      lifeRight = t == null ? 'FULL' : _fmt(t);
    }
    final lifeLabel = state.hasInfiniteLives ? '∞' : '${state.lives}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
      child: Row(
        children: [
          _Avatar(onTap: widget.onProfile),
          const SizedBox(width: 5),
          // Coins: big coin with a "+" on it, count beside it.
          Expanded(
            flex: 5,
            child: _HudPill(
              leading: const _CoinWithPlus(size: _icon),
              label: '${state.coins}',
              onTap: widget.onCoins,
            ),
          ),
          const SizedBox(width: 5),
          // Lives: number INSIDE the heart, regen status beside it.
          Expanded(
            flex: 6,
            child: _HudPill(
              leading: _HeartWithNumber(size: _icon, number: lifeLabel),
              trailing: lifeRight,
              onTap: widget.onLives,
            ),
          ),
          const SizedBox(width: 5),
          // Stars: big star, count beside it.
          Expanded(
            flex: 4,
            child: _HudPill(
              leading: const StarIcon(size: _icon),
              label: '${state.starTotal}',
              onTap: widget.onStars,
            ),
          ),
          const SizedBox(width: 5),
          _GearButton(onTap: widget.onSettings),
        ],
      ),
    );
  }
}

/// A dark chunky pill: a big 3D icon on the left, then an animated count and/or
/// a trailing status string. The whole content is in a FittedBox so it scales
/// down rather than overflowing when space is tight.
class _HudPill extends StatelessWidget {
  const _HudPill({
    required this.leading,
    this.label,
    this.trailing,
    this.onTap,
  });

  final Widget leading;
  final String? label;
  final String? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 52,
        padding: const EdgeInsets.only(left: 3, right: 10),
        decoration: BoxDecoration(
          color: GameColors.hudPill,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: GameColors.hudPillBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              leading,
              if (label != null) ...[
                const SizedBox(width: 6),
                _BumpText(
                  label!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
                  ),
                ),
              ],
              if (trailing != null) ...[
                const SizedBox(width: 8),
                Text(
                  trailing!,
                  style: const TextStyle(
                    color: Color(0xFFAEB9D4),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A big coin with a small green "+" badge on its lower-right.
class _CoinWithPlus extends StatelessWidget {
  const _CoinWithPlus({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    final badge = size * 0.5;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CoinIcon(size: size),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: badge,
              height: badge,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF6FD63B), GameColors.green],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(Icons.add_rounded,
                  color: Colors.white, size: badge * 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// A big heart with the life count drawn inside it.
class _HeartWithNumber extends StatelessWidget {
  const _HeartWithNumber({required this.size, required this.number});
  final double size;
  final String number;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          HeartIcon(size: size),
          // Nudge up slightly — a heart's visual mass sits above centre.
          Padding(
            padding: EdgeInsets.only(bottom: size * 0.08),
            child: _BumpText(
              number,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: size * 0.42,
                shadows: const [
                  Shadow(color: Color(0x99000000), blurRadius: 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Text that gives a quick scale "pop" whenever its value changes.
class _BumpText extends StatefulWidget {
  const _BumpText(this.text, {required this.style});
  final String text;
  final TextStyle style;

  @override
  State<_BumpText> createState() => _BumpTextState();
}

class _BumpTextState extends State<_BumpText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  @override
  void didUpdateWidget(_BumpText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final s = 1 + 0.35 * math.sin(_c.value * math.pi);
        return Transform.scale(scale: s, child: child);
      },
      child: Text(widget.text, style: widget.style),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFE082), Color(0xFFFFC02E)],
              ),
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const AppImage(
              AppImages.avatarPlayer,
              size: 42,
              fallback: Text('🐹', style: TextStyle(fontSize: 24)),
            ),
          ),
          Positioned(
            top: -3,
            right: -3,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: GameColors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GearButton extends StatelessWidget {
  const _GearButton({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: GameColors.hudPill,
          shape: BoxShape.circle,
          border: Border.all(color: GameColors.hudPillBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.settings_rounded, color: Colors.white, size: 24),
      ),
    );
  }
}
