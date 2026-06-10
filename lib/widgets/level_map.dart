import 'package:flutter/material.dart';

import '../data/levels.dart';
import '../data/worlds.dart';
import '../l10n/strings.dart';
import '../screens/game_screen.dart';
import '../screens/piggy_bank_screen.dart';
import '../state/app_scope.dart';
import '../state/main_nav.dart';
import '../theme/app_images.dart';
import '../theme/game_colors.dart';
import 'app_image.dart';
import 'game_dialogs.dart';
import 'promo_dialogs.dart';
import 'reward_dialogs.dart';
import 'ui_kit.dart';

/// How often a star-gate sits on the path (every N levels).
const int kGateInterval = 15;

const double _kRowExtent = 132; // fixed height per level node row
const double _kLineWidth = 7;

void _toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ));
}

/// The full home map body: the scrolling level path, the fixed side rails, the
/// "Current Level" pill, and the selection-aware bottom button.
class HomeMap extends StatefulWidget {
  const HomeMap({super.key});

  @override
  State<HomeMap> createState() => _HomeMapState();
}

class _HomeMapState extends State<HomeMap> {
  final ScrollController _controller = ScrollController();
  bool _didCenter = false;
  double _viewportH = 0;
  int _bgBand = 0; // which world band's background is showing

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
    // Re-centre on the current level whenever the player returns to the Home tab.
    kMainTab.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    kMainTab.removeListener(_onTabChanged);
    _controller.dispose();
    super.dispose();
  }

  // Home is tab index 1. Coming back to it snaps the current level to centre
  // (the player can still scroll freely while on the tab).
  void _onTabChanged() {
    if (kMainTab.value != 1 || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollTo(_frontier);
    });
  }

  int get _frontier => AppScope.read(context).unlockedLevel.clamp(1, kLevelCount);

  void _centerOnCurrent(double viewportH) {
    _viewportH = viewportH;
    if (_didCenter || !_controller.hasClients) return;
    _didCenter = true;
    _bgBand = worldBand(_frontier);
    _scrollTo(_frontier);
  }

  // Track which world band is centred in view and crossfade its background.
  void _onScroll() {
    if (_viewportH == 0 || !_controller.hasClients) return;
    final centerFromBottom = _controller.offset + _viewportH / 2;
    final idx = ((centerFromBottom - 96) / _kRowExtent).floor();
    final level = (idx + 1).clamp(1, kLevelCount);
    final band = worldBand(level);
    if (band != _bgBand) setState(() => _bgBand = band);
  }

  // Reversed list (level 1 at the bottom): item i occupies [i*extent, ...] up.
  void _scrollTo(int level) {
    if (!_controller.hasClients) return;
    final i = (level - 1).clamp(0, kLevelCount - 1);
    final target = (i * _kRowExtent + _kRowExtent / 2 - _viewportH / 2)
        .clamp(0.0, _controller.position.maxScrollExtent);
    _controller.animateTo(target,
        duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
  }

  void _tapNode(int number) {
    final frontier = _frontier;
    if (number > frontier) {
      _toast(context, 'Complete level $frontier first!');
      return;
    }
    if (number == frontier) {
      // An unplayed level — show the start popup, then launch on PLAY.
      showLevelStart(
        context,
        level: kLevels[number - 1],
        arrowColor: context.palette.arrow,
        onPlay: () => _play(number),
      );
      return;
    }
    // A completed level — open its level dialog (replay options).
    showReplayLevel(
      context,
      level: number,
      stars: AppScope.read(context).starsFor(number),
      onReplay: () => _launch(number),
    );
  }

  void _play(int number) {
    final state = AppScope.read(context);
    if (number > state.unlockedLevel) return;
    if (!state.canPlay) {
      showOutOfLives(context);
      return;
    }
    _launch(number);
  }

  Future<void> _launch(int number) async {
    // GameScreen pops `true` from its "Next" button to chain to the next level.
    final goNext = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => GameScreen(level: kLevels[number - 1])),
    );
    if (!mounted) return;
    // Back on the map — re-centre on the (possibly advanced) current level, and
    // open the start popup for it when the player chose "Next".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollTo(_frontier);
      final f = _frontier;
      if (goNext == true && f >= 1 && f <= kLevels.length) {
        showLevelStart(
          context,
          level: kLevels[f - 1],
          arrowColor: context.palette.arrow,
          onPlay: () => _play(f),
        );
      }
    });
  }

  void _goToCurrent() => _scrollTo(_frontier);

  @override
  Widget build(BuildContext context) {
    final state = context.appState;
    final frontier = state.unlockedLevel.clamp(1, kLevelCount);

    return Stack(
      children: [
        // World background — crossfades as you scroll between worlds.
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            child: _WorldBackground(
              key: ValueKey(_bgBand % kWorlds.length),
              band: _bgBand,
            ),
          ),
        ),

        // The scrolling path.
        LayoutBuilder(
          builder: (context, constraints) {
            WidgetsBinding.instance.addPostFrameCallback(
                (_) => _centerOnCurrent(constraints.maxHeight));
            return ListView.builder(
              controller: _controller,
              reverse: true,
              itemExtent: _kRowExtent,
              padding: const EdgeInsets.only(top: 112, bottom: 96),
              itemCount: kLevelCount,
              itemBuilder: (context, i) {
                final number = i + 1;
                return _LevelRow(
                  number: number,
                  unlocked: frontier,
                  stars: state.starsFor(number),
                  starTotal: state.starTotal,
                  selected: false,
                  onTap: () => _tapNode(number),
                );
              },
            );
          },
        ),

        // Fixed rails — below the floating HUD.
        Positioned(
          left: 8,
          top: 104,
          child: _SideRail(adsRemoved: state.adsRemoved),
        ),
        Positioned(
          right: 8,
          top: 104,
          child: _WorldRail(unlocked: frontier),
        ),

        // Jump-to-current chevron — sits just above the right end of PLAY.
        Positioned(
          right: 22,
          bottom: 92,
          child: _JumpButton(onTap: _goToCurrent),
        ),

        // Bottom PLAY button — narrower, centred, and gently pulsing.
        Positioned(
          left: 0,
          right: 0,
          bottom: 16,
          child: Center(
            child: _PlayPulse(
              child: SizedBox(
                width: 200,
                child: _bottomButton(context, frontier),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bottomButton(BuildContext context, int frontier) {
    return _BottomButton(
      color: GameColors.green,
      topLabel: context.l10n.play,
      bottomLabel: '${context.l10n.level.toUpperCase()} $frontier',
      onTap: () => _play(frontier),
    );
  }
}

/// Small round "jump to current level" chevron near the PLAY button.
class _JumpButton extends StatelessWidget {
  const _JumpButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(Icons.keyboard_arrow_up_rounded,
            color: GameColors.blue, size: 32),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// One row of the path: connector line + node, plus optional gate / world marker.
// ---------------------------------------------------------------------------

class _LevelRow extends StatelessWidget {
  const _LevelRow({
    required this.number,
    required this.unlocked,
    required this.stars,
    required this.starTotal,
    required this.selected,
    required this.onTap,
  });

  final int number;
  final int unlocked;
  final int stars;
  final int starTotal;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final completed = number < unlocked;
    final isCurrent = number == unlocked;
    final hasGate = number % kGateInterval == 0;
    final gateReq = number;
    final gateOpen = starTotal >= gateReq;

    final lineColor =
        number <= unlocked ? GameColors.blue : GameColors.homeLine;

    return Stack(
      alignment: Alignment.center,
      children: [
        Center(child: Container(width: _kLineWidth, color: lineColor)),
        if (hasGate)
          Align(
            alignment: const Alignment(0, -0.78),
            child: _StarGate(required: gateReq, open: gateOpen),
          ),
        Align(
          alignment: const Alignment(0, 0.2),
          child: isCurrent
              ? _CurrentNode(number: number, onTap: onTap)
              : _Node(
                  number: number,
                  completed: completed,
                  stars: stars,
                  selected: selected,
                  onTap: onTap,
                ),
        ),
      ],
    );
  }
}

/// A completed (or locked) level node, with arced stars and a seated 3D plate.
class _Node extends StatelessWidget {
  const _Node({
    required this.number,
    required this.completed,
    required this.stars,
    required this.selected,
    required this.onTap,
  });

  final int number;
  final bool completed;
  final int stars;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Completed levels alternate green / orange for a lively path; selected ones
    // turn gold. Locked levels are grey.
    final Color face;
    if (!completed) {
      face = const Color(0xFFAEB9CC);
    } else if (selected) {
      face = GameColors.star;
    } else {
      face = number.isEven ? GameColors.green : const Color(0xFFF59E2E);
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (completed)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _ArcStars(stars: stars),
            )
          else
            const SizedBox(height: 22),
          _NodeCircle(face: face, selected: selected, label: '$number'),
        ],
      ),
    );
  }
}

