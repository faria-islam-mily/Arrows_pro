import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../state/app_scope.dart';
import 'processing_overlay.dart';

/// Runs the "Remove Ads" purchase through [IapService]: shows the processing
/// spinner while the store works, then the matching result dialog. The unlock
/// itself ([AppState.removeAds]) is applied inside the service when the store
/// confirms, so the UI only has to react to the outcome.
Future<void> buyRemoveAds(BuildContext context) async {
  if (!IapService.instance.isAvailable) {
    showPurchaseFailed(context,
        message: 'The store isn\'t available right now.\nPlease try again later.');
    return;
  }

  showProcessing(context);
  final result = await IapService.instance.buyRemoveAds();
  if (!context.mounted) return;
  hideProcessing(context);

  switch (result) {
    case IapResult.success:
      showPurchaseSuccess(context);
    case IapResult.canceled:
      break; // user backed out of the store sheet — no dialog needed
    case IapResult.unavailable:
    case IapResult.failed:
      showPurchaseFailed(context);
  }
}

void showPurchaseSuccess(BuildContext context) => showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => const _PurchaseResultDialog(
        success: true,
        title: 'PURCHASE COMPLETE!',
        message: 'Ads removed — enjoy the quiet. Thank you!',
      ),
    );

void showPurchaseFailed(BuildContext context, {String? message}) =>
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => _PurchaseResultDialog(
        success: false,
        title: 'PURCHASE FAILED!',
        message: message ?? 'Oops! Something went wrong.\nPlease try again later.',
      ),
    );

class _PurchaseResultDialog extends StatelessWidget {
  const _PurchaseResultDialog({
    required this.success,
    required this.title,
    required this.message,
  });

  final bool success;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final header = success ? const Color(0xFF2EA843) : const Color(0xFFE53935);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeOutBack,
        tween: Tween(begin: 0.82, end: 1.0),
        builder: (context, s, child) =>
            Transform.scale(scale: s, child: child),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // Card.
            Container(
              margin: const EdgeInsets.only(top: 34),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Coloured header band.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 16),
                    decoration: BoxDecoration(
                      color: header,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(26)),
                    ),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: palette.arrow,
                            fontSize: 16,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 22),
                        _ChunkyButton(
                          label: 'OKAY',
                          color: const Color(0xFF2EA843),
                          onTap: () {
                            AudioService.instance.sfx('pop');
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Floating cart badge over the header.
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: header,
                shape: BoxShape.circle,
                border: Border.all(color: palette.surface, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: header.withValues(alpha: 0.5),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Icon(
                success
                    ? Icons.shopping_cart_checkout_rounded
                    : Icons.remove_shopping_cart_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChunkyButton extends StatelessWidget {
  const _ChunkyButton(
      {required this.label, required this.color, required this.onTap});
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.9), offset: const Offset(0, 4)),
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
          child: SizedBox(
            width: 180,
            height: 52,
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
