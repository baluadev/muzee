/*
 * Muzee Mono — ThemeData builder.
 *
 * Folds the semantic slots into a hand-authored ColorScheme (never fromSeed:
 * its per-role overrides do not propagate) and every Material component theme,
 * then attaches all Neo extensions. Inject once, at the MaterialApp.
 *
 * Pair with `themeAnimationStyle: AnimationStyle.noAnimation` on MaterialApp if
 * theme switches should snap instead of cross-fading.
 */

import 'package:flutter/material.dart';
import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:muzee/theme/neo/neo_icons.dart';
import 'package:muzee/theme/neo/neo_layout.dart';
import 'package:muzee/theme/neo/neo_motion.dart';
import 'package:muzee/theme/neo/neo_typography.dart';

enum NeoThemeVariant {
  dark(Brightness.dark),
  darkPureBlack(Brightness.dark),
  light(Brightness.light);

  const NeoThemeVariant(this.brightness);

  final Brightness brightness;

  NeoColors get colors => switch (this) {
    NeoThemeVariant.dark => NeoColors.dark,
    NeoThemeVariant.darkPureBlack => NeoColors.darkPureBlack,
    NeoThemeVariant.light => NeoColors.light,
  };

  /// Maps the app's persisted settings onto a variant.
  static NeoThemeVariant resolve({
    required Brightness brightness,
    required bool pureBlack,
  }) {
    if (brightness == Brightness.light) return NeoThemeVariant.light;
    return pureBlack ? NeoThemeVariant.darkPureBlack : NeoThemeVariant.dark;
  }
}

