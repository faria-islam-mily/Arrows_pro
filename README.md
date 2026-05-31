# Arrow Pro

A calm, **premium** arrow-escape puzzle game. Inspired by the "Arrows" genre,
rebuilt as a clean, ad-free, polished experience.

## The game

The board is packed with arrows arranged into a picture (heart, sunglasses,
abstract shapes). Tap an arrow and it slides in the direction it points — but it
can only **escape the board if its path to the edge is clear**. Find the right
order to clear every arrow. As they leave, the picture dissolves.

Positioning: relaxing / mindful — *"play a little daily, sleep better."*

## What makes it "Pro" (the premium angle)

- **No ads, no energy timers** — a one-time purchase or clean subscription.
- Polished slide-out animations + haptics.
- Handcrafted picture levels, multiple color themes (incl. eye-friendly mode).
- Daily streaks, hints, and difficulty tiers.

## Project structure

```
lib/
  main.dart                  App entry
  theme/app_theme.dart       Calm premium palette + theme
  models/
    grid_arrow.dart          Arrow (position + direction + state)
    level.dart               Level definition (grid size + arrow factory)
  data/levels.dart           Hand-authored starter level pack
  game/game_controller.dart  Rules: canExit / tap / hint + solvability check
  widgets/arrow_tile.dart    A single tappable arrow
  screens/
    home_screen.dart         Level select
    game_screen.dart         The board, lives, hint, progress, win/fail
test/
  levels_solvable_test.dart  Asserts every shipped level is solvable
```

## Running it

Flutter SDK is required (currently installing on this machine). Once ready:

```powershell
cd "e:\mily app\arrow_pro"
flutter create .      # generates android/ ios/ etc. — keeps existing lib/
flutter pub get
flutter test          # verify levels + logic
flutter run           # launch on a device/emulator
```

> `flutter create .` only fills in *missing* files (the platform folders), so it
> will not overwrite the hand-written code in `lib/`, `test/`, or `pubspec.yaml`.

> Built on Windows, targeting iOS + Android. iOS builds still require a Mac (or
> a CI service like Codemagic) to produce/sign an `.ipa`.

## Level design notes

The starter pack uses the **"outward" design family** (left side points left,
right side right, top up, bottom down) plus same-direction stacks. That
guarantees a clear-from-the-edge solution. New, more interlocking levels should
be validated with `GameController.solvable(level)` — the test suite already does
this for every level in `kLevels`.

## Monetization (planned model)

**Free + ads + IAP** (matches how the genre actually converts):

- Rewarded-ad hints + interstitials between levels.
- A **"Remove Ads"** IAP — groundwork is in `AppState.adsRemoved` /
  `AppState.removeAds()`; wire it to RevenueCat/StoreKit later.

## Themes & persistence (done)

- 4 themes incl. an eye-friendly **Midnight** dark mode — `lib/data/palettes.dart`,
  switched via the palette button on Home (`lib/widgets/theme_picker.dart`).
- State persists with `shared_preferences` (`lib/state/`): selected theme,
  highest unlocked level (levels lock until reached), and a **daily streak**
  (consecutive-day counter shown on Home).

## Roadmap

- [x] Themes + eye-friendly mode toggle
- [x] Daily streak + progress persistence (shared_preferences)
- [ ] Picture-shaped levels (heart, glasses) like the reference apps
- [ ] Level editor + JSON-based level loading
- [ ] Sound + music with settings toggles
- [ ] Ads + Remove-Ads IAP (RevenueCat / Google + Apple)
