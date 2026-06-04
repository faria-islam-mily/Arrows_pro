import 'package:flutter/material.dart';

import '../theme/app_images.dart';

/// A themed "world" — a band of [kLevelsPerWorld] levels with its own
/// full-screen background scene. Worlds cycle, so a fresh one appears every
/// [kLevelsPerWorld] levels all the way up the map.
class GameWorld {
  const GameWorld({
    required this.name,
    required this.emoji,
    required this.color,
    required this.background,
    required this.avatar,
  });

  final String name;
  final String emoji;
  final Color color;
  final String background; // full-screen scene asset (jpg)
  final String avatar; // round mascot for the right rail
}

/// A new world unlocks every this many levels.
const int kLevelsPerWorld = 50;

const List<GameWorld> kWorlds = [
  GameWorld(name: 'Sandy Shore', emoji: '🏖️', color: Color(0xFFF2B14C), background: AppImages.bgSandyShore, avatar: AppImages.worldSandyShore),
  GameWorld(name: 'Crab Cove', emoji: '🦀', color: Color(0xFFE8694C), background: AppImages.bgCrabCove, avatar: AppImages.worldCrabCove),
  GameWorld(name: 'Pool Party', emoji: '🏊', color: Color(0xFF3FB6E8), background: AppImages.bgPoolParty, avatar: AppImages.worldPoolParty),
  GameWorld(name: 'Night City', emoji: '🌃', color: Color(0xFF5B5BE6), background: AppImages.bgNightCity, avatar: AppImages.worldNightCity),
  GameWorld(name: 'Frostpeak', emoji: '🏔️', color: Color(0xFF7FD0E8), background: AppImages.bgFrostpeak, avatar: AppImages.worldFrostpeak),
  GameWorld(name: 'Deep Space', emoji: '🚀', color: Color(0xFF8B45D6), background: AppImages.bgDeepSpace, avatar: AppImages.worldDeepSpace),
];

/// The 0-based world band that [level] belongs to.
int worldBand(int level) => (level - 1) ~/ kLevelsPerWorld;

/// The world shown for a 0-based [band] index (cycles through [kWorlds]).
GameWorld worldForBand(int band) => kWorlds[band % kWorlds.length];

/// The world for a given [level].
GameWorld worldForLevel(int level) => worldForBand(worldBand(level));

/// The first level of a 0-based [band].
int bandStartLevel(int band) => band * kLevelsPerWorld + 1;
