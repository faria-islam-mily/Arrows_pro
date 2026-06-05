import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/shop_catalog.dart';
import '../l10n/strings.dart';
import '../models/power_up.dart';
import '../services/shop_service.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../theme/app_images.dart';
import '../theme/game_colors.dart';
import '../widgets/app_image.dart';
import '../widgets/purchase_dialogs.dart';
import '../widgets/ui_kit.dart';

/// Maps a shop product to its 3D hero PNG.
String _heroImage(String id) => switch (id) {
      'coins_1000' => AppImages.pack1000,
      'coins_5000' => AppImages.pack5000,
      'coins_10000' => AppImages.pack10000,
      'coins_25000' => AppImages.pack25000,
      'coins_50000' => AppImages.pack50000,
      'coins_100000' => AppImages.pack100000,
      'special_offer' => AppImages.offerSpecial,
      'classic_bundle' => AppImages.bundleClassic,
      'elite_bundle' => AppImages.bundleElite,
      'epic_bundle' => AppImages.bundleEpic,
      _ => AppImages.coin,
    };

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Refresh the countdown labels every minute.
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _fmtGift(Duration? d) {
    if (d == null) return '';
    return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
  }

  Future<void> _claimGift() async {
    final state = AppScope.read(context);
    if (await state.claimDailyGift()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('+${AppState.kDailyGiftCoins} coins!'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _toMidnight() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final d = midnight.difference(now);
    return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.appState;

    return Container(
      color: GameColors.blue,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _ShopTopBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
                children: [
                  _OfferCard(timeLeft: _toMidnight()),
                  const SizedBox(height: 14),
                  if (!state.adsRemoved) ...[
                    _NoAdsCard(onBuy: () => buyRemoveAds(context)),
                    const SizedBox(height: 14),
                  ],
                  _SectionLabel(context.l10n.coinsWord),
                  const SizedBox(height: 8),
                  _CoinGrid(),
                  const SizedBox(height: 16),
                  for (final b in kBundles) ...[
                    _BundleCard(product: b),
                    const SizedBox(height: 14),
                  ],
                  _FreeRow(
                    label: '$kWatchAdCoins COINS',
                    onTap: () => watchAdForCoins(context),
                  ),
                  const SizedBox(height: 12),
                  _DailyGiftRow(
                    canClaim: state.canClaimDailyGift,
                    timeLeft: _fmtGift(state.timeToNextGift),
                    onTap: _claimGift,
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

class _ShopTopBar extends StatelessWidget {
  const _ShopTopBar();

  @override
  Widget build(BuildContext context) {
    final state = context.appState;
    final lives = state.hasInfiniteLives ? '∞' : '${state.lives}';
    final String status;
    if (state.hasInfiniteLives) {
      status = '';
    } else {
      final t = state.timeToNextLife;
      if (t == null) {
        status = context.l10n.full;
      } else {
        final m = t.inMinutes.remainder(60).toString().padLeft(2, '0');
        status = '${t.inHours.toString().padLeft(2, '0')}:$m';
      }
    }
    return SizedBox(
      height: 50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Coin — left.
            Align(
              alignment: Alignment.centerLeft,
              child: _DarkPill(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CoinIcon(size: 30),
                    const SizedBox(width: 6),
                    Text('${state.coins}', style: _pillText),
                  ],
                ),
              ),
            ),
            // SHOP — centre.
            Text(
              context.l10n.shop.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                shadows: [Shadow(color: Colors.black26, offset: Offset(0, 2))],
              ),
            ),
            // Lives — right, number inside the heart.
            Align(
              alignment: Alignment.centerRight,
              child: _DarkPill(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _HeartNumber(size: 34, number: lives),
                    if (status.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(status,
                          style: const TextStyle(
                              color: Color(0xFFCFE0FF),
                              fontWeight: FontWeight.w800,
                              fontSize: 13)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const TextStyle _pillText = TextStyle(
    color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16);

class _DarkPill extends StatelessWidget {
  const _DarkPill({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.only(left: 5, right: 12),
      decoration: BoxDecoration(
        color: GameColors.blueDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
      ),
      child: child,
    );
  }
}

/// A heart with the life count drawn inside it.
class _HeartNumber extends StatelessWidget {
  const _HeartNumber({required this.size, required this.number});
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
          Padding(
            padding: EdgeInsets.only(bottom: size * 0.08),
            child: Text(
              number,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: size * 0.42,
                shadows: const [Shadow(color: Color(0x99000000), blurRadius: 2)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
          shadows: [Shadow(color: Colors.black26, offset: Offset(0, 1))],
        ),
      ),
    );
  }
}

/// Gently floats its child up and down for a lively, "alive" feel.
class _Bob extends StatefulWidget {
  const _Bob({required this.child, this.phase = 0, this.amount = 5});
  final Widget child;
  final double phase;
  final double amount;

  @override
  State<_Bob> createState() => _BobState();
}

class _BobState extends State<_Bob> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
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
        final t = _c.value * 2 * math.pi + widget.phase;
        return Transform.translate(
          offset: Offset(0, math.sin(t) * widget.amount),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// The big timed special-offer card.
class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.timeLeft});
  final String timeLeft;

  @override
  Widget build(BuildContext context) {
    const p = kSpecialOffer;
    return Container(
      decoration: BoxDecoration(
        color: GameColors.purple,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 2),
      ),
      child: Column(
        children: [
          // Timer chip.
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_rounded,
                    color: GameColors.blue, size: 16),
                const SizedBox(width: 5),
                Text(timeLeft,
                    style: const TextStyle(
                        color: GameColors.blue,
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      _Bob(
                        child: AppImage(
                          _heroImage(p.id),
                          size: 120,
                          fallback: const CoinIcon(size: 64),
                        ),
                      ),
                      Text(
                        '${p.coins}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const Expanded(flex: 6, child: _PerkGrid(product: p)),
              ],
            ),
          ),
          _CardFooter(
            title: p.title,
            priceLabel: p.priceLabel,
            onBuy: () => buyShopProduct(context, p),
          ),
        ],
      ),
    );
  }
}

class _NoAdsCard extends StatelessWidget {
  const _NoAdsCard({required this.onBuy});
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GameColors.purple,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24, width: 2),
      ),
      child: Row(
        children: [
          const AppImage(
            AppImages.noAds,
            size: 66,
            fallback: Icon(Icons.block_rounded, color: GameColors.red, size: 40),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.noAdsLabel,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900)),
                Text(context.l10n.removeInterstitial,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ChunkyButton(
            color: GameColors.green,
            depth: 5,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            onTap: onBuy,
            child: const Text('BDT 1,100',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15)),
          ),
        ],
      ),
    );
  }
}

