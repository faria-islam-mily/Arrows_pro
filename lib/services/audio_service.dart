import 'package:audioplayers/audioplayers.dart';

/// App-wide audio: one looping background-music player + a small pool for
/// overlapping sound effects. Every call is wrapped in try/catch so a missing
/// asset (no files dropped in `assets/sfx` / `assets/music` yet) is a harmless
/// no-op rather than a crash.
///
/// Gating by the user's Sound/Music toggles happens at the call sites
/// (FeedbackService for sfx, settings/app for music).
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final AudioPlayer _music = AudioPlayer()..setReleaseMode(ReleaseMode.loop);
  // Small round-robin pool so rapid taps can overlap without cutting out.
  final List<AudioPlayer> _sfxPool =
      List.generate(4, (_) => AudioPlayer()..setReleaseMode(ReleaseMode.release));
  int _sfxIndex = 0;
  bool _musicPlaying = false;

  Future<void> sfx(String clip) async {
    try {
      final player = _sfxPool[_sfxIndex];
      _sfxIndex = (_sfxIndex + 1) % _sfxPool.length;
      await player.stop();
      await player.play(AssetSource('sfx/$clip.mp3'), volume: 0.7);
    } catch (_) {
      // asset missing / platform hiccup — ignore
    }
  }

  Future<void> setMusicEnabled(bool on) async {
    try {
      if (on) {
        if (_musicPlaying) return;
        await _music.play(AssetSource('music/ambient.mp3'), volume: 0.35);
        _musicPlaying = true;
      } else {
        await _music.stop();
        _musicPlaying = false;
      }
    } catch (_) {
      // asset missing / platform hiccup — ignore
    }
  }

  /// Pause/resume with app lifecycle (call from a WidgetsBindingObserver).
  Future<void> pause() async {
    try {
      if (_musicPlaying) await _music.pause();
    } catch (_) {}
  }

  Future<void> resume() async {
    try {
      if (_musicPlaying) await _music.resume();
    } catch (_) {}
  }

  void dispose() {
    _music.dispose();
    for (final p in _sfxPool) {
      p.dispose();
    }
  }
}
