import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/shop_catalog.dart';
import '../l10n/strings.dart';
import '../models/power_up.dart';
import '../services/ads_service.dart';
import '../services/iap_service.dart';
import '../services/shop_service.dart';
import '../state/app_scope.dart';
import '../theme/app_images.dart';
import '../theme/game_colors.dart';
import 'app_image.dart';
import 'processing_overlay.dart';
import 'purchase_dialogs.dart';
import 'ui_kit.dart';

// Shared promo palette (the bright purple storefront look from the reference).
const Color _promoTop = Color(0xFF7C4BD0);
const Color _promoBottom = Color(0xFF4C2C9E);
const Color _titleYellow = Color(0xFFFFD23F);
const Color _titleStroke = Color(0xFF6A3AB0);

// ---------------------------------------------------------------------------
// Entry points
// ---------------------------------------------------------------------------

/// The full-screen "Remove Ads" upsell (opened from the NO ADS rail button).
Future<void> showRemoveAds(BuildContext context) => _showPromo(
      context,
      label: 'Remove Ads',
      builder: (_) => const _RemoveAdsPage(),
    );

/// The full-screen "Special Offer" upsell (opened from the SALE rail button).
Future<void> showSpecialOffer(BuildContext context) => _showPromo(
      context,
      label: 'Special Offer',
      builder: (_) => const _SpecialOfferPage(),
    );