class _NodeCircle extends StatelessWidget {
  const _NodeCircle({
    required this.face,
    required this.selected,
    required this.label,
    this.size = 60,
  });

  final Color face;
  final bool selected;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final circle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [GameColors.lighten(face), face],
        ),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(color: GameColors.darken(face), offset: const Offset(0, 4)),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 22,
        ),
      ),
    );

    if (!selected) return circle;
    // Selected: a glowing gold ring + a couple of sparkles.
    return SizedBox(
      width: size + 28,
      height: size + 18,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: size + 12,
            height: size + 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: GameColors.star, width: 3),
              boxShadow: [
                BoxShadow(
                    color: GameColors.star.withValues(alpha: 0.55),
                    blurRadius: 16),
              ],
            ),
          ),
          circle,
          const Positioned(
              right: 0, top: 4, child: _Sparkle(size: 12)),
          const Positioned(
              left: 2, bottom: 2, child: _Sparkle(size: 9)),
        ],
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.auto_awesome_rounded, color: GameColors.star, size: size);
  }
}

/// Three stars arced over a node (middle raised, sides tilted).
class _ArcStars extends StatelessWidget {
  const _ArcStars({required this.stars});
  final int stars;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Transform.rotate(
          angle: -0.35,
          child: StarIcon(size: 22, filled: stars >= 1),
        ),
        Transform.translate(
          offset: const Offset(0, -7),
          child: StarIcon(size: 27, filled: stars >= 2),
        ),
        Transform.rotate(
          angle: 0.35,
          child: StarIcon(size: 22, filled: stars >= 3),
        ),
      ],
    );
  }
}

