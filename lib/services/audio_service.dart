import 'package:audioplayers/audioplayers.dart';

/// App-wide audio — deliberately simple and conservative for Android reliability.
///
/// History of pain this design avoids:
///  * Creating ~16 players at once exhausted Android's media server
///    (`MEDIA_ERROR_SERVER_DIED`) → ALL audio died. So we keep very few.
///  * Low-latency / SoundPool mode produced FAST AudioTracks that started and
///    were cut immediately (inaudible) and logged `config failed => CORRUPTED`
///    on some chipsets. So we use normal media-player mode.
///
/// Design: exactly ONE reusable player per sound effect (4) + one for music = 5
/// players total, all media-player mode, each created lazily and kept. A tap
/// just `seek(0)` + `resume()`s its player. A global `mixWithOthers` audio
/// context stops effects from stealing focus and pausing the music.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  static final AudioContext _ctx = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
    respectSilence: false,
  ).build();

  final AudioPlayer _music = AudioPlayer();
  final Map<String, AudioPlayer> _sfx = {};
  bool _musicWanted = false;
  bool _inited = false;

  Future<void> init() async {
    if (_inited) return;
    _inited = true;
    try {
      await AudioPlayer.global.setAudioContext(_ctx);
    } catch (_) {}
    try {
      await _music.setAudioContext(_ctx);
      await _music.setReleaseMode(ReleaseMode.loop);
    } catch (_) {}
  }

  /// Lazily create + prepare one reusable player for [clip] (kept forever).
  Future<AudioPlayer?> _clipPlayer(String clip) async {
    final existing = _sfx[clip];
    if (existing != null) return existing;
    final p = AudioPlayer();
    _sfx[clip] = p; // store first so concurrent calls reuse it
    try {
      await p.setAudioContext(_ctx);
      await p.setReleaseMode(ReleaseMode.stop);
      await p.setSource(AssetSource('sfx/$clip.wav'));
      await p.setVolume(1.0);
    } catch (_) {
      // leave it; sfx() will just no-op for this clip
    }
    return p;
  }

  /// Warm the players one at a time (sequential — never a burst that could
  /// crash the media server).
  Future<void> preload(List<String> clips) async {
    await init();
    for (final clip in clips) {
      await _clipPlayer(clip);
    }
  }

  Future<void> sfx(String clip, {bool loud = false}) async {
    try {
      await init();
      final p = await _clipPlayer(clip);
      if (p == null) return;
      await p.seek(Duration.zero);
      await p.resume();
    } catch (_) {}
  }

  Future<void> setMusicEnabled(bool on) async {
    _musicWanted = on;
    await init();
    try {
      await _music.stop();
      if (on) {
        await _music.setReleaseMode(ReleaseMode.loop);
        await _music.setVolume(0.8);
        await _music.play(
            AssetSource('music/arrows_pro_background_music.mp3'),
            volume: 0.8);
      }
    } catch (_) {}
  }

  bool get musicWanted => _musicWanted;

  /// Pause music when the app leaves the foreground; resume on return.
  Future<void> pause() async {
    try {
      await _music.pause();
    } catch (_) {}
  }

  Future<void> resume() async {
    if (!_musicWanted) return;
    try {
      await _music.resume();
    } catch (_) {}
  }

  void dispose() {
    _music.dispose();
    for (final p in _sfx.values) {
      p.dispose();
    }
  }
}
