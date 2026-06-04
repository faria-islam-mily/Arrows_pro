import '../models/power_up.dart';

/// The 7-day daily-streak reward — now with FOUR weekly tables that rotate
/// (Week 1 → 2 → 3 → 4 → 1 …) so consecutive weeks never give the same set.
/// Rewards mix coins with every power-up, plus a growing coin chest on Day 7.
enum RewardKind { coins, hint, eraser, magic, undo }

class DailyReward {
  const DailyReward(this.day, this.kind, this.amount);

  final int day; // 1..7
  final RewardKind kind;
  final int amount;

  bool get isCoins => kind == RewardKind.coins;

  /// The power this reward grants, or null for coins.
  PowerUp? get power => switch (kind) {
        RewardKind.coins => null,
        RewardKind.hint => PowerUp.hint,
        RewardKind.eraser => PowerUp.eraser,
        RewardKind.magic => PowerUp.magic,
        RewardKind.undo => PowerUp.undo,
      };

  /// Short label for the reward cell ("60", "1 Hint", "2 Erasers").
  String get label {
    if (isCoins) return '$amount';
    final name = power!.label;
    return amount > 1 ? '$amount ${name}s' : '1 $name';
  }
}

const List<List<DailyReward>> _weeks = [
  // Week 1
  [
    DailyReward(1, RewardKind.coins, 25),
    DailyReward(2, RewardKind.hint, 1),
    DailyReward(3, RewardKind.coins, 40),
    DailyReward(4, RewardKind.magic, 1),
    DailyReward(5, RewardKind.coins, 60),
    DailyReward(6, RewardKind.undo, 1),
    DailyReward(7, RewardKind.coins, 150),
  ],
  // Week 2
  [
    DailyReward(1, RewardKind.coins, 30),
    DailyReward(2, RewardKind.eraser, 1),
    DailyReward(3, RewardKind.hint, 1),
    DailyReward(4, RewardKind.coins, 55),
    DailyReward(5, RewardKind.magic, 1),
    DailyReward(6, RewardKind.coins, 80),
    DailyReward(7, RewardKind.coins, 180),
  ],
  // Week 3
  [
    DailyReward(1, RewardKind.coins, 30),
    DailyReward(2, RewardKind.undo, 1),
    DailyReward(3, RewardKind.coins, 45),
    DailyReward(4, RewardKind.eraser, 1),
    DailyReward(5, RewardKind.hint, 2),
    DailyReward(6, RewardKind.coins, 90),
    DailyReward(7, RewardKind.coins, 200),
  ],
  // Week 4
  [
    DailyReward(1, RewardKind.hint, 1),
    DailyReward(2, RewardKind.coins, 35),
    DailyReward(3, RewardKind.magic, 1),
    DailyReward(4, RewardKind.coins, 60),
    DailyReward(5, RewardKind.eraser, 1),
    DailyReward(6, RewardKind.undo, 1),
    DailyReward(7, RewardKind.coins, 220),
  ],
];

/// Number of distinct weekly tables before they repeat.
int get rewardWeekCount => _weeks.length;

/// The reward for [day] (1..7) in week [cycle] (0-based, wraps).
DailyReward rewardForDay(int day, [int cycle = 0]) {
  final week = _weeks[cycle % _weeks.length];
  return week[(day - 1).clamp(0, 6)];
}
