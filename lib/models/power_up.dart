/// The four power-ups the player owns as inventory items.
enum PowerUp { hint, eraser, magic, undo }

/// How many a "GET x3" bundle grants.
const int kPowerBundleAmount = 3;

extension PowerUpInfo on PowerUp {
  String get label => switch (this) {
        PowerUp.hint => 'Hint',
        PowerUp.eraser => 'Eraser',
        PowerUp.magic => 'Magic',
        PowerUp.undo => 'Undo',
      };

  /// shared_preferences key for the owned count.
  String get storageKey => switch (this) {
        PowerUp.hint => 'hints',
        PowerUp.eraser => 'erasers',
        PowerUp.magic => 'magics',
        PowerUp.undo => 'undos',
      };

  /// Coins for a x3 bundle — scaled by how strong the power is.
  int get bundlePrice => switch (this) {
        PowerUp.hint => 90,
        PowerUp.eraser => 120,
        PowerUp.magic => 75,
        PowerUp.undo => 60,
      };
}
