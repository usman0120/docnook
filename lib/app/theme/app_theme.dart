import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Builds the Material theme from DocNook tokens. Separation comes from
/// hairlines and surface tone, so elevation and tint are switched off almost
/// everywhere (BLUEPRINT 9.3).
abstract final class AppTheme {
  static ThemeData light() => _build(DocNookColors.light);
  static ThemeData dark() => _build(DocNookColors.dark);

  static ThemeData _build(DocNookColors c) {
    final scheme = ColorScheme(
      brightness: c.brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      secondary: c.accent,
      onSecondary: c.onPrimary,
      error: c.danger,
      onError: c.isDark ? c.paper : c.surface,
      surface: c.surface,
      onSurface: c.ink,
      onSurfaceVariant: c.inkMuted,
      outline: c.hairline,
      outlineVariant: c.hairline,
      surfaceContainerLowest: c.surface,
      surfaceContainerLow: c.surface,
      surfaceContainer: c.surface,
      surfaceContainerHigh: c.surfaceSunken,
      surfaceContainerHighest: c.surfaceSunken,
      surfaceTint: Colors.transparent,
      scrim: c.scrim,
      shadow: Colors.black,
    );
    final text = DocNookText.textTheme(c.ink, c.inkMuted);

    return ThemeData(
      useMaterial3: true,
      brightness: c.brightness,
      colorScheme: scheme,
      extensions: [c],
      fontFamily: Fonts.sans,
      textTheme: text,
      scaffoldBackgroundColor: c.paper,
      canvasColor: c.paper,
      dividerColor: c.hairline,
      splashFactory: InkSparkle.splashFactory,
      highlightColor: c.selection,
      splashColor: c.selection,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: AppBarTheme(
        backgroundColor: c.paper,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: Space.screen,
        titleTextStyle: DocNookText.sectionTitle.copyWith(color: c.ink),
        iconTheme: IconThemeData(color: c.ink, size: Sizes.icon),
        systemOverlayStyle: _overlay(c),
      ),
      iconTheme: IconThemeData(color: c.ink, size: Sizes.icon),
      dividerTheme: DividerThemeData(
        color: c.hairline,
        thickness: Sizes.hairline,
        space: Sizes.hairline,
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.cardAll,
          side: BorderSide(color: c.hairline),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        modalBackgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        modalElevation: 8,
        modalBarrierColor: c.scrim,
        shape: const RoundedRectangleBorder(borderRadius: Radii.sheetTop),
        clipBehavior: Clip.antiAlias,
        showDragHandle: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        barrierColor: c.scrim,
        shape: const RoundedRectangleBorder(borderRadius: Radii.cardAll),
        titleTextStyle: DocNookText.sectionTitle.copyWith(color: c.ink),
        contentTextStyle: DocNookText.body.copyWith(color: c.inkMuted),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.cardAll,
          side: BorderSide(color: c.hairline),
        ),
        textStyle: DocNookText.body.copyWith(color: c.ink),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.ink,
        contentTextStyle: DocNookText.body.copyWith(color: c.paper),
        actionTextColor: c.isDark ? DocNookColors.light.accent : DocNookColors.dark.accent,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: Radii.cardAll),
        insetPadding: const EdgeInsets.all(Space.x4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        hintStyle: DocNookText.body.copyWith(color: c.inkMuted),
        labelStyle: DocNookText.body.copyWith(color: c.inkMuted),
        floatingLabelStyle: DocNookText.label.copyWith(color: c.primary),
        errorStyle: DocNookText.caption.copyWith(color: c.danger),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Space.x4,
          vertical: Space.x3,
        ),
        border: _fieldBorder(c.hairline),
        enabledBorder: _fieldBorder(c.hairline),
        focusedBorder: _fieldBorder(c.primary, width: 1.5),
        errorBorder: _fieldBorder(c.danger),
        focusedErrorBorder: _fieldBorder(c.danger, width: 1.5),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.primary,
        selectionColor: c.primary.withValues(alpha: 0.25),
        selectionHandleColor: c.primary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.accent,
        linearTrackColor: c.surfaceSunken,
        circularTrackColor: Colors.transparent,
        linearMinHeight: 4,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.onPrimary : c.inkMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.primary : c.surfaceSunken,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.primary : c.hairline,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.primary : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(c.onPrimary),
        side: BorderSide(color: c.inkMuted, width: 1.5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.primary : c.inkMuted,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: c.primary,
        inactiveTrackColor: c.surfaceSunken,
        thumbColor: c.primary,
        overlayColor: c.selection,
        trackHeight: 3,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: c.ink,
        textColor: c.ink,
        titleTextStyle: DocNookText.body.copyWith(color: c.ink),
        subtitleTextStyle: DocNookText.caption.copyWith(color: c.inkMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: Space.screen),
        minVerticalPadding: Space.x3,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: c.ink, borderRadius: Radii.chipAll),
        textStyle: DocNookText.caption.copyWith(color: c.paper),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(c.inkMuted.withValues(alpha: 0.5)),
        radius: const Radius.circular(2),
        thickness: const WidgetStatePropertyAll(3),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
    );
  }

  static OutlineInputBorder _fieldBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: Radii.cardAll,
        borderSide: BorderSide(color: color, width: width),
      );

  /// Transparent system bars with icons that contrast with the paper.
  static SystemUiOverlayStyle _overlay(DocNookColors c) => SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: c.isDark ? Brightness.light : Brightness.dark,
    statusBarBrightness: c.brightness,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: c.isDark ? Brightness.light : Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );

  static SystemUiOverlayStyle overlayFor(BuildContext context) =>
      _overlay(context.colors);
}
