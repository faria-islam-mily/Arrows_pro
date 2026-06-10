import 'dart:async';

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
  int _retries = 0;
  Timer? _retryTimer;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    if (_disposed) return;
    final ad = BannerAd(
      adUnitId: AdsService.bannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          _retries = 0;
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose(); // free the failed ad and stop pointing at it
          if (_disposed) return;
          _ad = null;
          if (mounted) setState(() => _loaded = false);
          // Retry with backoff (8s, 16s, 32s, 60s) so a transient network blip
          // doesn't leave the placeholder up for the whole session.
          if (_retries < 4) {
            _retries++;
            _retryTimer?.cancel();
            _retryTimer = Timer(
              Duration(seconds: (4 << _retries).clamp(8, 60)),
              () {
                if (!_disposed && !AppScope.read(context).adsRemoved) _load();
              },
            );
          }
        },
      ),
    );
    _ad = ad;
    ad.load();
  }

  @override
  void dispose() {
    _disposed = true;
    _retryTimer?.cancel();
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.appState;
    // Purchased → release the ad and take up no space.
    if (state.adsRemoved) {
      _retryTimer?.cancel();
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
