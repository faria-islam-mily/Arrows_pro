import 'package:flutter/foundation.dart';

import 'storage.dart';

/// Persistent app-wide state: selected theme, level progress, daily streak,
/// and the premium "remove ads" flag (free + ads + IAP model).
class AppState extends ChangeNotifier {
  AppState(this._storage) {
    _load();
  }

  final Storage _storage;

  static const _kTheme = 'themeIndex';
  static const _kUnlocked = 'unlockedLevel';
  static const _kStreak = 'streak';
  static const _kLastPlayed = 'lastPlayed';
  static const _kAdsRemoved = 'adsRemoved';

  int _themeIndex = 0;
  int _unlockedLevel = 1; // highest level number the player may open
  int _streak = 0;
  String? _lastPlayed; // yyyy-mm-dd of last completed day
  bool _adsRemoved = false;

  int get themeIndex => _themeIndex;
  int get unlockedLevel => _unlockedLevel;
  int get streak => _streak;
  bool get adsRemoved => _adsRemoved;

  bool isUnlocked(int levelNumber) => levelNumber <= _unlockedLevel;

  void _load() {
    _themeIndex = _storage.getInt(_kTheme, 0);
    _unlockedLevel = _storage.getInt(_kUnlocked, 1);
    _streak = _storage.getInt(_kStreak, 0);
    _lastPlayed = _storage.getString(_kLastPlayed);
    _adsRemoved = _storage.getBool(_kAdsRemoved, false);
  }

  Future<void> setTheme(int index) async {
    if (index == _themeIndex) return;
    _themeIndex = index;
    notifyListeners();
    await _storage.setInt(_kTheme, index);
  }

  /// Premium unlock (wired to RevenueCat/StoreKit later).
  Future<void> removeAds() async {
    _adsRemoved = true;
    notifyListeners();
    await _storage.setBool(_kAdsRemoved, true);
  }

  /// Called when a level is cleared: unlock the next one and bump the streak.
  Future<void> completeLevel(int levelNumber) async {
    var changed = false;
    if (levelNumber + 1 > _unlockedLevel) {
      _unlockedLevel = levelNumber + 1;
      await _storage.setInt(_kUnlocked, _unlockedLevel);
      changed = true;
    }
    changed = await _bumpStreak() || changed;
    if (changed) notifyListeners();
  }

  /// Returns true if the streak value changed.
  Future<bool> _bumpStreak() async {
    final now = DateTime.now();
    final today = _dateKey(now);
    if (_lastPlayed == today) return false; // already counted today

    final yesterday = _dateKey(now.subtract(const Duration(days: 1)));
    _streak = (_lastPlayed == yesterday) ? _streak + 1 : 1;
    _lastPlayed = today;
    await _storage.setInt(_kStreak, _streak);
    await _storage.setString(_kLastPlayed, today);
    return true;
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