/// The green, pulsing "play this now" node.
class _CurrentNode extends StatefulWidget {
  const _CurrentNode({required this.number, required this.onTap});
  final int number;
  final VoidCallback onTap;

  @override
  State<_CurrentNode> createState() => _CurrentNodeState();
}

class _CurrentNodeState extends State<_CurrentNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 18),
          AnimatedBuilder(
            animation: _c,
            builder: (context, child) =>
                Transform.scale(scale: 1.0 + _c.value * 0.08, child: child),
            child: _NodeCircle(
              face: GameColors.green,
              selected: true, // gold ring + sparkles mark the level to play
              label: '${widget.number}',
              size: 74,
            ),
          ),
        ],
      ),
    );
  }
}

class _StarGate extends StatelessWidget {
  const _StarGate({required this.required, required this.open});
  final int required;
  final bool open;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: open
              ? [GameColors.lighten(GameColors.star), GameColors.star]
              : [const Color(0xFFC4CEDD), const Color(0xFFA9B6C9)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(open ? Icons.star_rounded : Icons.lock_rounded,
              color: Colors.white, size: 18),
          const SizedBox(width: 4),
          Text(
            '$required',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom button + fixed rails.
// ---------------------------------------------------------------------------

class _BottomButton extends StatelessWidget {
  const _BottomButton({
    required this.color,
    required this.topLabel,
    required this.bottomLabel,
    required this.onTap,
  });

  final Color color;
  final String topLabel;
  final String bottomLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChunkyButton(
      color: color,
      depth: 6,
      radius: 18,
      padding: const EdgeInsets.symmetric(vertical: 9),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            topLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              shadows: [Shadow(color: Colors.black26, offset: Offset(0, 2))],
            ),
          ),
          Text(
            bottomLabel,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Gives the PLAY button a slow "breathing" pulse (scale + tiny bob) so it
/// always feels alive and invites a tap.
class _PlayPulse extends StatefulWidget {
  const _PlayPulse({required this.child});
  final Widget child;

  @override
  State<_PlayPulse> createState() => _PlayPulseState();
}

class _PlayPulseState extends State<_PlayPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

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
        final t = Curves.easeInOut.transform(_c.value);
        return Transform.translate(
          offset: Offset(0, -2 * t),
          child: Transform.scale(scale: 1 + 0.035 * t, child: child),
        );
      },
      child: widget.child,
    );
  }
}

