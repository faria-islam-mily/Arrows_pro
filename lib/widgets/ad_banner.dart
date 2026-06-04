import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../data/palettes.dart';
import '../services/ads_service.dart';
import '../state/app_scope.dart';

/// A grounded AdMob banner. Loads a real [BannerAd] and shows it once ready;
/// until then it holds the banner's height with a subtle placeholder so the
/// layout doesn't jump. Collapses to nothing once the player buys "Remove Ads"
/// ([AppState.adsRemoved]).
///
/// The "Remove ads" purchase lives in Settings (and the result dialogs), kept
/// off the banner itself so nothing sits next to a live ad — AdMob policy.
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final ad = BannerAd(
      adUnitId: AdsService.bannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    );
    _ad = ad;
    ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.appState;
    // Purchased → release the ad and take up no space.
    if (state.adsRemoved) {
      _ad?.dispose();
      _ad = null;
      return const SizedBox.shrink();
    }

    final palette = context.palette;
    final height = AdSize.banner.height.toDouble(); // 50

    return Material(
      color: palette.background,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: _loaded && _ad != null
              ? Center(
                  child: SizedBox(
                    width: _ad!.size.width.toDouble(),
                    height: height,
                    child: AdWidget(ad: _ad!),
                  ),
                )
              : _Placeholder(palette: palette),
        ),
      ),
    );
  }
}

/// Shown while the banner is still loading (or never fills).
class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.palette});
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Advertisement',
        style: TextStyle(
          color: palette.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
