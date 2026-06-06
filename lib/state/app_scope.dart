import 'package:flutter/widgets.dart';

import '../data/palettes.dart';
import 'app_state.dart';

/// Exposes [AppState] to the widget tree and rebuilds dependents when it
/// notifies (theme change, progress, etc.).
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  /// Use in `build` — establishes a dependency so the widget rebuilds.
  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in the widget tree');
    return scope!.notifier!;
  }

  /// Use in callbacks — reads without subscribing.
  static AppState read(BuildContext context) {
    final element =
        context.getElementForInheritedWidgetOfExactType<AppScope>();
    return (element!.widget as AppScope).notifier!;
  }
}

extension AppContext on BuildContext {
  AppState get appState => AppScope.of(this);
  AppPalette get palette =>
      kPalettes[AppScope.of(this).themeIndex.clamp(0, kPalettes.length - 1)];
  ArrowScheme get arrowScheme =>
      kArrowSchemes[AppScope.of(this).arrowSchemeIndex.clamp(0, kArrowSchemes.length - 1)];
}
