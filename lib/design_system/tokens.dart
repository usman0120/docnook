import 'package:docnook/domain/entities/doc_type.dart';
import 'package:flutter/material.dart';

/// "Paper and ink" colour tokens (BLUEPRINT 9.1). Screens read colours only
/// through `context.colors`; no raw colour values appear outside this file.
@immutable
final class DocNookColors extends ThemeExtension<DocNookColors> {
  const DocNookColors({
    required this.paper,
    required this.surface,
    required this.surfaceSunken,
    required this.ink,
    required this.inkMuted,
    required this.hairline,
    required this.primary,
    required this.onPrimary,
    required this.accent,
    required this.danger,
    required this.success,
    required this.scrim,
    required this.brightness,
  });

  static const light = DocNookColors(
    paper: Color(0xFFF7F5F0),
    surface: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFEFECE4),
    ink: Color(0xFF1C1B19),
    inkMuted: Color(0xFF5F5B53),
    hairline: Color(0xFFE4E0D6),
    primary: Color(0xFF1F3A4D),
    onPrimary: Color(0xFFFFFFFF),
    accent: Color(0xFFB57A1F),
    danger: Color(0xFFB3261E),
    success: Color(0xFF2E6B3F),
    scrim: Color(0x661C1B19),
    brightness: Brightness.light,
  );

  static const dark = DocNookColors(
    paper: Color(0xFF141413),
    surface: Color(0xFF1D1C1A),
    surfaceSunken: Color(0xFF23221F),
    ink: Color(0xFFECE9E2),
    inkMuted: Color(0xFFA8A398),
    hairline: Color(0xFF2E2C28),
    primary: Color(0xFF9CC0D3),
    onPrimary: Color(0xFF0E1A22),
    accent: Color(0xFFE0A84A),
    danger: Color(0xFFF2B8B5),
    success: Color(0xFF8FD1A0),
    scrim: Color(0x99000000),
    brightness: Brightness.dark,
  );

  final Color paper;
  final Color surface;
  final Color surfaceSunken;
  final Color ink;
  final Color inkMuted;
  final Color hairline;
  final Color primary;
  final Color onPrimary;
  final Color accent;
  final Color danger;
  final Color success;
  final Color scrim;
  final Brightness brightness;

  bool get isDark => brightness == Brightness.dark;

  /// Pressed/selected wash over a surface: primary at low opacity.
  Color get selection => primary.withValues(alpha: isDark ? 0.18 : 0.10);

  /// File-type colour. Used only for small marks (spine, badge, icon tint),
  /// never large fills. Lightened in dark theme to keep contrast on `surface`.
  Color fileType(DocType type) {
    final base = switch (type) {
      DocType.pdf => const Color(0xFFC0392B),
      DocType.word => const Color(0xFF2B5797),
      DocType.sheet => const Color(0xFF217346),
      DocType.slides => const Color(0xFFC4532A),
      DocType.text => const Color(0xFF6B6B6B),
      DocType.markdown => const Color(0xFF3D5A80),
      DocType.epub => const Color(0xFF6E4C9E),
      DocType.image => const Color(0xFF1F7A7A),
      DocType.archive => const Color(0xFF8A6D3B),
      DocType.other => const Color(0xFF6B6B6B),
    };
    return isDark ? Color.lerp(base, const Color(0xFFFFFFFF), 0.38)! : base;
  }

  @override
  DocNookColors copyWith() => this;

  @override
  DocNookColors lerp(DocNookColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return DocNookColors(
      paper: mix(paper, other.paper),
      surface: mix(surface, other.surface),
      surfaceSunken: mix(surfaceSunken, other.surfaceSunken),
      ink: mix(ink, other.ink),
      inkMuted: mix(inkMuted, other.inkMuted),
      hairline: mix(hairline, other.hairline),
      primary: mix(primary, other.primary),
      onPrimary: mix(onPrimary, other.onPrimary),
      accent: mix(accent, other.accent),
      danger: mix(danger, other.danger),
      success: mix(success, other.success),
      scrim: mix(scrim, other.scrim),
      brightness: t < 0.5 ? brightness : other.brightness,
    );
  }
}

/// 4-point spacing grid.
abstract final class Space {
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x6 = 24;
  static const double x8 = 32;
  static const double x12 = 48;

  /// Horizontal padding of every screen.
  static const double screen = 16;
}

abstract final class Radii {
  static const double chip = 8;
  static const double card = 12;
  static const double sheet = 20;

  static const chipAll = BorderRadius.all(Radius.circular(chip));
  static const cardAll = BorderRadius.all(Radius.circular(card));
  static const sheetTop = BorderRadius.vertical(top: Radius.circular(sheet));
}

abstract final class Sizes {
  /// Minimum touch target (NFR-A11Y-01).
  static const double touch = 48;
  static const double hairline = 1;
  static const double spine = 3;
  static const double icon = 22;
  static const double iconSmall = 18;
  static const double buttonHeight = 48;
  static const double rowThumb = 44;
}

abstract final class Motion {
  static const fast = Duration(milliseconds: 180);
  static const standard = Duration(milliseconds: 220);
  static const curve = Curves.easeOutCubic;

  /// Zero when the user turned animations off in system settings.
  static Duration of(BuildContext context, [Duration duration = standard]) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}

extension DocNookThemeContext on BuildContext {
  DocNookColors get colors => Theme.of(this).extension<DocNookColors>()!;
}
