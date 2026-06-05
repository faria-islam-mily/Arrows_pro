import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/power_up.dart';
import '../services/audio_service.dart';
import '../state/app_scope.dart';

// Four DISTINCT buy pages — one per power-up, each with its own header colour,
// badge gradient, icon and copy. Opened from a tile's "+" or when you tap a
// power you've run out of.

Future<void> showHintBoosterSheet(BuildContext context) => _show(
      context,
      power: PowerUp.hint,
      header: const Color(0xFFF4A100),
      badge: const [Color(0xFFFFD23F), Color(0xFFF4A100)],
      icon: Icons.lightbulb_rounded,
    );

Future<void> showEraserBoosterSheet(BuildContext context) => _show(
      context,
      power: PowerUp.eraser,
      header: const Color(0xFFEE4B4B),
      badge: const [Color(0xFFFF7A7A), Color(0xFFEE4B4B)],
      icon: Icons.cleaning_services_rounded,
    );

Future<void> showMagicBoosterSheet(BuildContext context) => _show(
      context,
      power: PowerUp.magic,
      header: const Color(0xFF4E5DF2),
      badge: const [Color(0xFF8E8EF6), Color(0xFF4E5DF2)],
      icon: Icons.auto_awesome_rounded,
    );

Future<void> showUndoBoosterSheet(BuildContext context) => _show(
      context,
      power: PowerUp.undo,
      header: const Color(0xFF1E9E8A),
      badge: const [Color(0xFF36C58E), Color(0xFF1E9E8A)],
      icon: Icons.undo_rounded,
    );

/// Opens the buy page for [power]. Also called from anywhere a power is needed.
Future<void> showBoosterFor(BuildContext context, PowerUp power) {
  switch (power) {
    case PowerUp.hint:
      return showHintBoosterSheet(context);
    case PowerUp.eraser:
      return showEraserBoosterSheet(context);
    case PowerUp.magic:
      return showMagicBoosterSheet(context);
    case PowerUp.undo:
      return showUndoBoosterSheet(context);
  }
}

Future<void> _show(
  BuildContext context, {
  required PowerUp power,
  required Color header,
  required List<Color> badge,
  required IconData icon,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (_) => _BoosterDialog(
      power: power,
      header: header,
      badge: badge,
      icon: icon,
    ),
  );
}

class _BoosterDialog extends StatelessWidget {
  const _BoosterDialog({
    required this.power,
    required this.header,
    required this.badge,
    required this.icon,
  });

  final PowerUp power;
  final Color header;
  final List<Color> badge;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final messenger = ScaffoldMessenger.of(context);

    void toast(String m) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(m),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ));
    }

    // Reward one (placeholder for a rewarded video ad).
    Future<void> watchForOne() async {
      final state = AppScope.read(context);
      final msg = context.l10n.boosterAdded(power);
      await state.addPower(power, 1);
      AudioService.instance.sfx('win');
      if (context.mounted) Navigator.of(context).pop();
      toast(msg);
    }

    Future<void> buyBundle() async {
      final state = AppScope.read(context);
      final needMsg = context.l10n.needCoinsBundle(power.bundlePrice);
      final addedMsg = '+$kPowerBundleAmount ${context.l10n.powerName(power)}';
      if (!await state.spendCoins(power.bundlePrice)) {
        toast(needMsg);
        return;
      }
      await state.addPower(power, kPowerBundleAmount);
      AudioService.instance.sfx('win');
      if (context.mounted) Navigator.of(context).pop();
      toast(addedMsg);
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header bar tinted to this power.
          Container(
            decoration: BoxDecoration(
              color: header,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(22, 14, 12, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.getBooster,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
          // Body.
          Container(
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: badge,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: badge.last.withValues(alpha: 0.55),
                        blurRadius: 26,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 56, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.boosterTitle(power),
                  style: TextStyle(
                    color: palette.arrow == const Color(0xFFEE4B4B)
                        ? Colors.white
                        : palette.arrow,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _BoosterButton(
                        colors: const [Color(0xFFA24BF0), Color(0xFF7B2FF0)],
                        onTap: watchForOne,
                        top: const Icon(Icons.smart_display,
                            color: Colors.white, size: 22),
                        label: '${context.l10n.get} x1',
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _BoosterButton(
                        colors: const [Color(0xFF3FD17A), Color(0xFF27A35A)],
                        onTap: buyBundle,
                        label: '${context.l10n.get} x$kPowerBundleAmount',
                        bottom: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.monetization_on,
                                size: 16, color: Color(0xFFFFD23F)),
                            const SizedBox(width: 4),
                            Text(
                              '${power.bundlePrice}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A chunky 3D-style action button for the booster popup.
class _BoosterButton extends StatelessWidget {
  const _BoosterButton({
    required this.colors,
    required this.onTap,
    required this.label,
    this.top,
    this.bottom,
  });

  final List<Color> colors;
  final VoidCallback onTap;
  final String label;
  final Widget? top;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: colors.last, offset: const Offset(0, 4)),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (top != null) ...[top!, const SizedBox(height: 4)],
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (bottom != null) ...[const SizedBox(height: 4), bottom!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
