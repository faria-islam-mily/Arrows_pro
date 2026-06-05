import 'package:flutter/material.dart';

import '../data/palettes.dart';
import '../l10n/strings.dart';
import '../state/app_scope.dart';

/// Opens a bottom sheet to switch themes (incl. the eye-friendly dark option).
Future<void> showThemePicker(BuildContext context) {
  final state = AppScope.read(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.palette.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.theme,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: context.palette.arrow,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (var i = 0; i < kPalettes.length; i++)
                    _Swatch(
                      palette: kPalettes[i],
                      selected: state.themeIndex == i,
                      onTap: () {
                        state.setTheme(i);
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final AppPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: palette.background,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? palette.primary : Colors.black12,
                width: selected ? 4 : 2,
              ),
            ),
            child: Center(
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: palette.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(palette.name, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
