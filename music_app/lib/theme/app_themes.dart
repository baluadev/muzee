import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:muzee/services/settings_manager.dart';
import 'package:muzee/theme/dynamic_color_compat.dart';
import 'package:muzee/theme/neo/neo_typography.dart';
import 'package:muzee/theme/tubify_color_schemes.dart';
import 'package:muzee/theme/tubify_tokens.dart';

ThemeMode themeMode = themeModeFor(appearanceSetting.value);
Brightness brightness = getBrightnessFromThemeMode(themeMode);

PageTransitionsBuilder transitionsBuilder = predictiveBack.value
    ? const PredictiveBackPageTransitionsBuilder()
    : const CupertinoPageTransitionsBuilder();

Brightness getBrightnessFromThemeMode(ThemeMode themeMode) {
  final themeBrightnessMapping = {
    ThemeMode.light: Brightness.light,
    ThemeMode.dark: Brightness.dark,
    ThemeMode.system:
        SchedulerBinding.instance.platformDispatcher.platformBrightness,
  };

  return themeBrightnessMapping[themeMode] ?? Brightness.dark;
}

/// The Material theme mode for [appearance] (pure black is a dark mode).
ThemeMode themeModeFor(AppAppearance appearance) => switch (appearance) {
  AppAppearance.system => ThemeMode.system,
  AppAppearance.light => ThemeMode.light,
  AppAppearance.dark || AppAppearance.black => ThemeMode.dark,
};

/// Material You surfaces can follow the wallpaper; Tubify keeps accent `#ABD600`.
ColorScheme tubifyBrandPrimaryOverlay(ColorScheme scheme) {
  final light = scheme.brightness == Brightness.light;
  if (light) {
    return scheme.copyWith(
      primary: TubifyTokens.lightPrimary,
      onPrimary: TubifyTokens.lightOnPrimary,
      primaryContainer: TubifyTokens.lightPrimaryContainer,
      onPrimaryContainer: TubifyTokens.lightOnPrimaryContainer,
      surfaceTint: TubifyTokens.lightPrimary,
    );
  }
  return scheme.copyWith(
    primary: TubifyTokens.darkPrimary,
    onPrimary: TubifyTokens.darkOnPrimary,
    primaryContainer: TubifyTokens.darkPrimaryContainer,
    onPrimaryContainer: TubifyTokens.darkOnPrimaryContainer,
    surfaceTint: TubifyTokens.darkPrimary,
  );
}

ColorScheme getAppColorScheme(
  ColorScheme? lightColorScheme,
  ColorScheme? darkColorScheme,
) {
  if (useSystemColor.value &&
      lightColorScheme != null &&
      darkColorScheme != null) {
    // Temporary fix until this will be fixed: https://github.com/material-foundation/flutter-packages/issues/582

    (lightColorScheme, darkColorScheme) = tempGenerateDynamicColourSchemes(
      lightColorScheme,
      darkColorScheme,
    );
  }

  final selectedScheme = (brightness == Brightness.light)
      ? lightColorScheme
      : darkColorScheme;

  if (useSystemColor.value && selectedScheme != null) {
    return tubifyBrandPrimaryOverlay(selectedScheme);
  }
  return brightness == Brightness.light
      ? TubifyColorSchemes.light
      : TubifyColorSchemes.dark;
}

