import 'package:flutter/foundation.dart';

import '../data/daily_rewards.dart';
import '../data/levels.dart';
import '../models/power_up.dart';
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
  static const _kNotifications = 'notificationsOn';
  static const _kTutorialSeen = 'tutorialSeen';
  static const _kDailyDone = 'dailyDoneDate';
  static const _kCoins = 'coins';
  static const _kHints = 'hints';
  static const _kRewardDay = 'rewardDay';
  static const _kRewardClaimed = 'rewardClaimedDate';
  static const _kRewardCycle = 'rewardCycle';
  static const _kLives = 'lives';
  static const _kNextLife = 'nextLifeMs';
  static const _kInfinite = 'infiniteUntilMs';
  static const _kStarsTotal = 'starsTotal';
  static const _kPiggy = 'piggyCoins';
  static const _kUsername = 'username';
  static const _kAvatar = 'avatarIndex';
  static const _kFrame = 'frameIndex';
  static const _kProfileDone = 'profileDone';
  static const _kLanguage = 'languageName';

  int _themeIndex = 0;
  int _unlockedLevel = 1; // highest level number the player may open
  int _streak = 0;
  String? _lastPlayed; // yyyy-mm-dd of last completed day
  bool _adsRemoved = false;

  bool _soundOn = true;
  bool _vibrationOn = true;
  bool _musicOn = true;
  bool _notificationsOn = true;
  bool _tutorialSeen = false;
  String? _dailyDone; // yyyy-mm-dd the daily challenge was last completed

  int _coins = 0;
  // Owned power-ups. Start at 0 — each is unlocked (and the first one granted)
  // at its introduction level (see [powerUnlockLevel]).
  int _hints = 0;
  int _erasers = 0;
  int _magics = 0;
  int _undos = 0;
  int _rewardDay = 0; // last claimed day in the 1..7 cycle (0 = none yet)
  String? _rewardClaimed; // yyyy-mm-dd of the last daily-reward claim
  int _rewardCycle = 0; // which weekly reward table is active (advances weekly)
  final Set<PowerUp> _seenIntros = {}; // power intros already shown

  // ---- Lives: a global, regenerating "energy" pool shared across the app ----
  static const int kMaxLives = 5;
  static const Duration kLifeRegen = Duration(minutes: 30);
  int _lives = kMaxLives;
  int _nextLifeMs = 0; // epoch ms when the next life regenerates (0 = full)
  int _infiniteUntilMs = 0; // epoch ms until infinite lives expire (0 = none)
  int _starsTotal = 0; // cached sum of best stars across all levels

  // ---- Piggy bank: coins accumulate here as you beat levels; "break" it to
  // collect them all at once (a coin sink / monetization hook). ----
  static const int kPiggyCap = 3500;
  static const int kPiggyBreakMin = 500; // minimum before it can be broken
  static const int kPiggyPerLevel = 50; // coins added per level cleared
  int _piggyCoins = 0;

  // ---- Player profile ----
  String? _username;
  int _avatarIndex = 0;
  int _frameIndex = 0;
  bool _profileDone = false; // shown the first-run name/avatar flow yet?
  // Display language. Currently a saved UI preference (the picker reflects it);
  // wiring it to full string translation is a future step.
  String _language = 'English';

  /// The level at which each power is introduced (gradual rollout).
  static const Map<PowerUp, int> _unlockLevel = {
    PowerUp.hint: 4,
    PowerUp.undo: 12,
    PowerUp.eraser: 24,
    PowerUp.magic: 38,
  };

  int powerUnlockLevel(PowerUp p) => _unlockLevel[p]!;

  /// A power is available once the player has reached its unlock level (playing
  /// it counts as reaching it, so it also works with debug level-jumps).
  bool isPowerUnlocked(PowerUp p, int currentLevel) {
    final reached = currentLevel > _unlockedLevel ? currentLevel : _unlockedLevel;
    return reached >= _unlockLevel[p]!;
  }

  bool hasSeenIntro(PowerUp p) => _seenIntros.contains(p);

  Future<void> markIntroSeen(PowerUp p) async {
    if (!_seenIntros.add(p)) return;
    notifyListeners();
    await _storage.setBool('intro_${p.storageKey}', true);
  }

  int get themeIndex => _themeIndex;
  int get unlockedLevel => _unlockedLevel;
  int get streak => _streak;
  bool get adsRemoved => _adsRemoved;
  bool get soundOn => _soundOn;
  bool get vibrationOn => _vibrationOn;
  bool get musicOn => _musicOn;
  bool get notificationsOn => _notificationsOn;
  bool get tutorialSeen => _tutorialSeen;
  int get coins => _coins;
  int get hints => _hints;
  int get rewardCycle => _rewardCycle;
  int get starTotal => _starsTotal;
  int get piggyCoins => _piggyCoins;
  bool get canBreakPiggy => _piggyCoins >= kPiggyBreakMin;

  // ---- Profile ----
  String get username => (_username?.isNotEmpty ?? false) ? _username! : 'Player';
  bool get hasUsername => _username != null && _username!.trim().isNotEmpty;
  int get avatarIndex => _avatarIndex;
  int get frameIndex => _frameIndex;
  bool get profileDone => _profileDone;
  String get language => _language;

  Future<void> setLanguage(String name) async {
    _language = name;
    notifyListeners();
    await _storage.setString(_kLanguage, name);
  }

  Future<void> setUsername(String name) async {
    _username = name.trim();
    notifyListeners();
    await _storage.setString(_kUsername, _username!);
  }

  Future<void> setAvatar(int index) async {
    _avatarIndex = index;
    notifyListeners();
    await _storage.setInt(_kAvatar, index);
  }

  Future<void> setFrame(int index) async {
    _frameIndex = index;
    notifyListeners();
    await _storage.setInt(_kFrame, index);
  }

  Future<void> markProfileDone() async {
    if (_profileDone) return;
    _profileDone = true;
    notifyListeners();
    await _storage.setBool(_kProfileDone, true);
  }

  /// Add coins to the piggy bank (capped).
  Future<void> addToPiggy(int n) async {
    if (n <= 0) return;
    _piggyCoins = (_piggyCoins + n).clamp(0, kPiggyCap);
    notifyListeners();
    await _storage.setInt(_kPiggy, _piggyCoins);
  }

  /// Smash the piggy: move all its coins into the spendable balance and reset.
  /// Returns the amount collected.
  Future<int> breakPiggy() async {
    final amount = _piggyCoins;
    if (amount <= 0) return 0;
    _piggyCoins = 0;
    _coins += amount;
    notifyListeners();
    await _storage.setInt(_kPiggy, 0);
    await _storage.setInt(_kCoins, _coins);
    return amount;
  }

  // ---- Lives API ----------------------------------------------------------

  /// True while a timed "infinite lives" bundle is active.
  bool get hasInfiniteLives =>
      _infiniteUntilMs > DateTime.now().millisecondsSinceEpoch;

  /// Current playable lives (shows full while infinite is active). Pure — never
  /// mutates state, so it is safe to read during build. [tick] persists regen.
  int get lives => hasInfiniteLives ? kMaxLives : _effectiveLives();

  /// Whether the player may start a level right now.
  bool get canPlay => hasInfiniteLives || lives > 0;

  int _effectiveLives() {
    if (_lives >= kMaxLives || _nextLifeMs == 0) {
      return _lives.clamp(0, kMaxLives);
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    var n = _lives;
    var next = _nextLifeMs;
    while (n < kMaxLives && next != 0 && now >= next) {
      n++;
      next += kLifeRegen.inMilliseconds;
    }
    return n.clamp(0, kMaxLives);
  }

  /// Time until the next life regenerates, or null when full / infinite.
  Duration? get timeToNextLife {
    if (hasInfiniteLives) return null;
    if (_effectiveLives() >= kMaxLives || _nextLifeMs == 0) return null;
    final now = DateTime.now().millisecondsSinceEpoch;
    var next = _nextLifeMs;
    while (next != 0 && now >= next) {
      next += kLifeRegen.inMilliseconds;
    }
    final ms = next - now;
    return ms > 0 ? Duration(milliseconds: ms) : Duration.zero;
  }

  /// Time left on the active infinite-lives bundle, or null if none.
  Duration? get infiniteRemaining {
    if (!hasInfiniteLives) return null;
    return Duration(
        milliseconds: _infiniteUntilMs - DateTime.now().millisecondsSinceEpoch);
  }

  /// Called ~once a second by the HUD ticker: bank any lives that regenerated
  /// and persist them. The per-second countdown itself is computed live by the
  /// HUD from [timeToNextLife]; this only fires storage writes when a whole
  /// life actually arrives.
  void tick() {
    if (hasInfiniteLives) return;
    final eff = _effectiveLives();
    if (eff == _lives) return;
    _lives = eff;
    if (_lives >= kMaxLives) {
      _nextLifeMs = 0;
    } else {
      final now = DateTime.now().millisecondsSinceEpoch;
      while (_nextLifeMs != 0 && now >= _nextLifeMs && _lives < kMaxLives) {
        _nextLifeMs += kLifeRegen.inMilliseconds;
      }
    }
    _storage.setInt(_kLives, _lives);
    _storage.setInt(_kNextLife, _nextLifeMs);
    notifyListeners();
  }

  /// Spend one life (on a level fail). Starts the regen clock if we were full.
  Future<void> loseLife() async {
    if (hasInfiniteLives) return;
    _lives = _effectiveLives();
    if (_lives >= kMaxLives || _nextLifeMs == 0) {
      _nextLifeMs =
          DateTime.now().millisecondsSinceEpoch + kLifeRegen.inMilliseconds;
    }
    _lives = (_lives - 1).clamp(0, kMaxLives);
    notifyListeners();
    await _storage.setInt(_kLives, _lives);
    await _storage.setInt(_kNextLife, _nextLifeMs);
  }

  /// Grant [n] lives (refill / purchase / reward), capped at the max.
  Future<void> addLives(int n) async {
    _lives = (_effectiveLives() + n).clamp(0, kMaxLives);
    if (_lives >= kMaxLives) {
      _nextLifeMs = 0;
    } else if (_nextLifeMs == 0) {
      _nextLifeMs =
          DateTime.now().millisecondsSinceEpoch + kLifeRegen.inMilliseconds;
    }
    notifyListeners();
    await _storage.setInt(_kLives, _lives);
    await _storage.setInt(_kNextLife, _nextLifeMs);
  }

  Future<void> refillLives() => addLives(kMaxLives);

  /// Start (or extend) a timed infinite-lives bundle.
  Future<void> grantInfiniteLives(Duration d) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final base = hasInfiniteLives ? _infiniteUntilMs : now;
    _infiniteUntilMs = base + d.inMilliseconds;
    notifyListeners();
    await _storage.setInt(_kInfinite, _infiniteUntilMs);
  }

  /// Owned count of a given power-up.
  int powerCount(PowerUp p) => switch (p) {
        PowerUp.hint => _hints,
        PowerUp.eraser => _erasers,
        PowerUp.magic => _magics,
        PowerUp.undo => _undos,
      };

  void _setPower(PowerUp p, int v) {
    switch (p) {
      case PowerUp.hint:
        _hints = v;
      case PowerUp.eraser:
        _erasers = v;
      case PowerUp.magic:
        _magics = v;
      case PowerUp.undo:
        _undos = v;
    }
  }

  Future<void> addPower(PowerUp p, int n) async {
    _setPower(p, powerCount(p) + n);
    notifyListeners();
    await _storage.setInt(p.storageKey, powerCount(p));
  }

  /// Consume one of [p]; returns true if one was available.
  Future<bool> usePower(PowerUp p) async {
    if (powerCount(p) <= 0) return false;
    _setPower(p, powerCount(p) - 1);
    notifyListeners();
    await _storage.setInt(p.storageKey, powerCount(p));
    return true;
  }

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
    _notificationsOn = _storage.getBool(_kNotifications, true);
    _tutorialSeen = _storage.getBool(_kTutorialSeen, false);
    _dailyDone = _storage.getString(_kDailyDone);
    _coins = _storage.getInt(_kCoins, 0);
    _hints = _storage.getInt(_kHints, 0);
    _erasers = _storage.getInt(PowerUp.eraser.storageKey, 0);
    _magics = _storage.getInt(PowerUp.magic.storageKey, 0);
    _undos = _storage.getInt(PowerUp.undo.storageKey, 0);
    _rewardDay = _storage.getInt(_kRewardDay, 0);
    _rewardClaimed = _storage.getString(_kRewardClaimed);
    _rewardCycle = _storage.getInt(_kRewardCycle, 0);
    for (final p in PowerUp.values) {
      if (_storage.getBool('intro_${p.storageKey}', false)) _seenIntros.add(p);
    }
    _lives = _storage.getInt(_kLives, kMaxLives);
    _nextLifeMs = _storage.getInt(_kNextLife, 0);
    _infiniteUntilMs = _storage.getInt(_kInfinite, 0);
    _piggyCoins = _storage.getInt(_kPiggy, 0);
    _username = _storage.getString(_kUsername);
    _avatarIndex = _storage.getInt(_kAvatar, 0);
    _frameIndex = _storage.getInt(_kFrame, 0);
    _profileDone = _storage.getBool(_kProfileDone, false);
    _language = _storage.getString(_kLanguage) ?? 'English';
    // Star total is cached; on first run (or upgrade) seed it by summing once.
    _starsTotal = _storage.getInt(_kStarsTotal, -1);
    if (_starsTotal < 0) {
      _starsTotal = totalStars(kLevelCount);
      _storage.setInt(_kStarsTotal, _starsTotal);
    }
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

  // Back-compat helpers for hints (delegate to the generic power inventory).
  Future<void> addHints(int n) => addPower(PowerUp.hint, n);
  Future<bool> useHint() => usePower(PowerUp.hint);

  /// Claim today's daily reward (from the current weekly table). Returns the
  /// granted reward, or null if it was already claimed today. Completing Day 7
  /// advances to the next week's table.
  Future<DailyReward?> claimDailyReward() async {
    if (!canClaimDaily) return null;
    final day = offeredRewardDay;
    final reward = rewardForDay(day, _rewardCycle);
    _rewardDay = day;
    _rewardClaimed = _dateKey(DateTime.now());

    if (reward.isCoins) {
      _coins += reward.amount;
      await _storage.setInt(_kCoins, _coins);
    } else {
      final p = reward.power!;
      _setPower(p, powerCount(p) + reward.amount);
      await _storage.setInt(p.storageKey, powerCount(p));
    }
    // Finishing the week rotates to a fresh reward table next time.
    if (day >= 7) {
      _rewardCycle++;
      await _storage.setInt(_kRewardCycle, _rewardCycle);
    }

    notifyListeners();
    await _storage.setInt(_kRewardDay, _rewardDay);
    await _storage.setString(_kRewardClaimed, _rewardClaimed!);
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

  Future<void> setNotifications(bool on) async {
    _notificationsOn = on;
    notifyListeners();
    await _storage.setBool(_kNotifications, on);
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

  /// Record a star rating for a level, keeping the best result. Also keeps the
  /// cached [starTotal] in sync by adding only the improvement.
  Future<void> recordStars(int levelNumber, int stars) async {
    final clamped = stars.clamp(0, 3);
    final prev = starsFor(levelNumber);
    if (clamped <= prev) return;
    await _storage.setInt('stars_$levelNumber', clamped);
    _starsTotal += clamped - prev;
    await _storage.setInt(_kStarsTotal, _starsTotal);
    notifyListeners();
  }

  /// Called when a level is cleared: unlock the next one and bump the streak.
  Future<void> completeLevel(int levelNumber) async {
    var changed = false;
    if (levelNumber + 1 > _unlockedLevel) {
      _unlockedLevel = levelNumber + 1;
      await _storage.setInt(_kUnlocked, _unlockedLevel);
      // First clear of a new level drops some coins into the piggy bank.
      _piggyCoins = (_piggyCoins + kPiggyPerLevel).clamp(0, kPiggyCap);
      await _storage.setInt(_kPiggy, _piggyCoins);
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