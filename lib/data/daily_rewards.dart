/// The 7-day daily-streak reward cycle (repeats). Many small rewards — coins
/// most days, hint tokens on a couple, a bigger coin "chest" on day 7.
enum RewardKind { coins, hint }

class DailyReward {
  const DailyReward(this.day, this.kind, this.amount);

  final int day; // 1..7
  final RewardKind kind;
  final int amount;

  bool get isCoins => kind == RewardKind.coins;
  String get label =>
      isCoins ? '$amount' : '$amount Hint${amount > 1 ? 's' : ''}';
}

const List<DailyReward> kDailyRewards = [
  DailyReward(1, RewardKind.coins, 25),
  DailyReward(2, RewardKind.coins, 40),
  DailyReward(3, RewardKind.hint, 1),
  DailyReward(4, RewardKind.coins, 60),
  DailyReward(5, RewardKind.coins, 80),
  DailyReward(6, RewardKind.hint, 2),
  DailyReward(7, RewardKind.coins, 150), // big chest
];

DailyReward rewardForDay(int day) => kDailyRewards[(day - 1).clamp(0, 6)];