Future<void> _showPromo(
  BuildContext context, {
  required String label,
  required WidgetBuilder builder,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: label,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    transitionDuration: const Duration(milliseconds: 340),
    pageBuilder: (ctx, _, __) => builder(ctx),
    transitionBuilder: (_, anim, __, child) {
      final c = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(begin: 0.92, end: 1.0).animate(c),
          child: child,
        ),
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Remove Ads
// ---------------------------------------------------------------------------

class _RemoveAdsPage extends StatelessWidget {
  const _RemoveAdsPage();

  @override
  Widget build(BuildContext context) {
    final price = IapService.instance.removeAdsPrice;
    return _PromoScaffold(
      children: [
        _CartoonTitle(main: context.l10n.removeWord, sub: context.l10n.adsWord),
        const Spacer(flex: 2),
        const _FloatingHero(
          child: AppImage(
            AppImages.noAds,
            size: 200,
            fallback: Text('📺', style: TextStyle(fontSize: 130)),
          ),
        ),
        const Spacer(flex: 2),
        Text(
          context.l10n.removesAds,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            height: 1.15,
            fontWeight: FontWeight.w900,
            shadows: [Shadow(color: Color(0x66000000), offset: Offset(0, 2))],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          context.l10n.keepOptionalAds,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(flex: 2),
        _PromoBuyButton(
          label: price.isNotEmpty ? price : 'BDT 1,100',
          onTap: () => _purchaseRemoveAds(context),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Buy Remove Ads through the store when available, otherwise grant it locally
/// (dev/testing) so the flow is demoable without a live store product.
Future<void> _purchaseRemoveAds(BuildContext context) async {
  if (IapService.instance.isAvailable) {
    await buyRemoveAds(context);
    return;
  }
  final state = AppScope.read(context);
  showProcessing(context);
  await Future<void>.delayed(const Duration(milliseconds: 1300));
  if (!context.mounted) return;
  hideProcessing(context);
  await state.removeAds();
  if (context.mounted) showPurchaseSuccess(context);
}

// ---------------------------------------------------------------------------
// Special Offer
// ---------------------------------------------------------------------------

class _SpecialOfferPage extends StatelessWidget {
  const _SpecialOfferPage();

  @override
  Widget build(BuildContext context) {
    const offer = kSpecialOffer;
    return _PromoScaffold(
      children: [
        _CartoonTitle(
            main: context.l10n.specialWord, sub: context.l10n.offerWord),
        const Spacer(),
        const _FloatingHero(
          sparkles: true,
          child: AppImage(
            AppImages.offerSpecial,
            size: 200,
            fallback: AppImage(
              AppImages.pack50000,
              size: 200,
              fallback: Text('💰', style: TextStyle(fontSize: 120)),
            ),
          ),
        ),
        const Spacer(),
        // Reward panel with the "30% OFF" badge.
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22), width: 1.5),
              ),
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppImage(AppImages.pack10000,
                          size: 64,
                          fallback:
                              Text('🪙', style: TextStyle(fontSize: 44))),
                      Text('${offer.coins}',
                          style: const TextStyle(
                              color: _titleYellow,
                              fontSize: 24,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 1.5,
                    height: 70,
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(child: _PromoPerks(offer)),
                ],
              ),
            ),
            Positioned(
              top: -16,
              left: -6,
              child: _DiscountBadge(),
            ),
          ],
        ),
        const Spacer(),
        _PromoBuyButton(
          label: offer.priceLabel,
          onTap: () => buyShopProduct(context, offer),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _PromoPerks extends StatelessWidget {
  const _PromoPerks(this.offer);
  final ShopProduct offer;

  @override
  Widget build(BuildContext context) {
    final perks = <Widget>[
      if (offer.infiniteHours > 0)
        _PerkChip(
            icon: const HeartIcon(size: 30), label: '∞${offer.infiniteHours}hrs'),
      if (offer.magic > 0)
        _PerkChip(
            icon: const PowerIcon(PowerUp.magic, size: 30),
            label: 'x${offer.magic}'),
      if (offer.hint > 0)
        _PerkChip(
            icon: const PowerIcon(PowerUp.hint, size: 30),
            label: 'x${offer.hint}'),
      if (offer.eraser > 0)
        _PerkChip(
            icon: const PowerIcon(PowerUp.eraser, size: 30),
            label: 'x${offer.eraser}'),
    ];
    return Wrap(
      spacing: 14,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: perks,
    );
  }
}

class _PerkChip extends StatelessWidget {
  const _PerkChip({required this.icon, required this.label});
  final Widget icon;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _DiscountBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.15,
      child: Container(
        width: 60,
        height: 60,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: GameColors.red,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Color(0x66000000), blurRadius: 6)],
        ),
        child: const Text('30%\nOFF',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.05,
                fontWeight: FontWeight.w900)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared building blocks
// ---------------------------------------------------------------------------

/// The full-screen purple promo frame: gradient background, a floating close X,
/// and a vertically laid-out [children] column.
class _PromoScaffold extends StatelessWidget {
  const _PromoScaffold({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_promoTop, _promoBottom],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
              Positioned(
                top: 6,
                right: 10,
                child: ChunkyCircleButton(
                  icon: Icons.close_rounded,
                  color: GameColors.red,
                  size: 42,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The chunky cartoon two-part title — a thick-outlined yellow word over a
/// small white pill (e.g. SPECIAL / OFFER, REMOVE / ADS).
class _CartoonTitle extends StatelessWidget {
  const _CartoonTitle({required this.main, required this.sub});
  final String main;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 30),
        Stack(
          alignment: Alignment.center,
          children: [
            // Outline.
            Text(main,
                style: TextStyle(
                  fontSize: 54,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 9
                    ..strokeJoin = StrokeJoin.round
                    ..color = _titleStroke,
                )),
            // Fill.
            const Text('', style: TextStyle(fontSize: 54)),
            Text(main,
                style: const TextStyle(
                  fontSize: 54,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: _titleYellow,
                  shadows: [
                    Shadow(color: Color(0x55000000), offset: Offset(0, 3))
                  ],
                )),
          ],
        ),
        Transform.translate(
          offset: const Offset(0, -6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF3FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _titleStroke, width: 2),
            ),
            child: Text(sub,
                style: const TextStyle(
                    color: Color(0xFF8A93A8),
                    fontSize: 18,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w900)),
          ),
        ),
      ],
    );
  }
}

/// A hero image that gently bobs up and down, with an optional sweeping light
/// ray behind it and twinkling sparkles for extra life.
class _FloatingHero extends StatefulWidget {
  const _FloatingHero({required this.child, this.sparkles = false});
  final Widget child;
  final bool sparkles;

  @override
  State<_FloatingHero> createState() => _FloatingHeroState();
}

class _FloatingHeroState extends State<_FloatingHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

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
        final bob = math.sin(_c.value * math.pi * 2) * 8;
        return SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Soft rotating light ray.
              Transform.rotate(
                angle: _c.value * math.pi * 2,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: 0.10),
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: 0.10),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.15, 0.3, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
              if (widget.sparkles) ..._sparkles(),
              Transform.translate(offset: Offset(0, bob), child: child),
            ],
          ),
        );
      },
      child: widget.child,
    );
  }

  List<Widget> _sparkles() {
    const spots = [
      Offset(-78, -60),
      Offset(80, -40),
      Offset(60, 70),
      Offset(-70, 64),
    ];
    return [
      for (var i = 0; i < spots.length; i++)
        Transform.translate(
          offset: spots[i],
          child: Opacity(
            opacity: (0.4 +
                    0.6 *
                        (0.5 +
                            0.5 *
                                math.sin(_c.value * math.pi * 2 + i * 1.6)))
                .clamp(0.0, 1.0),
            child: Icon(Icons.star_rounded,
                color: _titleYellow.withValues(alpha: 0.9),
                size: 16 + (i.isEven ? 6 : 0)),
          ),
        ),
    ];
  }
}