ThemeData getAppTheme(ColorScheme colorScheme) {
  final base = colorScheme.brightness == Brightness.light
      ? ThemeData.light(useMaterial3: true)
      : ThemeData.dark(useMaterial3: true);

  // Inter is bundled (assets/fonts); no runtime download.
  final textTheme = base.textTheme.apply(
    fontFamily: NeoFontFamilies.text,
    bodyColor: colorScheme.onSurface,
    displayColor: colorScheme.onSurface,
  );
  final primaryTextTheme = base.primaryTextTheme.apply(
    fontFamily: NeoFontFamilies.text,
    bodyColor: colorScheme.onPrimary,
    displayColor: colorScheme.onPrimary,
  );

  final isLight = colorScheme.brightness == Brightness.light;
  final isPureBlack =
      colorScheme.brightness == Brightness.dark && usePureBlackColor.value;

  // Pure black theme colors
  const pureBlack = Color(0xFF000000);
  const pureBlackElevated = Color(0xFF0A0A0A);
  const pureBlackContainer = Color(0xFF121212);
  const pureBlackContainerHigh = Color(0xFF1A1A1A);

  // Resolve surfaces so scaffold / AppBar / nav chrome match [TubifyTokens.darkSurface]
  // on dark (including Material You); pure-black OLED overrides below.
  final effectiveColorScheme = isPureBlack
      ? colorScheme.copyWith(
          surface: pureBlack,
          surfaceContainerLowest: pureBlack,
          surfaceContainerLow: pureBlackElevated,
          surfaceContainer: pureBlackContainer,
          surfaceContainerHigh: pureBlackContainerHigh,
          surfaceContainerHighest: pureBlackContainerHigh,
        )
      : (!isLight
            ? colorScheme.copyWith(
                surface: TubifyTokens.darkSurface,
                surfaceContainerLowest: TubifyTokens.darkSurface,
              )
            : colorScheme);

  final bgColor = effectiveColorScheme.surface;

  final cardBgColor = isLight
      ? colorScheme.surfaceContainerLow
      : (isPureBlack ? pureBlackElevated : null);

  final borderColor = effectiveColorScheme.outline.withAlpha(77);
  final subtleBorderColor = effectiveColorScheme.outlineVariant.withAlpha(51);
  final pillRadius = BorderRadius.circular(9999);
  final regularRadius = BorderRadius.circular(12);
  final cardRadius = BorderRadius.circular(16);

  final themedText = textTheme.copyWith(
    headlineLarge: textTheme.headlineLarge?.copyWith(
      fontSize: 32,
      height: 40 / 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.32,
    ),
    headlineMedium: textTheme.headlineMedium?.copyWith(
      fontSize: 24,
      height: 32 / 24,
      fontWeight: FontWeight.w700,
    ),
    headlineSmall: textTheme.headlineSmall?.copyWith(
      fontSize: 20,
      height: 28 / 20,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: textTheme.titleMedium?.copyWith(
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: textTheme.bodyLarge?.copyWith(
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: textTheme.bodyMedium?.copyWith(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w400,
    ),
    labelLarge: textTheme.labelLarge?.copyWith(
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.6,
    ),
    labelMedium: textTheme.labelMedium?.copyWith(
      fontSize: 10,
      height: 14 / 10,
      fontWeight: FontWeight.w500,
    ),
  );

  return ThemeData(
    fontFamily: NeoFontFamilies.text,
    scaffoldBackgroundColor: bgColor,
    colorScheme: effectiveColorScheme,
    textTheme: themedText,
    primaryTextTheme: primaryTextTheme,
    cardColor: cardBgColor,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: regularRadius),
        backgroundColor: effectiveColorScheme.primary,
        foregroundColor: effectiveColorScheme.onPrimary,
        textStyle: themedText.bodyLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        elevation: 0,
        minimumSize: const Size(0, 44),
        side: BorderSide(color: effectiveColorScheme.onSurface),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: regularRadius),
        foregroundColor: effectiveColorScheme.onSurface,
        textStyle: themedText.bodyLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        elevation: 0,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: regularRadius),
        foregroundColor: effectiveColorScheme.onSurfaceVariant,
        textStyle: themedText.bodyLarge,
      ),
    ),
    cardTheme: base.cardTheme.copyWith(
      elevation: 0,
      color: cardBgColor,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: cardRadius,
        side: BorderSide(color: subtleBorderColor),
      ),
    ),
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: bgColor,
      foregroundColor: effectiveColorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: themedText.headlineSmall?.copyWith(
        color: effectiveColorScheme.onSurface,
      ),
      toolbarHeight: 64,
      iconTheme: IconThemeData(
        color: effectiveColorScheme.onSurfaceVariant,
        size: 24,
      ),
      actionsIconTheme: IconThemeData(
        color: effectiveColorScheme.onSurfaceVariant,
        size: 24,
      ),
    ),
    listTileTheme: base.listTileTheme.copyWith(
      tileColor: effectiveColorScheme.surfaceContainer,
      textColor: effectiveColorScheme.onSurface,
      iconColor: effectiveColorScheme.onSurfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: cardRadius),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    sliderTheme: base.sliderTheme.copyWith(
      year2023: false,
      trackHeight: 4,
      thumbSize: WidgetStateProperty.all(const Size(16, 16)),
      activeTrackColor: effectiveColorScheme.primary,
      inactiveTrackColor: effectiveColorScheme.surfaceContainerHigh,
      thumbColor: effectiveColorScheme.primary,
    ),
    bottomSheetTheme: base.bottomSheetTheme.copyWith(
      backgroundColor: effectiveColorScheme.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: subtleBorderColor),
      ),
      dragHandleColor: effectiveColorScheme.outline.withAlpha(102),
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      filled: true,
      isDense: true,
      fillColor: isLight
          ? colorScheme.surfaceContainerHighest
          : (isPureBlack
                ? pureBlackContainerHigh
                : colorScheme.surfaceContainerHigh),
      border: OutlineInputBorder(
        borderRadius: regularRadius,
        borderSide: BorderSide(color: subtleBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: regularRadius,
        borderSide: BorderSide(color: subtleBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: regularRadius,
        borderSide: BorderSide(color: effectiveColorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: regularRadius,
        borderSide: BorderSide(color: effectiveColorScheme.error, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: regularRadius,
        borderSide: BorderSide(color: effectiveColorScheme.error, width: 2),
      ),
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      hintStyle: themedText.bodyLarge?.copyWith(
        color: effectiveColorScheme.onSurfaceVariant,
      ),
      helperStyle: themedText.labelMedium?.copyWith(
        color: effectiveColorScheme.onSurfaceVariant,
      ),
      errorStyle: themedText.labelMedium?.copyWith(
        color: effectiveColorScheme.error,
      ),
    ),
    dialogTheme: base.dialogTheme.copyWith(
      backgroundColor: effectiveColorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: cardRadius,
        side: BorderSide(color: subtleBorderColor),
      ),
      elevation: 12,
      titleTextStyle: themedText.headlineSmall?.copyWith(
        color: effectiveColorScheme.onSurface,
      ),
      contentTextStyle: themedText.bodyMedium?.copyWith(
        color: effectiveColorScheme.onSurfaceVariant,
      ),
    ),
    navigationBarTheme: base.navigationBarTheme.copyWith(
      backgroundColor: bgColor,
      elevation: 0,
      height: 80,
      indicatorColor: Colors.transparent,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: effectiveColorScheme.primary, size: 24);
        }
        return IconThemeData(
          color: effectiveColorScheme.onSurfaceVariant,
          size: 24,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(
            color: effectiveColorScheme.primary,
            fontSize: 10,
            height: 14 / 10,
            fontWeight: FontWeight.w500,
          );
        }
        return TextStyle(
          color: effectiveColorScheme.onSurfaceVariant,
          fontSize: 10,
          height: 14 / 10,
          fontWeight: FontWeight.w500,
        );
      }),
    ),
    navigationRailTheme: base.navigationRailTheme.copyWith(
      backgroundColor: bgColor,
      elevation: 0,
      indicatorColor: effectiveColorScheme.primaryContainer,
      selectedIconTheme: IconThemeData(
        color: effectiveColorScheme.primary,
        size: 24,
      ),
      unselectedIconTheme: IconThemeData(
        color: effectiveColorScheme.onSurfaceVariant,
        size: 24,
      ),
      selectedLabelTextStyle: TextStyle(
        color: effectiveColorScheme.primary,
        fontSize: 10,
        height: 14 / 10,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: effectiveColorScheme.onSurfaceVariant,
        fontSize: 10,
        height: 14 / 10,
        fontWeight: FontWeight.w500,
      ),
    ),
    popupMenuTheme: base.popupMenuTheme.copyWith(
      color: effectiveColorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: cardRadius,
        side: BorderSide(color: subtleBorderColor),
      ),
      elevation: 12,
      textStyle: themedText.bodyLarge?.copyWith(
        color: effectiveColorScheme.onSurface,
      ),
    ),
    dividerTheme: base.dividerTheme.copyWith(color: borderColor, thickness: 1),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: effectiveColorScheme.surfaceContainerHigh,
      contentTextStyle: themedText.bodyMedium?.copyWith(
        color: effectiveColorScheme.onSurface,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: cardRadius),
      elevation: 6,
      actionTextColor: effectiveColorScheme.primary,
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: effectiveColorScheme.surfaceContainerHigh,
      selectedColor: effectiveColorScheme.primary,
      disabledColor: effectiveColorScheme.surfaceContainerLow,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: pillRadius),
      labelStyle: themedText.bodyLarge?.copyWith(
        color: effectiveColorScheme.onSurface,
      ),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    useMaterial3: true,
    pageTransitionsTheme: PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: transitionsBuilder,
      },
    ),
  );
}