class _CoinGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.64,
      children: [
        for (final p in kCoinPacks) _CoinPackCard(product: p),
      ],
    );
  }
}

class _CoinPackCard extends StatelessWidget {
  const _CoinPackCard({required this.product});
  final ShopProduct product;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => buyShopProduct(context, product),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF3ECDD),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            const SizedBox(height: 4),
            _Bob(
              amount: 4,
              phase: (product.coins % 7) * 1.0,
              child: AppImage(
                _heroImage(product.id),
                size: 96,
                fallback: const CoinIcon(size: 56),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              product.title,
              style: const TextStyle(
                color: Color(0xFF3A6BD6),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                color: GameColors.green,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(14)),
              ),
              alignment: Alignment.center,
              child: Text(
                product.priceLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BundleCard extends StatelessWidget {
  const _BundleCard({required this.product});
  final ShopProduct product;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: GameColors.purple,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      _Bob(
                        phase: (product.coins % 5) * 1.2,
                        child: AppImage(
                          _heroImage(product.id),
                          size: 116,
                          fallback:
                              const Text('💰', style: TextStyle(fontSize: 36)),
                        ),
                      ),
                      Text(
                        '${product.coins}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(flex: 6, child: _PerkGrid(product: product)),
              ],
            ),
          ),
          _CardFooter(
            title: product.title,
            priceLabel: product.priceLabel,
            onBuy: () => buyShopProduct(context, product),
          ),
        ],
      ),
    );
  }
}

/// 2×2 grid of perk chips (infinite lives + power-ups).
class _PerkGrid extends StatelessWidget {
  const _PerkGrid({required this.product});
  final ShopProduct product;

  @override
  Widget build(BuildContext context) {
    final perks = <Widget>[
      if (product.infiniteHours > 0)
        _perk(const _InfiniteLife(size: 30), '${product.infiniteHours}hrs'),
      if (product.magic > 0)
        _perk(const PowerIcon(PowerUp.magic, size: 30), 'x${product.magic}'),
      if (product.hint > 0)
        _perk(const PowerIcon(PowerUp.hint, size: 30), 'x${product.hint}'),
      if (product.eraser > 0)
        _perk(const PowerIcon(PowerUp.eraser, size: 30), 'x${product.eraser}'),
      if (product.undo > 0)
        _perk(const PowerIcon(PowerUp.undo, size: 30), 'x${product.undo}'),
    ];
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 10,
      children: perks,
    );
  }

  // Every perk gets the same footprint so they line up in a tidy grid.
  Widget _perk(Widget icon, String label) {
    return SizedBox(
      width: 74,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 32, height: 32, child: Center(child: icon)),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15)),
        ],
      ),
    );
  }
}

/// Heart with an infinity overlay — represents the timed infinite-lives perk.
class _InfiniteLife extends StatelessWidget {
  const _InfiniteLife({this.size = 22});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          HeartIcon(size: size),
          Icon(Icons.all_inclusive_rounded,
              size: size * 0.5, color: Colors.white),
        ],
      ),
    );
  }
}

class _CardFooter extends StatelessWidget {
  const _CardFooter({
    required this.title,
    required this.priceLabel,
    required this.onBuy,
  });
  final String title;
  final String priceLabel;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: GameColors.blue,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          ChunkyButton(
            color: GameColors.green,
            depth: 5,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            onTap: onBuy,
            child: Text(priceLabel,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15)),
          ),
        ],
      ),
    );
  }
}

class _FreeRow extends StatelessWidget {
  const _FreeRow({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: GameColors.blueDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CoinIcon(size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900)),
          ),
          ChunkyButton(
            color: GameColors.purple,
            depth: 5,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            onTap: onTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.play_circle_fill_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 5),
                Text(context.l10n.free,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyGiftRow extends StatelessWidget {
  const _DailyGiftRow({
    required this.canClaim,
    required this.timeLeft,
    required this.onTap,
  });
  final bool canClaim;
  final String timeLeft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canClaim ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: GameColors.purple,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const AppImage(
              AppImages.gift,
              size: 42,
              fallback: Text('🎁', style: TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(context.l10n.dailyGift,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CoinIcon(size: 18),
                      const SizedBox(width: 4),
                      Text('${AppState.kDailyGiftCoins} ${context.l10n.coinsWord}',
                          style: const TextStyle(
                              color: Color(0xFFFFE08A),
                              fontSize: 13,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
                ],
              ),
            ),
            if (canClaim)
              ChunkyButton(
                color: GameColors.green,
                depth: 5,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                onTap: onTap,
                child: Text(context.l10n.claim,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14)),
              )
            else
              Row(
                children: [
                  Text(context.l10n.nextIn,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                  Text(timeLeft,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
