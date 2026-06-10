import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Initialises the Google Mobile Ads SDK and hands out the right banner ad-unit
/// ID for the current platform / build mode.
///
/// In debug/profile we always serve Google's official **test** units so you can
/// develop without risking your AdMob account. Release builds use your real
/// units — fill in [_androidBanner] / [_iosBanner] below.
class AdsService {
  AdsService._();

  static bool _inited = false;

  /// Safe to call more than once; only the first call does the work.
  static Future<void> init() async {
    if (_inited) return;
    _inited = true;
    try {
      await MobileAds.instance.initialize();
    } catch (_) {
      // Ads simply won't show (e.g. on an unsupported platform / no network).
    }
    loadRewarded(); // warm a rewarded ad for the first "Watch" tap
    loadInterstitial(); // warm an interstitial for the first level break
  }

  // ---- Rewarded video ----------------------------------------------------

  static RewardedAd? _rewarded;
  static bool _loadingRewarded = false;
  // Resolved whenever a load finishes (success OR failure), so a waiting
  // [showRewarded] can wake up the moment an ad is ready.
  static Completer<void>? _loadWaiter;

  /// Preload a rewarded ad (no-op if one is ready or already loading).
  static void loadRewarded() {
    if (_rewarded != null || _loadingRewarded) return;
    _loadingRewarded = true;
    RewardedAd.load(
      adUnitId: rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          _loadingRewarded = false;
          _wakeLoadWaiter();
        },
        onAdFailedToLoad: (_) {
          _rewarded = null;
          _loadingRewarded = false;
          _wakeLoadWaiter();
        },
      ),
    );
  }

  static void _wakeLoadWaiter() {
    final w = _loadWaiter;
    _loadWaiter = null;
    if (w != null && !w.isCompleted) w.complete();
  }

  /// Show a rewarded ad. Resolves true only if the user earned the reward.
  /// If none is ready yet it kicks off a load and waits briefly for it (so the
  /// "watch a video" reward reliably plays instead of failing on the first tap).
  static Future<bool> showRewarded() async {
    if (_rewarded == null) {
      loadRewarded();
      // Wait up to a few seconds for the in-flight load to finish.
      if (_loadingRewarded) {
        _loadWaiter ??= Completer<void>();
        await _loadWaiter!.future
            .timeout(const Duration(seconds: 5), onTimeout: () {});
      }
    }
    final ad = _rewarded;
    if (ad == null) return false;
    _rewarded = null;
    final completer = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadRewarded();
        if (!completer.isCompleted) completer.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        loadRewarded();
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    ad.show(onUserEarnedReward: (_, __) => earned = true);
    return completer.future;
  }

  // ---- Interstitial (full-screen, at level breaks) -----------------------

  static InterstitialAd? _interstitial;
  static bool _loadingInterstitial = false;
  static int _interGate = 0; // only show on every Nth break (less intrusive)

  /// Preload an interstitial (no-op if one is ready or already loading).
  static void loadInterstitial() {
    if (_interstitial != null || _loadingInterstitial) return;
    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _loadingInterstitial = false;
        },
        onAdFailedToLoad: (_) {
          _interstitial = null;
          _loadingInterstitial = false;
        },
      ),
    );
  }

  /// Show a full-screen interstitial at a level break — but only on every other
  /// break so it isn't intrusive. Resolves when the ad is dismissed, or
  /// immediately if it's not this break's turn / none is ready. Callers should
  /// gate on `!adsRemoved` before calling.
  static Future<void> maybeShowInterstitial() async {
    _interGate++;
    if (_interGate % 2 != 0) {
      loadInterstitial(); // warm one for next time
      return;
    }
    final ad = _interstitial;
    if (ad == null) {
      loadInterstitial();
      return;
    }
    _interstitial = null;
    final completer = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadInterstitial();
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        loadInterstitial();
        if (!completer.isCompleted) completer.complete();
      },
    );
    ad.show();
    return completer.future;
  }

  static String get interstitialUnitId {
    if (kReleaseMode) {
      return Platform.isIOS ? _iosInterstitial : _androidInterstitial;
    }
    // Google's official sample interstitial units.
    return Platform.isIOS
        ? 'ca-app-pub-3940256099942544/4411468910'
        : 'ca-app-pub-3940256099942544/1033173712';
  }

  static String get rewardedUnitId {
    if (kReleaseMode) {
      return Platform.isIOS ? _iosRewarded : _androidRewarded;
    }
    // Google's official sample rewarded units.
    return Platform.isIOS
        ? 'ca-app-pub-3940256099942544/1712485313'
        : 'ca-app-pub-3940256099942544/5224354917';
  }

  /// The banner ad-unit ID to request, picked by platform and build mode.
  static String get bannerUnitId {
    if (kReleaseMode) {
      return Platform.isIOS ? _iosBanner : _androidBanner;
    }
    // Google's official sample banner units — always fill, never billed.
    return Platform.isIOS
        ? 'ca-app-pub-3940256099942544/2934735716'
        : 'ca-app-pub-3940256099942544/6300978111';
  }

  // TODO: replace these with your real AdMob banner ad-unit IDs from the AdMob
  // console before shipping a release build. Also set the app-level AdMob app
  // ID in AndroidManifest.xml (meta-data) and ios/Runner/Info.plist
  // (GADApplicationIdentifier).
  static const String _androidBanner =
      'ca-app-pub-0000000000000000/0000000000';
  static const String _iosBanner = 'ca-app-pub-0000000000000000/0000000000';
  static const String _androidRewarded =
      'ca-app-pub-0000000000000000/0000000000';
  static const String _iosRewarded =
      'ca-app-pub-0000000000000000/0000000000';
  static const String _androidInterstitial =
      'ca-app-pub-0000000000000000/0000000000';
  static const String _iosInterstitial =
      'ca-app-pub-0000000000000000/0000000000';
}