/// [locale] picks the heading family: Space Grotesk for Latin-script locales,
/// Inter elsewhere (see [NeoFontFamilies.displayFor]).
ThemeData buildNeoTheme(
  NeoThemeVariant variant, {
  PageTransitionsBuilder? androidTransitions,
  Locale? locale,
}) {
  final c = variant.colors;
  const layout = NeoLayout.standard;
  const shapes = NeoShapes.standard;
  const motion = NeoMotion.standardSet;
  final effects = NeoEffects.from(c);
  final typeExtras = NeoTypeExtras.from(c.onSurfaceMuted, c.accent);
  final displayFamily = NeoFontFamilies.displayFor(locale?.languageCode);
  final text = buildNeoTextTheme(c.onSurface, displayFamily: displayFamily);

  final scheme = ColorScheme(
    brightness: variant.brightness,
    primary: c.accent,
    onPrimary: c.onAccent,
    primaryContainer: c.accentSoft,
    onPrimaryContainer: c.onAccentSoft,
    inversePrimary: c.accentSoft,
    secondary: c.secondary,
    onSecondary: c.onSecondary,
    secondaryContainer: c.secondarySoft,
    onSecondaryContainer: c.onSecondarySoft,
    tertiary: c.secondary,
    onTertiary: c.onSecondary,
    tertiaryContainer: c.secondarySoft,
    onTertiaryContainer: c.onSecondarySoft,
    error: c.danger,
    onError: c.onDanger,
    errorContainer: c.dangerSoft,
    onErrorContainer: c.onDangerSoft,
    surface: c.background,
    onSurface: c.onSurface,
    onSurfaceVariant: c.onSurfaceMuted,
    surfaceDim: c.background,
    surfaceBright: c.surfaceRaised,
    surfaceContainerLowest: c.background,
    surfaceContainerLow: c.surface,
    surfaceContainer: c.surface,
    surfaceContainerHigh: c.surfaceRaised,
    surfaceContainerHighest: c.surfaceRaised,
    inverseSurface: c.onSurface,
    onInverseSurface: c.background,
    outline: c.outline,
    outlineVariant: c.hairline,
    shadow: c.scrim,
    scrim: c.scrim,
    surfaceTint: Colors.transparent,
  );

  WidgetStateProperty<T> selected<T>(T on, T off) =>
      WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? on : off,
      );

  final pill = shapes.pillShape();
  final controlPadding = EdgeInsets.symmetric(horizontal: layout.space24);
  final controlSize = Size(0, layout.controlHeight);

  return ThemeData(
    useMaterial3: true,
    brightness: variant.brightness,
    colorScheme: scheme,
    textTheme: text,
    primaryTextTheme: buildNeoTextTheme(
      c.onAccent,
      displayFamily: displayFamily,
    ),
    scaffoldBackgroundColor: c.background,
    canvasColor: c.background,
    dividerColor: c.hairline,
    splashFactory: InkRipple.splashFactory,
    highlightColor: c.pressedOverlay,
    splashColor: c.pressedOverlay,
    hoverColor: c.pressedOverlay,
    focusColor: c.pressedOverlay,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    iconTheme: IconThemeData(color: c.onSurface, size: layout.iconLarge),
    pageTransitionsTheme: androidTransitions == null
        ? const PageTransitionsTheme()
        : PageTransitionsTheme(
            builders: {TargetPlatform.android: androidTransitions},
          ),
    appBarTheme: AppBarThemeData(
      backgroundColor: c.background,
      foregroundColor: c.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.headlineSmall,
      iconTheme: IconThemeData(color: c.onSurface, size: layout.iconLarge),
      actionsIconTheme: IconThemeData(
        color: c.onSurface,
        size: layout.iconLarge,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: layout.space48 + layout.space24,
      indicatorColor: c.accentSoft,
      indicatorShape: pill,
      iconTheme: selected(
        IconThemeData(color: c.accent, size: layout.iconLarge),
        IconThemeData(color: c.onSurfaceMuted, size: layout.iconLarge),
      ),
      labelTextStyle: selected(
        text.labelSmall!.copyWith(
          color: c.onSurface,
          fontWeight: FontWeight.w700,
        ),
        text.labelSmall!.copyWith(color: c.onSurfaceMuted),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: c.background,
      elevation: 0,
      indicatorColor: c.accentSoft,
      indicatorShape: pill,
      selectedIconTheme: IconThemeData(color: c.accent, size: layout.iconLarge),
      unselectedIconTheme: IconThemeData(
        color: c.onSurfaceMuted,
        size: layout.iconLarge,
      ),
      selectedLabelTextStyle: text.labelSmall!.copyWith(
        color: c.onSurface,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelTextStyle: text.labelSmall!.copyWith(
        color: c.onSurfaceMuted,
      ),
    ),
    cardTheme: CardThemeData(
      color: c.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: shapes.cardShape(),
      clipBehavior: Clip.antiAlias,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: c.onSurfaceMuted,
      textColor: c.onSurface,
      titleTextStyle: text.titleMedium,
      subtitleTextStyle: text.bodySmall!.copyWith(color: c.onSurfaceMuted),
      contentPadding: EdgeInsets.symmetric(horizontal: layout.gutter),
      minVerticalPadding: layout.space8,
      shape: shapes.controlShape(),
    ),
    dividerTheme: DividerThemeData(
      color: c.hairline,
      thickness: layout.hairlineWidth,
      space: layout.hairlineWidth,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        disabledBackgroundColor: c.surfaceRaised,
        disabledForegroundColor: c.onSurfaceSubtle,
        minimumSize: controlSize,
        padding: controlPadding,
        shape: pill,
        textStyle: text.labelLarge,
        elevation: 0,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: c.surfaceRaised,
        foregroundColor: c.onSurface,
        disabledBackgroundColor: c.surface,
        disabledForegroundColor: c.onSurfaceSubtle,
        minimumSize: controlSize,
        padding: controlPadding,
        shape: pill,
        textStyle: text.labelLarge,
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.onSurface,
        disabledForegroundColor: c.onSurfaceSubtle,
        side: BorderSide(color: c.outline, width: layout.hairlineWidth),
        minimumSize: controlSize,
        padding: controlPadding,
        shape: pill,
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.accent,
        disabledForegroundColor: c.onSurfaceSubtle,
        minimumSize: controlSize,
        padding: EdgeInsets.symmetric(horizontal: layout.space16),
        shape: pill,
        textStyle: text.labelLarge,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: c.onSurface,
        disabledForegroundColor: c.onSurfaceSubtle,
        minimumSize: Size.square(layout.minTouchTarget),
        iconSize: layout.iconLarge,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: c.accent,
      foregroundColor: c.onAccent,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: shapes.cardShape(),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: c.surfaceRaised,
      selectedColor: c.accent,
      disabledColor: c.surface,
      checkmarkColor: c.onAccent,
      labelStyle: text.labelMedium,
      secondaryLabelStyle: text.labelMedium!.copyWith(color: c.onAccent),
      side: BorderSide.none,
      shape: shapes.controlShape(),
      padding: EdgeInsets.symmetric(horizontal: layout.space8),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: c.surfaceRaised,
      contentPadding: EdgeInsets.symmetric(
        horizontal: layout.space16,
        vertical: layout.space12,
      ),
      border: OutlineInputBorder(
        borderRadius: shapes.medium,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: shapes.medium,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: shapes.medium,
        borderSide: BorderSide(color: c.accent, width: layout.focusWidth),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: shapes.medium,
        borderSide: BorderSide(color: c.danger, width: layout.focusWidth),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: shapes.medium,
        borderSide: BorderSide(color: c.danger, width: layout.focusWidth),
      ),
      hintStyle: text.bodyLarge!.copyWith(color: c.onSurfaceMuted),
      labelStyle: text.bodyLarge!.copyWith(color: c.onSurfaceMuted),
      floatingLabelStyle: text.bodySmall!.copyWith(color: c.accent),
      helperStyle: text.bodySmall!.copyWith(color: c.onSurfaceMuted),
      errorStyle: text.bodySmall!.copyWith(color: c.danger),
      prefixIconColor: c.onSurfaceMuted,
      suffixIconColor: c.onSurfaceMuted,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.accent,
      selectionColor: c.accentGlow,
      selectionHandleColor: c.accent,
    ),
    sliderTheme: SliderThemeData(
      trackHeight: layout.progressTrack,
      activeTrackColor: c.accent,
      // >= 3:1 on the background, so the full length of the song is visible.
      inactiveTrackColor: c.outline,
      thumbColor: c.accent,
      overlayColor: c.accentGlow,
      thumbShape: const RoundSliderThumbShape(
        enabledThumbRadius: 7,
        elevation: 0,
        pressedElevation: 0,
      ),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
      valueIndicatorColor: c.surfaceRaised,
      valueIndicatorTextStyle: typeExtras.timecode.copyWith(color: c.onSurface),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: c.accent,
      linearTrackColor: c.surfaceRaised,
      circularTrackColor: Colors.transparent,
      linearMinHeight: layout.progressTrack,
      refreshBackgroundColor: c.surfaceRaised,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return c.onSurfaceSubtle;
        return states.contains(WidgetState.selected)
            ? c.onAccent
            : c.onSurfaceMuted;
      }),
      trackColor: selected(c.accent, c.surfaceRaised),
      trackOutlineColor: selected(Colors.transparent, c.outline),
      // Non-color signal for "on": a check glyph in the thumb.
      thumbIcon: selected(Icon(NeoIcons.check, color: c.accent), null),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: selected(c.accent, Colors.transparent),
      checkColor: WidgetStatePropertyAll(c.onAccent),
      side: BorderSide(color: c.outline, width: layout.focusWidth),
    ),
    radioTheme: RadioThemeData(fillColor: selected(c.accent, c.outline)),
    tabBarTheme: TabBarThemeData(
      indicatorColor: c.accent,
      indicatorSize: TabBarIndicatorSize.label,
      labelColor: c.onSurface,
      unselectedLabelColor: c.onSurfaceMuted,
      labelStyle: text.labelLarge,
      unselectedLabelStyle: text.labelLarge!.copyWith(
        fontWeight: FontWeight.w500,
      ),
      dividerColor: Colors.transparent,
      overlayColor: WidgetStatePropertyAll(c.pressedOverlay),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: shapes.cardShape(),
      barrierColor: c.scrim,
      titleTextStyle: text.headlineSmall,
      contentTextStyle: text.bodyMedium!.copyWith(color: c.onSurfaceMuted),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      modalBackgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      modalElevation: 0,
      shape: shapes.sheetShape(),
      showDragHandle: true,
      dragHandleColor: c.outline,
      modalBarrierColor: c.scrim,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: c.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: shapes.controlShape(),
      textStyle: text.bodyLarge,
      iconColor: c.accent,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.surfaceRaised,
      contentTextStyle: text.bodyMedium,
      actionTextColor: c.accent,
      behavior: SnackBarBehavior.floating,
      shape: shapes.controlShape(),
      elevation: 0,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: shapes.small,
      ),
      textStyle: text.bodySmall,
      waitDuration: motion.emphasized,
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll(c.outline),
      thickness: WidgetStatePropertyAll(layout.space4),
      radius: Radius.circular(shapes.radiusSmall),
    ),
    badgeTheme: BadgeThemeData(
      backgroundColor: c.accent,
      textColor: c.onAccent,
      textStyle: text.labelSmall,
    ),
    extensions: <ThemeExtension<dynamic>>[
      c,
      layout,
      shapes,
      motion,
      effects,
      typeExtras,
    ],
  );
}
