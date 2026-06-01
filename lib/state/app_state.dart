import 'package:flutter/foundation.dart';

import 'storage.dart';

/// Persistent app-wide state: selected theme, level progress, daily streak,
/// the premium "remove ads" flag, plus settings toggles, first-run tutorial
/// flag, per-level star ratings, and daily-challenge tracking.
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
  static const _kSound = 'soundOn';
  static const _kVibration = 'vibrationOn';
  static const _kMusic = 'musicOn';
  static const _kTutorialSeen = 'tutorialSeen';
  static const _kDailyDone = 'dailyDoneDate';

  int _themeIndex = 0;
  int _unlockedLevel = 1; // highest level number the player may open
  int _streak = 0;
  String? _lastPlayed; // yyyy-mm-dd of last completed day
  bool _adsRemoved = false;

  bool _soundOn = true;
  bool _vibrationOn = true;
  bool _musicOn = true;
  bool _tutorialSeen = false;
  String? _dailyDone; // yyyy-mm-dd the daily challenge was last completed

  int get themeIndex => _themeIndex;
  int get unlockedLevel => _unlockedLevel;
  int get streak => _streak;
  bool get adsRemoved => _adsRemoved;
  bool get soundOn => _soundOn;
  bool get vibrationOn => _vibrationOn;
  bool get musicOn => _musicOn;
  bool get tutorialSeen => _tutorialSeen;

  bool isUnlocked(int levelNumber) => levelNumber <= _unlockedLevel;

  /// Best star rating earned for [levelNumber] (0 = not yet cleared).
  int starsFor(int levelNumber) => _storage.getInt('stars_$levelNumber', 0);

  /// Total stars across the whole pack — handy for a progress header.
  int totalStars(int levelCount) {
    var sum = 0;
    for (var n = 1; n <= levelCount; n++) {
      sum += starsFor(n);
    }
    return sum;
  }

  bool get dailyDoneToday => _dailyDone == _dateKey(DateTime.now());

  void _load() {
    _themeIndex = _storage.getInt(_kTheme, 0);
    _unlockedLevel = _storage.getInt(_kUnlocked, 1);
    _streak = _storage.getInt(_kStreak, 0);
    _lastPlayed = _storage.getString(_kLastPlayed);
    _adsRemoved = _storage.getBool(_kAdsRemoved, false);
    _soundOn = _storage.getBool(_kSound, true);
    _vibrationOn = _storage.getBool(_kVibration, true);
    _musicOn = _storage.getBool(_kMusic, true);
    _tutorialSeen = _storage.getBool(_kTutorialSeen, false);
    _dailyDone = _storage.getString(_kDailyDone);
  }

  Future<void> setTheme(int index) async {
    if (index == _themeIndex) return;
    _themeIndex = index;
    notifyListeners();
    await _storage.setInt(_kTheme, index);
  }

  Future<void> setSound(bool on) async {
    _soundOn = on;
    notifyListeners();
    await _storage.setBool(_kSound, on);
  }

  Future<void> setVibration(bool on) async {
    _vibrationOn = on;
    notifyListeners();
    await _storage.setBool(_kVibration, on);
  }

  Future<void> setMusic(bool on) async {
    _musicOn = on;
    notifyListeners();
    await _storage.setBool(_kMusic, on);
  }

  Future<void> markTutorialSeen() async {
    if (_tutorialSeen) return;
    _tutorialSeen = true;
    notifyListeners();
    await _storage.setBool(_kTutorialSeen, true);
  }

  /// Premium unlock (wired to RevenueCat/StoreKit later).
  Future<void> removeAds() async {
    _adsRemoved = true;
    notifyListeners();
    await _storage.setBool(_kAdsRemoved, true);
  }

  /// Record a star rating for a level, keeping the best result.
  Future<void> recordStars(int levelNumber, int stars) async {
    final clamped = stars.clamp(0, 3);
    if (clamped <= starsFor(levelNumber)) return;
    await _storage.setInt('stars_$levelNumber', clamped);
    notifyListeners();
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

  /// Mark today's daily challenge as completed (also counts toward the streak).
  Future<void> markDailyDone() async {
    final today = _dateKey(DateTime.now());
    if (_dailyDone == today) return;
    _dailyDone = today;
    await _storage.setString(_kDailyDone, today);
    await _bumpStreak();
    notifyListeners();
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