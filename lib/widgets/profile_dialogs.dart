import 'package:flutter/material.dart';

import '../data/profile_data.dart';
import '../l10n/strings.dart';
import '../state/app_scope.dart';
import '../theme/game_colors.dart';
import 'app_image.dart';
import 'ui_kit.dart';

/// The player's avatar in its chosen frame — used in the HUD and the profile
/// page. The avatar art fills the frame; emoji is the fallback.
class AvatarBadge extends StatelessWidget {
  const AvatarBadge({
    super.key,
    required this.avatarIndex,
    required this.frameIndex,
    this.size = 46,
    this.showDot = false,
  });

  final int avatarIndex;
  final int frameIndex;
  final double size;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final avatar = kAvatars[avatarIndex.clamp(0, kAvatars.length - 1)];
    final frame = kFrames[frameIndex.clamp(0, kFrames.length - 1)];
    final r = size * 0.3;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(r),
            color: frame.color,
            border: Border.all(color: Colors.white, width: size * 0.055),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.all(size * 0.06),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(r * 0.7),
            child: AppImage(
              avatar.asset,
              size: size,
              fit: BoxFit.cover,
              fallback: Center(
                child: Text(avatar.emoji,
                    style: TextStyle(fontSize: size * 0.5)),
              ),
            ),
          ),
        ),
        if (showDot)
          Positioned(
            top: -3,
            right: -3,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: GameColors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Username dialog (first run).
// ---------------------------------------------------------------------------

Future<void> showUsernameDialog(BuildContext context,
    {required VoidCallback onDone}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (ctx) => GameDialog(
      title: ctx.l10n.username,
      onClose: () => Navigator.of(ctx).pop(),
      child: _UsernameBody(onDone: () {
        Navigator.of(ctx).pop();
        onDone();
      }),
    ),
  );
}

class _UsernameBody extends StatefulWidget {
  const _UsernameBody({required this.onDone});
  final VoidCallback onDone;

  @override
  State<_UsernameBody> createState() => _UsernameBodyState();
}