/// The big green "buy" button with a gold lip, matching the reference CTA.
class _PromoBuyButton extends StatelessWidget {
  const _PromoBuyButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChunkyButton(
      color: GameColors.green,
      depth: 8,
      radius: 18,
      shadowColor: const Color(0xFFB07A12), // gold lip
      padding: const EdgeInsets.symmetric(vertical: 18),
      onTap: onTap,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
          shadows: [Shadow(color: Color(0x66000000), offset: Offset(0, 2))],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lives dialog (opened from the lives "+" in the HUD)
// ---------------------------------------------------------------------------

const Color _livesPanel = Color(0xFF2C3858);
const Color _livesInner = Color(0xFF3B4668);

/// Shows the Lives panel: the current lives, the regen countdown, a free-video
/// refill, and a value bundle below.
Future<void> showLivesDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (_) => const _LivesDialog(),
  );
}

class _LivesDialog extends StatefulWidget {
  const _LivesDialog();
  @override
  State<_LivesDialog> createState() => _LivesDialogState();
}

class _LivesDialogState extends State<_LivesDialog> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
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

  Future<void> _refill() async {
    final state = AppScope.read(context);
    final earned = await AdsService.showRewarded();
    if (!mounted) return;
    if (earned) {
      await state.refillLives();
      if (mounted) Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ad not ready yet — try again in a moment.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.appState;
    final infinite = state.hasInfiniteLives;
    final String status;
    if (infinite) {
      status = _fmt(state.infiniteRemaining ?? Duration.zero);
    } else {
      final t = state.timeToNextLife;
      status = t == null ? 'FULL' : _fmt(t);
    }

    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topRight,
                  children: [
                    _card(state, infinite, status),
                    Positioned(
                      top: -10,
                      right: -6,
                      child: ChunkyCircleButton(
                        icon: Icons.close_rounded,
                        color: GameColors.red,
                        size: 38,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _BundleTile(
                  offer: kBundles.first,
                  onBuy: () => buyShopProduct(context, kBundles.first),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(state, bool infinite, String status) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [GameColors.headerBlue, GameColors.headerBlueDark],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Text(context.l10n.lives,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(color: Colors.black26, offset: Offset(0, 2))
                    ])),
          ),
          // Body.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            decoration: const BoxDecoration(
              color: _livesPanel,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: _livesInner,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: _BigHeart(label: infinite ? '∞' : '${state.lives}'),
                ),
                const SizedBox(height: 14),
                Text(infinite ? context.l10n.infiniteLives : context.l10n.nextLifeIn,
                    style: const TextStyle(
                        color: Color(0xFFAEB9D4),
                        fontSize: 14,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                // Countdown pill.
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222C46),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: GameColors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.remove_rounded,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Text(status,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(width: 14),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ChunkyButton(
                    color: GameColors.green,
                    depth: 7,
                    radius: 18,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    onTap: _refill,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(context.l10n.refill,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900)),
                        Text(context.l10n.free,
                            style: const TextStyle(
                                color: Color(0xFFDFFFCB),
                                fontSize: 13,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A large heart with the count drawn inside that gently beats.
class _BigHeart extends StatefulWidget {
  const _BigHeart({required this.label});
  final String label;
  @override
  State<_BigHeart> createState() => _BigHeartState();
}

class _BigHeartState extends State<_BigHeart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
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
        final s = 1 + 0.06 * Curves.easeInOut.transform(_c.value);
        return Transform.scale(scale: s, child: child);
      },
      child: SizedBox(
        width: 130,
        height: 120,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const HeartIcon(size: 120),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(widget.label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 54,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(color: Color(0x99000000), blurRadius: 3)
                      ])),
            ),
          ],
        ),
      ),
    );
  }
}

/// The pink value-bundle tile shown under the Lives panel.
class _BundleTile extends StatelessWidget {
  const _BundleTile({required this.offer, required this.onBuy});
  final ShopProduct offer;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE85C9A), Color(0xFFD23F84)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppImage(AppImages.pack5000,
                        size: 64,
                        fallback: Text('🪙', style: TextStyle(fontSize: 44))),
                    Text('${offer.coins}',
                        style: const TextStyle(
                            color: _titleYellow,
                            fontSize: 22,
                            fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(child: _PromoPerks(offer)),
              ],
            ),
          ),
          // Bottom strip with the name + price.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 10, 12, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(offer.title.toUpperCase(),
                      style: const TextStyle(
                          color: Color(0xFF6E33B0),
                          fontSize: 18,
                          fontWeight: FontWeight.w900)),
                ),
                ChunkyButton(
                  color: GameColors.green,
                  depth: 5,
                  radius: 14,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  onTap: onBuy,
                  child: Text(offer.priceLabel,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
