import 'package:flutter/material.dart';

import 'data/palettes.dart';
import 'screens/splash_screen.dart';
import 'services/audio_service.dart';
import 'state/app_scope.dart';
import 'state/app_state.dart';
import 'state/storage.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await Storage.open();
  final state = AppState(storage);
  // Start the looping background music if the player has it enabled (no-op
  // until a track is added to assets/music/ambient.mp3).
  if (state.musicOn) AudioService.instance.setMusicEnabled(true);
  runApp(AppScope(state: state, child: const ArrowProApp()));
}

class ArrowProApp extends StatelessWidget {
  const ArrowProApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final palette = kPalettes[state.themeIndex];
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