class _UsernameBodyState extends State<_UsernameBody> {
  final _controller = TextEditingController();
  int _seed = 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _randomize() {
    _seed = (_seed * 7 + 13) % 100000;
    _controller.text = randomUsername(DateTime.now().millisecondsSinceEpoch + _seed);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final valid = _controller.text.trim().isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
          decoration: BoxDecoration(
            color: const Color(0xFFDDE7F4),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  onChanged: (_) => setState(() {}),
                  maxLength: 16,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(
                    color: GameColors.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    isDense: true,
                    hintText: context.l10n.yourName,
                  ),
                ),
              ),
              ChunkyCircleButton(
                icon: Icons.casino_rounded,
                color: GameColors.green,
                size: 40,
                iconSize: 22,
                onTap: _randomize,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(context.l10n.createUsername,
            style: const TextStyle(
                color: GameColors.blue,
                fontWeight: FontWeight.w800,
                fontSize: 15)),
        const SizedBox(height: 16),
        SizedBox(
          width: 220,
          child: ChunkyButton(
            color: valid ? GameColors.green : const Color(0xFFB9C2D6),
            depth: 6,
            onTap: valid
                ? () {
                    AppScope.read(context).setUsername(_controller.text);
                    widget.onDone();
                  }
                : null,
            child: Text(context.l10n.continueWord.toUpperCase(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1)),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Profile dialog (avatar / frame / badge).
// ---------------------------------------------------------------------------

void showProfileDialog(BuildContext context, {VoidCallback? onDone}) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (ctx) => GameDialog(
      title: ctx.l10n.profile,
      maxWidth: 400,
      onClose: () => Navigator.of(ctx).pop(),
      child: _ProfileBody(onDone: () {
        Navigator.of(ctx).pop();
        onDone?.call();
      }),
    ),
  );
}

enum _Tab { avatar, frame, badge }

class _ProfileBody extends StatefulWidget {
  const _ProfileBody({required this.onDone});
  final VoidCallback onDone;

  @override
  State<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<_ProfileBody> {
  _Tab _tab = _Tab.avatar;

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(m), duration: const Duration(seconds: 2)),
      );

  @override
  Widget build(BuildContext context) {
    final state = context.appState;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar + name header.
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE9F0FA),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              AvatarBadge(
                avatarIndex: state.avatarIndex,
                frameIndex: state.frameIndex,
                size: 56,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDE7F4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          state.username,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: GameColors.ink,
                              fontWeight: FontWeight.w900,
                              fontSize: 17),
                        ),
                      ),
                      ChunkyCircleButton(
                        icon: Icons.edit_rounded,
                        color: GameColors.green,
                        size: 34,
                        iconSize: 18,
                        onTap: () => showUsernameDialog(context, onDone: () {}),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Tabs(tab: _tab, onTab: (t) => setState(() => _tab = t)),
        const SizedBox(height: 12),
        SizedBox(height: 230, child: _tabContent(state)),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ChunkyButton(
            color: GameColors.green,
            depth: 6,
            onTap: widget.onDone,
            child: Text(context.l10n.continueWord.toUpperCase(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1)),
          ),
        ),
      ],
    );
  }

  Widget _tabContent(state) {
    switch (_tab) {
      case _Tab.avatar:
        return GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            for (var i = 0; i < kAvatars.length; i++)
              _AvatarTile(
                index: i,
                selected: state.avatarIndex == i,
                onTap: () => state.setAvatar(i),
              ),
          ],
        );
      case _Tab.frame:
        return GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            for (var i = 0; i < kFrames.length; i++)
              _FrameTile(
                index: i,
                selected: state.frameIndex == i,
                onTap: () {
                  if (kFrames[i].unlocked) {
                    state.setFrame(i);
                  } else {
                    _toast(context.l10n.unlockFrameLater);
                  }
                },
              ),
          ],
        );
      case _Tab.badge:
        return Center(
          child: Text(context.l10n.comingSoon,
              style: const TextStyle(
                  color: GameColors.inkMuted,
                  fontSize: 20,
                  fontWeight: FontWeight.w900)),
        );
    }
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.tab, required this.onTab});
  final _Tab tab;
  final ValueChanged<_Tab> onTab;

  @override
  Widget build(BuildContext context) {
    Widget seg(String label, _Tab t) => Expanded(
          child: GestureDetector(
            onTap: () => onTab(t),
            behavior: HitTestBehavior.opaque,
            child: Container(
              margin: const EdgeInsets.all(3),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: tab == t ? GameColors.green : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15)),
            ),
          ),
        );
    return Container(
      decoration: BoxDecoration(
        color: GameColors.blue,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          seg(context.l10n.avatar, _Tab.avatar),
          seg(context.l10n.frame, _Tab.frame),
          seg(context.l10n.badge, _Tab.badge),
        ],
      ),
    );
  }
}

class _AvatarTile extends StatelessWidget {
  const _AvatarTile(
      {required this.index, required this.selected, required this.onTap});
  final int index;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final avatar = kAvatars[index];
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFCBD8EC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? GameColors.green : Colors.white,
                width: 3,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: AppImage(
              avatar.asset,
              size: 90,
              fit: BoxFit.cover,
              fallback: Center(
                  child: Text(avatar.emoji, style: const TextStyle(fontSize: 36))),
            ),
          ),
          if (selected)
            const Positioned(
              right: 2,
              bottom: 2,
              child: CircleAvatar(
                radius: 11,
                backgroundColor: GameColors.green,
                child: Icon(Icons.check_rounded, color: Colors.white, size: 16),
              ),
            ),
        ],
      ),
    );
  }
}

class _FrameTile extends StatelessWidget {
  const _FrameTile(
      {required this.index, required this.selected, required this.onTap});
  final int index;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final frame = kFrames[index];
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: frame.color,
              border: Border.all(
                color: selected ? GameColors.green : Colors.white,
                width: 3,
              ),
            ),
            padding: const EdgeInsets.all(10),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF3E7BE8),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: frame.unlocked
                  ? null
                  : const Icon(Icons.lock_rounded,
                      color: Color(0xFFFFC02E), size: 26),
            ),
          ),
          if (selected)
            const Positioned(
              right: 2,
              bottom: 2,
              child: CircleAvatar(
                radius: 11,
                backgroundColor: GameColors.green,
                child: Icon(Icons.check_rounded, color: Colors.white, size: 16),
              ),
            ),
        ],
      ),
    );
  }
}
