import 'package:flutter/material.dart';

/// Bundled font families (all SIL Open Font License). Nothing is fetched at
/// runtime.
abstract final class Fonts {
  static const sans = 'Inter';
  static const serif = 'SourceSerif4';
  static const mono = 'JetBrainsMono';
}

/// The six text styles of the design system (BLUEPRINT 9.2). Sizes are in
/// logical pixels and scale with the system font size.
abstract final class DocNookText {
  /// Large serif title: Home, Files and Tools only.
  static const screenTitle = TextStyle(
    fontFamily: Fonts.serif,
    fontSize: 28,
    height: 34 / 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  static const sectionTitle = TextStyle(
    fontFamily: Fonts.sans,
    fontSize: 17,
    height: 24 / 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
  );

  static const body = TextStyle(
    fontFamily: Fonts.sans,
    fontSize: 15,
    height: 22 / 15,
    fontWeight: FontWeight.w400,
  );

  /// Body weight for names in lists: same size, slightly heavier.
  static const bodyStrong = TextStyle(
    fontFamily: Fonts.sans,
    fontSize: 15,
    height: 22 / 15,
    fontWeight: FontWeight.w500,
  );

  static const label = TextStyle(
    fontFamily: Fonts.sans,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w500,
  );

  static const caption = TextStyle(
    fontFamily: Fonts.sans,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
  );

  static const mono = TextStyle(
    fontFamily: Fonts.mono,
    fontSize: 13,
    height: 20 / 13,
    fontWeight: FontWeight.w400,
  );

  /// Maps the styles onto Material's slots so stock widgets (dialogs, text
  /// fields, menus) pick up the same type without per-widget overrides.
  static TextTheme textTheme(Color ink, Color inkMuted) => TextTheme(
    headlineMedium: screenTitle.copyWith(color: ink),
    headlineSmall: screenTitle.copyWith(color: ink, fontSize: 22, height: 28 / 22),
    titleLarge: sectionTitle.copyWith(color: ink, fontSize: 19, height: 26 / 19),
    titleMedium: sectionTitle.copyWith(color: ink),
    titleSmall: bodyStrong.copyWith(color: ink),
    bodyLarge: body.copyWith(color: ink),
    bodyMedium: body.copyWith(color: ink),
    bodySmall: caption.copyWith(color: inkMuted),
    labelLarge: label.copyWith(color: ink, fontSize: 14, height: 20 / 14),
    labelMedium: label.copyWith(color: ink),
    labelSmall: caption.copyWith(color: inkMuted),
  );
}