class _SideRail extends StatelessWidget {
  const _SideRail({required this.adsRemoved});
  final bool adsRemoved;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RailButton(
          color: const Color(0xFFE85C9A),
          image: AppImages.piggyBank,
          label: context.l10n.piggy,
          // Only notify when there are coins ready to collect (breakable).
          badge: context.appState.canBreakPiggy,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PiggyBankScreen()),
          ),
        ),
        const SizedBox(height: 12),
        if (!adsRemoved) ...[
          _RailButton(
            color: GameColors.blue,
            image: AppImages.noAds,
            label: context.l10n.noAdsLabel,
            onTap: () => showRemoveAds(context),
          ),
          const SizedBox(height: 12),
        ],
        _RailButton(
          color: const Color(0xFFF2A33C),
          image: AppImages.offerSpecial,
          emoji: '🪙', // fallback if the art is missing
          label: context.l10n.sale,
          onTap: () => showSpecialOffer(context),
        ),
      ],
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.color,
    required this.label,
    required this.onTap,
    this.emoji,
    this.image,
    this.badge = false,
  });

  final Color color;
  final String label;
  final VoidCallback onTap;
  final String? emoji;
  final String? image;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 58,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [GameColors.lighten(color), color],
                    ),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: GameColors.darken(color),
                          offset: const Offset(0, 3)),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: image != null
                      ? ClipOval(
                          child: AppImage(
                            image!,
                            size: 48,
                            fit: BoxFit.cover,
                            fallback: emoji != null
                                ? Center(
                                    child: Text(emoji!,
                                        style: const TextStyle(fontSize: 38)))
                                : null,
                          ),
                        )
                      : Text(emoji ?? '',
                          style: const TextStyle(fontSize: 38)),
                ),
                if (badge)
                  Positioned(
                    top: -4,
                    right: -2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: GameColors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Center(
                        child: Text('!',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: GameColors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen world scene behind the path, with a soft scrim top & bottom so
/// the HUD and PLAY button stay readable.
class _WorldBackground extends StatelessWidget {
  const _WorldBackground({super.key, required this.band});
  final int band;

  @override
  Widget build(BuildContext context) {
    final world = worldForBand(band);
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          world.background,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          cacheWidth: 800,
          errorBuilder: (_, __, ___) =>
              const ColoredBox(color: GameColors.homeBackground),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.16, 0.80, 1.0],
              colors: [
                Colors.black.withValues(alpha: 0.32),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withValues(alpha: 0.30),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The right rail of the next couple of upcoming worlds (a new one every 50
/// levels). Tapping one shows when it unlocks.
class _WorldRail extends StatelessWidget {
  const _WorldRail({required this.unlocked});
  final int unlocked;

  @override
  Widget build(BuildContext context) {
    final curBand = worldBand(unlocked);
    final bands = [curBand + 1, curBand + 2]
        .where((b) => bandStartLevel(b) <= kLevelCount)
        .toList();
    if (bands.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (final b in bands) ...[
          _WorldAvatar(world: worldForBand(b), unlockLevel: bandStartLevel(b)),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _WorldAvatar extends StatelessWidget {
  const _WorldAvatar({required this.world, required this.unlockLevel});
  final GameWorld world;
  final int unlockLevel;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _toast(
          context, 'Reach Level $unlockLevel to unlock ${world.name}'),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFC9D4E4),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: ClipOval(
              child: AppImage(
                world.avatar,
                size: 58,
                fit: BoxFit.cover,
                fallback: Text(world.emoji, style: const TextStyle(fontSize: 30)),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF9AA7BC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                'LVL$unlockLevel',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
