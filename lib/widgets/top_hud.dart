import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../state/app_scope.dart';
import '../theme/game_colors.dart';
import 'app_image.dart';
import 'profile_dialogs.dart';

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

class _TopHudState extends State<TopHud>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _shine;
  static const double _icon = 36; // all HUD icons share one size — balanced

  @override
  void initState() {
    super.initState();
    // Drives a slow glossy shine that sweeps across every pill.
    _shine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      AppScope.read(context).tick();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _shine.dispose();
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
    // Only invite "get more" when lives are actually regenerating — never on
    // full or infinite (timeToNextLife is null in both those cases).
    final showLivesPlus = state.timeToNextLife != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
      child: Row(
        children: [
          _TapScale(
            onTap: widget.onProfile,
            child: AvatarBadge(
              avatarIndex: state.avatarIndex,
              frameIndex: state.frameIndex,
              size: 46,
              showDot: true,
            ),
          ),
          const SizedBox(width: 5),
          // Coins: big coin with a "+" on it, count beside it.
          Expanded(
            flex: 5,
            child: _HudPill(
              shine: _shine,
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
              shine: _shine,
              leading: _HeartWithNumber(
                  size: _icon, number: lifeLabel, showPlus: showLivesPlus),
              trailing: lifeRight,
              onTap: widget.onLives,
            ),
          ),
          const SizedBox(width: 5),
          // Stars: big star, count beside it.
          Expanded(
            flex: 4,
            child: _HudPill(
              shine: _shine,
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

/// The bright HUD accent blue — ties the pills into the glossy, white-bordered
/// button family used by the side rail (PIGGY / NO ADS / SALE) and the nav bar.
const Color _hudBlue = Color(0xFF3F8DEC);

/// The shared glossy surface: a vertical blue gradient, a crisp white border, a
/// chunky bottom lip + soft ambient shadow, and a sweeping shine — clipped to
/// [radius] (use a circular radius for the gear).
Widget _glossBase({
  required BorderRadius radius,
  required Animation<double> animation,
}) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: radius,
      boxShadow: [
        // Chunky bottom lip (like the rail buttons).
        BoxShadow(color: GameColors.darken(_hudBlue, 0.22), offset: const Offset(0, 3)),
        // Soft ambient shadow.
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 7,
            offset: const Offset(0, 3)),
      ],
    ),
    child: ClipRRect(
      borderRadius: radius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [GameColors.lighten(_hudBlue, 0.12), _hudBlue],
              ),
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: radius,
            ),
          ),
          _Shimmer(animation: animation),
        ],
      ),
    ),
  );
}

/// A glossy blue pill: a big 3D icon on the left, then an animated count and/or
/// a trailing status string. The content is in a FittedBox so it scales down
/// rather than overflowing when space is tight. The shine + border come from
/// the shared [_glossBase]; the icon may overhang it without being clipped.
class _HudPill extends StatelessWidget {
  const _HudPill({
    required this.leading,
    required this.shine,
    this.label,
    this.trailing,
    this.onTap,
  });

  final Widget leading;
  final Animation<double> shine;
  final String? label;
  final String? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _TapScale(
      onTap: onTap,
      child: SizedBox(
        height: 46,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.centerLeft,
          children: [
            Positioned.fill(
              child: _glossBase(
                radius: BorderRadius.circular(23),
                animation: shine,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 3, right: 12),
              // The 3D icon stays full-size; only the count text scales down so
              // a long number can never shrink the icon (keeps all icons equal).
              child: Row(
                children: [
                  leading,
                  const SizedBox(width: 6),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (label != null)
                            _BumpText(
                              label!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 19,
                                shadows: [
                                  Shadow(
                                      color: Color(0x55000000),
                                      offset: Offset(0, 1),
                                      blurRadius: 1),
                                ],
                              ),
                            ),
                          if (trailing != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              trailing!,
                              style: const TextStyle(
                                color: Color(0xFFE3EDFF),
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Press-down scale feedback shared by every interactive HUD element.
class _TapScale extends StatefulWidget {
  const _TapScale({required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> {
  bool _down = false;
  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled
          ? (_) {
              _set(false);
              widget.onTap!();
            }
          : null,
      onTapCancel: () => _set(false),
      child: AnimatedScale(
        scale: _down ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// A soft diagonal highlight that sweeps across a gloss surface, then rests for
/// the remainder of the cycle. Clipped by the surface's [ClipRRect].
class _Shimmer extends StatelessWidget {
  const _Shimmer({required this.animation});
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final v = animation.value;
          if (v >= 0.34) return const SizedBox.shrink();
          final t = v / 0.34; // 0..1 sweep, then idle
          return Align(
            alignment: Alignment(-1.6 + t * 3.2, 0),
            child: child,
          );
        },
        child: Transform.rotate(
          angle: -0.42,
          child: Container(
            width: 24,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.0),
                  Colors.white.withValues(alpha: 0.28),
                  Colors.white.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A small green "+" badge used on tappable resource icons (coins, lives).
class _PlusBadge extends StatelessWidget {
  const _PlusBadge({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6FD63B), GameColors.green],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Icon(Icons.add_rounded, color: Colors.white, size: size * 0.7),
    );
  }
}

/// A big coin with a small green "+" badge on its lower-right.
class _CoinWithPlus extends StatelessWidget {
  const _CoinWithPlus({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CoinIcon(size: size),
          const Positioned(
            right: -2,
            bottom: -2,
            child: _PlusBadge(size: 16),
          ),
        ],
      ),
    );
  }
}

/// A big heart with the life count drawn inside it and a green "+" badge — so,
/// like the coin, tapping it clearly leads somewhere to get more.
class _HeartWithNumber extends StatelessWidget {
  const _HeartWithNumber({
    required this.size,
    required this.number,
    this.showPlus = true,
  });
  final double size;
  final String number;
  final bool showPlus;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
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
          // Only when lives are regenerating (not full / infinite).
          if (showPlus)
            const Positioned(
              right: -2,
              bottom: -2,
              child: _PlusBadge(size: 16),
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

/// A bare settings gear — no background or border, just the icon (with a soft
/// shadow so it stays legible over the bright scene).
class _GearButton extends StatelessWidget {
  const _GearButton({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _TapScale(
      onTap: onTap,
      child: const SizedBox(
        width: 40,
        height: 46,
        child: Center(
          child: Icon(
            Icons.settings_rounded,
            color: Colors.white,
            size: 30,
            shadows: [
              Shadow(color: Color(0x80000000), blurRadius: 5, offset: Offset(0, 2)),
            ],
          ),
        ),
      ),
    );
  }
}
