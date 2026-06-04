import 'package:flutter/material.dart';

import '../theme/app_images.dart';

/// A selectable profile avatar. [asset] is the 3D art; [emoji] is the fallback
/// shown until that art is added.
class GameAvatar {
  const GameAvatar(this.asset, this.emoji);
  final String asset;
  final String emoji;
}

const String _base = 'assets/images';

/// Avatar choices. Index 0 uses the art we already have; the rest fall back to
/// emoji until their PNGs are dropped in `assets/images/`.
const List<GameAvatar> kAvatars = [
  GameAvatar(AppImages.avatarPlayer, '🐤'),
  GameAvatar('$_base/avatar_chicken.png', '🐔'),
  GameAvatar('$_base/avatar_llama.png', '🦙'),
  GameAvatar('$_base/avatar_raccoon.png', '🦝'),
  GameAvatar('$_base/avatar_duck.png', '🦆'),
  GameAvatar('$_base/avatar_cow.png', '🐮'),
  GameAvatar('$_base/avatar_parrot.png', '🦜'),
  GameAvatar('$_base/avatar_pug.png', '🐶'),
  GameAvatar('$_base/avatar_sheep.png', '🐑'),
];

/// A coloured avatar frame. Locked ones need to be unlocked later (placeholder).
class ProfileFrame {
  const ProfileFrame(this.color, {this.unlocked = false});
  final Color color;
  final bool unlocked;
}

const List<ProfileFrame> kFrames = [
  ProfileFrame(Color(0xFFFFC02E), unlocked: true), // gold
  ProfileFrame(Color(0xFF58C42B), unlocked: true), // green
  ProfileFrame(Colors.white, unlocked: true), // white
  ProfileFrame(Color(0xFFE5524A)), // red (locked)
  ProfileFrame(Color(0xFF3E7BE8)), // blue (locked)
  ProfileFrame(Color(0xFFE85C9A)), // pink (locked)
  ProfileFrame(Color(0xFFF2A33C)), // orange (locked)
  ProfileFrame(Color(0xFF8B45D6)), // purple (locked)
  ProfileFrame(Color(0xFF2AB7B7)), // teal (locked)
];

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
