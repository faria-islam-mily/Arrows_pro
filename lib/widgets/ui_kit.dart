import 'package:flutter/material.dart';

import '../theme/game_colors.dart';

/// A "juicy" casual-game button: a flat 3D slab with a darker bottom lip that
/// presses down when tapped. The whole app's primary buttons use this so the
/// feel is consistent with the reference design.
class ChunkyButton extends StatefulWidget {
  const ChunkyButton({
    super.key,
    required this.child,
    required this.color,
    this.onTap,
    this.depth = 6,
    this.radius = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.shadowColor,
    this.gradient = true,
    this.enabled = true,
  });

  final Widget child;
  final Color color;
  final VoidCallback? onTap;
  final double depth; // height of the 3D lip
  final double radius;
  final EdgeInsets padding;
  final Color? shadowColor;
  final bool gradient;
  final bool enabled;

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled && widget.onTap != null;
    final face = enabled ? widget.color : const Color(0xFFB9C2D6);
    final lip = widget.shadowColor ?? GameColors.darken(face);
    final r = BorderRadius.circular(widget.radius);

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
      child: Container(
        // The dark lip shows through this bottom padding.
        padding: EdgeInsets.only(bottom: widget.depth),
        decoration: BoxDecoration(color: lip, borderRadius: r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 70),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _down ? widget.depth : 0, 0),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.gradient ? null : face,
            gradient: widget.gradient
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [GameColors.lighten(face), face],
                  )
                : null,
            borderRadius: r,
          ),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// A round chunky icon button (used for the red close "X", + buttons, etc.).
class ChunkyCircleButton extends StatelessWidget {
  const ChunkyCircleButton({
    super.key,
    required this.icon,
    required this.color,
    this.onTap,
    this.size = 44,
    this.iconSize = 24,
    this.iconColor = Colors.white,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return ChunkyButton(
      onTap: onTap,
      color: color,
      depth: 4,
      radius: size,
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(icon, size: iconSize, color: iconColor),
      ),
    );
  }
}

/// The standard cartoon dialog frame: a coloured header bar with a centred
/// title, a white rounded body, and a floating red "X" close button. Pops in
/// with a spring. Use [showGameDialog] to present it.
class GameDialog extends StatelessWidget {
  const GameDialog({
    super.key,
    required this.title,
    required this.child,
    this.onClose,
    this.headerColor = GameColors.headerBlue,
    this.maxWidth = 360,
  });

  final String title;
  final Widget child;
  final VoidCallback? onClose;
  final Color headerColor;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      tween: Tween(begin: 0.82, end: 1.0),
      builder: (_, s, child) => Transform.scale(scale: s, child: child),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header.
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 22),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            GameColors.lighten(headerColor),
                            headerColor,
                          ],
                        ),
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(26)),
                      ),
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(color: Colors.black26, offset: Offset(0, 2)),
                          ],
                        ),
                      ),
                    ),
                    // Body — overlaps the header so the rounded corners tuck in.
                    Transform.translate(
                      offset: const Offset(0, -12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                        decoration: const BoxDecoration(
                          color: GameColors.panel,
                          borderRadius: BorderRadius.all(Radius.circular(26)),
                        ),
                        // A transparent Material so inputs (TextField, ink)
                        // inside any GameDialog have the ancestor they require.
                        child: Material(
                          type: MaterialType.transparency,
                          child: child,
                        ),
                      ),
                    ),
                  ],
                ),
                // Floating close button.
                if (onClose != null)
                  Positioned(
                    top: -10,
                    right: -6,
                    child: ChunkyCircleButton(
                      icon: Icons.close_rounded,
                      color: GameColors.red,
                      size: 40,
                      iconSize: 24,
                      onTap: onClose,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Present a [GameDialog]-style dialog with the standard dimmed barrier.
Future<T?> showGameDialog<T>(
  BuildContext context, {
  required String title,
  required Widget child,
  bool barrierDismissible = true,
  Color headerColor = GameColors.headerBlue,
  bool showClose = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) => GameDialog(
      title: title,
      headerColor: headerColor,
      onClose: showClose ? () => Navigator.of(ctx).pop() : null,
      child: child,
    ),
  );
}
