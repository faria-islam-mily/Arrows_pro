import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/palettes.dart';
import 'screens/splash_screen.dart';
import 'services/ads_service.dart';
import 'services/audio_service.dart';
import 'services/iap_service.dart';
import 'state/app_scope.dart';
import 'state/app_state.dart';
import 'state/storage.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fullscreen, immersive game look: hide the system status bar (clock,
  // battery, wifi, signal) and nav bar. They slide back on a swipe, then
  // auto-hide again. Re-applied on resume (see didChangeAppLifecycleState).
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  final storage = await Storage.open();
  final state = AppState(storage);
  // Warm the sfx pools so the first tap/heart-loss sound fires instantly.
  AudioService.instance.preload(['pop', 'blocked', 'win', 'heart']);
  // Start the looping background music if the player has it enabled.
  if (state.musicOn) AudioService.instance.setMusicEnabled(true);
  // Bring up monetization (non-blocking): init the ads SDK and the store. The
  // store init also silently re-applies any prior "Remove Ads" purchase.
  AdsService.init();
  IapService.instance.init(state);
  runApp(AppScope(state: state, child: const ArrowProApp()));
}

class ArrowProApp extends StatefulWidget {
  const ArrowProApp({super.key});

  @override
  State<ArrowProApp> createState() => _ArrowProAppState();
}

class _ArrowProAppState extends State<ArrowProApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Cold start can fire before the audio engine is ready, so (re)start music
    // once the first frame is up (setMusicEnabled is idempotent).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = AppScope.read(context);
      if (state.musicOn) AudioService.instance.setMusicEnabled(true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    // Stop music whenever the app leaves the foreground (so it never keeps
    // playing in the background / after close), resume when it returns.
    if (s == AppLifecycleState.resumed) {
      AudioService.instance.resume();
      // Re-hide the system bars (Android can re-show them after resume).
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else if (s == AppLifecycleState.paused ||
        s == AppLifecycleState.hidden ||
        s == AppLifecycleState.detached) {
      AudioService.instance.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final palette = kPalettes[state.themeIndex];
        final dark = palette.brightness == Brightness.dark;
        // Transparent bars with icons that contrast the current theme.
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
          statusBarBrightness: dark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: palette.background,
          systemNavigationBarIconBrightness:
              dark ? Brightness.light : Brightness.dark,
        ));
        return MaterialApp(
          title: 'Arrow Pro',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.fromPalette(palette),
          home: const SplashScreen(),
        );
      },
    );
  }
}
