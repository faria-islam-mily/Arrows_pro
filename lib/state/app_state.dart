import 'package:flutter/foundation.dart';

import '../data/daily_rewards.dart';
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
  static const _kCoins = 'coins';
  static const _kHints = 'hints';
  static const _kRewardDay = 'rewardDay';
  static const _kRewardClaimed = 'rewardClaimedDate';

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

  int _coins = 0;
  int _hints = 1; // start with one free hint
  int _rewardDay = 0; // last claimed day in the 1..7 cycle (0 = none yet)
  String? _rewardClaimed; // yyyy-mm-dd of the last daily-reward claim

  int get themeIndex => _themeIndex;
  int get unlockedLevel => _unlockedLevel;
  int get streak => _streak;
  bool get adsRemoved => _adsRemoved;
  bool get soundOn => _soundOn;
  bool get vibrationOn => _vibrationOn;
  bool get musicOn => _musicOn;
  bool get tutorialSeen => _tutorialSeen;
  int get coins => _coins;
  int get hints => _hints;

  /// Today's daily reward can still be collected.
  bool get canClaimDaily => _rewardClaimed != _dateKey(DateTime.now());

  /// Which day of the 1..7 cycle is offered today (advances if yesterday was
  /// claimed, restarts at 1 on a first visit or a missed day).
  int get offeredRewardDay {
    final now = _dateKey(DateTime.now());
    final yesterday = _dateKey(DateTime.now().subtract(const Duration(days: 1)));
    if (_rewardClaimed == now) return _rewardDay; // already claimed today
    if (_rewardClaimed == yesterday) return _rewardDay >= 7 ? 1 : _rewardDay + 1;
    return 1; // first visit or a broken streak → restart the cycle
  }

  /// DEBUG: set true to unlock every level for testing. Flip back to false
  /// before release.
  static const bool debugUnlockAll = false;

  bool isUnlocked(int levelNumber) =>
      debugUnlockAll || levelNumber <= _unlockedLevel;

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
    // One-time migration: the premium "Arcade" dark theme is the new default.
    // Force it once for anyone whose saved index pointed at an old palette,
    // then respect their choice from then on.
    if (_storage.getInt('themeMigratedV2', 0) == 0) {
      _storage.setInt('themeMigratedV2', 1);
      _storage.setInt(_kTheme, 0);
    }
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
    _coins = _storage.getInt(_kCoins, 0);
    _hints = _storage.getInt(_kHints, 1);
    _rewardDay = _storage.getInt(_kRewardDay, 0);
    _rewardClaimed = _storage.getString(_kRewardClaimed);
  }

  Future<void> addCoins(int n) async {
    if (n == 0) return;
    _coins += n;
    notifyListeners();
    await _storage.setInt(_kCoins, _coins);
  }

  /// Spend coins if affordable; returns true on success.
  Future<bool> spendCoins(int n) async {
    if (_coins < n) return false;
    _coins -= n;
    notifyListeners();
    await _storage.setInt(_kCoins, _coins);
    return true;
  }

  Future<void> addHints(int n) async {
    _hints += n;
    notifyListeners();
    await _storage.setInt(_kHints, _hints);
  }

  /// Consume one hint token; returns true if one was available.
  Future<bool> useHint() async {
    if (_hints <= 0) return false;
    _hints -= 1;
    notifyListeners();
    await _storage.setInt(_kHints, _hints);
    return true;
  }

  /// Claim today's daily reward. Returns the granted reward, or null if it was
  /// already claimed today.
  Future<DailyReward?> claimDailyReward() async {
    if (!canClaimDaily) return null;
    final day = offeredRewardDay;
    final reward = rewardForDay(day);
    _rewardDay = day;
    _rewardClaimed = _dateKey(DateTime.now());
    if (reward.isCoins) {
      _coins += reward.amount;
    } else {
      _hints += reward.amount;
    }
    notifyListeners();
    await _storage.setInt(_kRewardDay, _rewardDay);
    await _storage.setString(_kRewardClaimed, _rewardClaimed!);
    await _storage.setInt(_kCoins, _coins);
    await _storage.setInt(_kHints, _hints);
    return reward;
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