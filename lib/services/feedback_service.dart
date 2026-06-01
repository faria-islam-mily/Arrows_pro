import 'package:flutter/services.dart';

import '../state/app_state.dart';
import 'audio_service.dart';

/// Central place for haptics and sound, gated by the user's settings toggles.
/// Call the semantic methods (`tapSuccess`, `blocked`, `win`) from the UI so
/// the feel stays consistent and respects Sound/Vibration preferences.
///
/// Haptics use the built-in [HapticFeedback]. Sound is stubbed: to enable it,
/// add `audioplayers` to pubspec, drop clips in `assets/sfx/`, and fill in the
/// `_play` method below (a single AudioPlayer pool works well).
class FeedbackService {
  FeedbackService(this.state);

  final AppState state;

  /// An arrow successfully slid off the board.
  void tapSuccess() {
    if (state.vibrationOn) HapticFeedback.lightImpact();
    _play('pop');
  }

  /// A blocked tap (wrong move, costs a life).
  void blocked() {
    if (state.vibrationOn) HapticFeedback.heavyImpact();
    _play('blocked');
  }

  /// Level cleared.
  void win() {
    if (state.vibrationOn) HapticFeedback.mediumImpact();
    _play('win');
  }

  /// A light tick for UI taps (buttons, hints).
  void tick() {
    if (state.vibrationOn) HapticFeedback.selectionClick();
  }

  void _play(String clip) {
    if (!state.soundOn) return;
    AudioService.instance.sfx(clip); // no-op until clips are added to assets/sfx
  }
}