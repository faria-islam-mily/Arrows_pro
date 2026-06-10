import 'package:flutter/material.dart';

import '../theme/app_images.dart';

/// A selectable profile avatar. [asset] is the 3D art; [emoji] is the fallback
/// shown until that art is added. Unlocks at [unlockLevel].
class GameAvatar {
  const GameAvatar(this.asset, this.emoji, this.unlockLevel);
  final String asset;
  final String emoji;
  final int unlockLevel;
}

const String _base = 'assets/images';

/// Avatar choices, unlocking as the player progresses. Index 0 uses the art we
/// already have; the rest fall back to emoji until their PNGs are dropped in.
const List<GameAvatar> kAvatars = [
  GameAvatar(AppImages.avatarPlayer, '🐹', 1),
  GameAvatar('$_base/avatar_chicken.png', '🐔', 1),
  GameAvatar('$_base/avatar_llama.png', '🦙', 4),
  GameAvatar('$_base/avatar_raccoon.png', '🦝', 8),
  GameAvatar('$_base/avatar_duck.png', '🦆', 13),
  GameAvatar('$_base/avatar_cow.png', '🐮', 20),
  GameAvatar('$_base/avatar_parrot.png', '🦜', 28),
  GameAvatar('$_base/avatar_pug.png', '🐶', 38),
  GameAvatar('$_base/avatar_sheep.png', '🐑', 50),
];

/// A coloured avatar frame (drawn as the ring around the avatar — no assets).
class ProfileFrame {
  const ProfileFrame(this.color, this.unlockLevel);
  final Color color;
  final int unlockLevel;
}

const List<ProfileFrame> kFrames = [
  ProfileFrame(Color(0xFFFFC02E), 1), // gold
  ProfileFrame(Color(0xFF58C42B), 1), // green
  ProfileFrame(Colors.white, 1), // white
  ProfileFrame(Color(0xFFE5524A), 6), // red
  ProfileFrame(Color(0xFF3E7BE8), 11), // blue
  ProfileFrame(Color(0xFFE85C9A), 17), // pink
  ProfileFrame(Color(0xFFF2A33C), 24), // orange
  ProfileFrame(Color(0xFF8B45D6), 32), // purple
  ProfileFrame(Color(0xFF2AB7B7), 42), // teal
];

/// A collectible badge — a gradient emblem with an icon (no assets). The chosen
/// one shows as a small corner emblem on the player's avatar.
class ProfileBadge {
  const ProfileBadge(this.icon, this.colors, this.unlockLevel);
  final IconData icon;
  final List<Color> colors; // gradient
  final int unlockLevel;
}

const List<ProfileBadge> kBadges = [
  ProfileBadge(Icons.star_rounded, [Color(0xFFFFD23F), Color(0xFFF2A33C)], 1),
  ProfileBadge(Icons.bolt_rounded, [Color(0xFF6FD63B), Color(0xFF2E9E1C)], 3),
  ProfileBadge(Icons.local_fire_department_rounded,
      [Color(0xFFFF8A3D), Color(0xFFE5524A)], 7),
  ProfileBadge(Icons.workspace_premium_rounded,
      [Color(0xFF5AC8FF), Color(0xFF2D6CDF)], 12),
  ProfileBadge(
      Icons.emoji_events_rounded, [Color(0xFFFFD23F), Color(0xFFE0941C)], 18),
  ProfileBadge(Icons.shield_rounded, [Color(0xFFB97BFF), Color(0xFF6E33B0)], 25),
  ProfileBadge(
      Icons.rocket_launch_rounded, [Color(0xFFFF6FB5), Color(0xFFD23F84)], 33),
  ProfileBadge(Icons.diamond_rounded, [Color(0xFF49E0C0), Color(0xFF1B9AAA)], 43),
  ProfileBadge(
      Icons.military_tech_rounded, [Color(0xFFFFC02E), Color(0xFFB5761F)], 55),
];

/// True if any avatar/frame/badge unlocks in the window (seenLevel, reachedLevel]
/// — i.e. something new became available that the player hasn't acknowledged.
bool hasNewProfileUnlock(int seenLevel, int reachedLevel) {
  bool fresh(int u) => u > seenLevel && u <= reachedLevel;
  return kAvatars.any((a) => fresh(a.unlockLevel)) ||
      kFrames.any((f) => fresh(f.unlockLevel)) ||
      kBadges.any((b) => fresh(b.unlockLevel));
}

const List<String> _adjectives = [
  'Happy', 'Lucky', 'Swift', 'Brave', 'Cool', 'Mega', 'Super', 'Jolly',
  'Witty', 'Sunny', 'Turbo', 'Cosmic', 'Sneaky', 'Mighty', 'Royal',
];
const List<String> _animals = [
  'Tiger', 'Panda', 'Otter', 'Fox', 'Koala', 'Hippo', 'Dragon', 'Bunny',
  'Wolf', 'Cat', 'Duck', 'Llama', 'Raccoon', 'Penguin', 'Shark',
];

/// A fun random username derived from [seed] (e.g. millisecondsSinceEpoch).
String randomUsername(int seed) {
  final a = _adjectives[seed % _adjectives.length];
  final n = _animals[(seed ~/ 7) % _animals.length];
  return '$a$n${seed % 1000}';
}
