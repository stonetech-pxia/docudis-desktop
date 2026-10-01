import 'package:docudis_ffi/docudis_ffi.dart' show EntityType;
import 'package:flutter/material.dart';

/// Design tokens for the "Clay" direction. Source of truth: design/README.md
/// and design/mockups/DirectionClay.dc.html.
abstract final class Clay {
  static const bg = Color(0xFFF5EFE8);
  static const surface = Color(0xFFFFFCF8);
  static const blob = Color(0xFFEAD9C8);

  static const primary = Color(0xFFC8623A);
  static const primaryPressed = Color(0xFFA84E2C);
  static const primaryTint = Color(0xFFF6DED5);
  static const secondary = Color(0xFF6B7F62);
  static const secondaryTint = Color(0xFFE3E9DC);
  static const secondaryText = Color(0xFF4E6644);
  static const tertiary = Color(0xFFB8926A);
  static const tertiaryTint = Color(0xFFEFE3D2);

  static const ink = Color(0xFF2A2420);
  static const inkMuted = Color(0xFF6B5F55);
  static const inkCaption = Color(0xFF8A7B6F);
  static const inkPlaceholder = Color(0xFFA89A8E);
  static const divider = Color(0xFFE8DFD4);
  static const disabled = Color(0xFFE6E2DD);

  static const warningBg = Color(0xFFF3E8CB);
  static const warningText = Color(0xFF7A5A10);
  static const error = Color(0xFFB03A2E);

  // Desktop sizes: the phone's 22 / 16 / 52 / 44 read as an app blown up
  // on a monitor. The colours are the Android app's.
  static const radius = 12.0;
  static const controlRadius = 8.0;
  static const buttonHeight = 34.0;
  static const tapTarget = 32.0;
  static const pagePadding = EdgeInsets.symmetric(horizontal: 20);

  /// One duration and curve for every transition, so they never fight.
  static const motion = Duration(milliseconds: 240);
  static const motionCurve = Curves.easeInOutCubic;

  static const shadow = [
    BoxShadow(color: Color(0x14785A3C), blurRadius: 10, offset: Offset(0, 2)),
  ];

  /// Icon tiles: three round corners and one tighter bottom-left corner.
  static const iconTileRadius = BorderRadius.only(
    topLeft: Radius.circular(10),
    topRight: Radius.circular(10),
    bottomRight: Radius.circular(10),
    bottomLeft: Radius.circular(4),
  );

  static const headingFamily = 'Sora';
  static const bodyFamily = 'Karla';

  static TextStyle heading(
    double size, {
    FontWeight weight = FontWeight.w700,
    Color color = ink,
    double? height,
    double letterSpacing = 0,
  }) => _style(headingFamily, size, weight, color, height, letterSpacing);

  static TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = ink,
    double? height,
  }) => _style(bodyFamily, size, weight, color, height, 0);

  /// Placeholders such as `[PERSON_1]`.
  static TextStyle mono(double size, {Color color = primaryPressed}) =>
      TextStyle(
        fontFamily: 'monospace',
        fontFamilyFallback: const ['Roboto Mono', 'Menlo', 'Consolas'],
        fontSize: size,
        fontWeight: FontWeight.w500,
        color: color,
      );

  /// Uppercase tracked label (section captions).
  static TextStyle label({Color color = inkCaption}) => body(
    12,
    weight: FontWeight.w700,
    color: color,
  ).copyWith(letterSpacing: 0.5);

  // The bundled fonts are variable; the weight axis has to be set explicitly
  // next to fontWeight or every weight renders as Regular.
  static TextStyle _style(
    String family,
    double size,
    FontWeight weight,
    Color color,
    double? height,
    double letterSpacing,
  ) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: weight,
    fontVariations: [FontVariation.weight(weight.value.toDouble())],
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

/// Highlight colors for one entity type: same lightness, hue varies.
class EntityColors {
  const EntityColors(this.background, this.foreground, this.accent);

  final Color background;
  final Color foreground;
  final Color accent;
}

EntityColors entityColors(EntityType type) => switch (type) {
  EntityType.person => const EntityColors(
    Color(0xFFF6DED5),
    Color(0xFF8E3B22),
    Color(0xFFC8623A),
  ),
  EntityType.email => const EntityColors(
    Color(0xFFE3E9DC),
    Color(0xFF4E6644),
    Color(0xFF6B7F62),
  ),
  EntityType.phone => const EntityColors(
    Color(0xFFEFE3D2),
    Color(0xFF7A5A33),
    Color(0xFFB8926A),
  ),
  EntityType.id || EntityType.number || EntityType.card || EntityType.iban =>
    const EntityColors(Color(0xFFEADFEA), Color(0xFF6A3F73), Color(0xFF8F5E99)),
  EntityType.date || EntityType.birthDate => const EntityColors(
    Color(0xFFF3E8CB),
    Color(0xFF7A5A10),
    Color(0xFFB08A2E),
  ),
  EntityType.address => const EntityColors(
    Color(0xFFDCE8EA),
    Color(0xFF2E5C66),
    Color(0xFF4C8A96),
  ),
  EntityType.company || EntityType.other => const EntityColors(
    Color(0xFFE6E2DD),
    Color(0xFF4C4540),
    Color(0xFF7A6E66),
  ),
  EntityType.amount => const EntityColors(
    Color(0xFFF5E3D2),
    Color(0xFF8A4A1E),
    Color(0xFFC27A3E),
  ),
  EntityType.secret || EntityType.apiKey => const EntityColors(
    Color(0xFFF2DCE3),
    Color(0xFF8A2E4E),
    Color(0xFFB8456F),
  ),
  EntityType.ip || EntityType.url => const EntityColors(
    Color(0xFFDDE6EC),
    Color(0xFF3A5568),
    Color(0xFF5F7F95),
  ),
  EntityType.custom => const EntityColors(
    Color(0xFFEBE4F2),
    Color(0xFF4F3F7A),
    Color(0xFF6E5AA8),
  ),
};

ThemeData clayTheme() {
  const scheme = ColorScheme.light(
    primary: Clay.primary,
    onPrimary: Colors.white,
    primaryContainer: Clay.primaryTint,
    onPrimaryContainer: Clay.primaryPressed,
    secondary: Clay.secondary,
    onSecondary: Colors.white,
    secondaryContainer: Clay.secondaryTint,
    onSecondaryContainer: Clay.secondaryText,
    tertiary: Clay.tertiary,
    onTertiary: Colors.white,
    tertiaryContainer: Clay.tertiaryTint,
    surface: Clay.surface,
    onSurface: Clay.ink,
    onSurfaceVariant: Clay.inkMuted,
    surfaceContainerHighest: Clay.disabled,
    outline: Clay.divider,
    outlineVariant: Clay.divider,
    error: Clay.error,
    onError: Colors.white,
  );

  final text = TextTheme(
    displaySmall: Clay.heading(24, letterSpacing: -0.48, height: 1.2),
    headlineSmall: Clay.heading(19, letterSpacing: -0.38, height: 1.2),
    titleLarge: Clay.heading(16),
    titleMedium: Clay.heading(14, weight: FontWeight.w600),
    titleSmall: Clay.heading(13, weight: FontWeight.w600),
    bodyLarge: Clay.body(14, height: 1.5),
    bodyMedium: Clay.body(13.5, height: 1.5),
    bodySmall: Clay.body(12, color: Clay.inkCaption, height: 1.4),
    labelLarge: Clay.heading(13, weight: FontWeight.w600),
    labelMedium: Clay.body(12, weight: FontWeight.w700, color: Clay.inkMuted),
    labelSmall: Clay.body(
      11,
      weight: FontWeight.w700,
      color: Clay.inkPlaceholder,
    ),
  );

  final controlShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(Clay.controlRadius),
  );
  final cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(Clay.radius),
  );
  OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(Clay.controlRadius),
        borderSide: BorderSide(color: color, width: width),
      );

  return ThemeData(
    useMaterial3: true,
    visualDensity: VisualDensity.compact,
    // Desktop controls answer the pointer with a hover tint, not a ripple.
    splashFactory: NoSplash.splashFactory,
    hoverColor: Clay.bg,
    highlightColor: Clay.divider.withValues(alpha: 0.5),
    colorScheme: scheme,
    scaffoldBackgroundColor: Clay.bg,
    fontFamily: Clay.bodyFamily,
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: Clay.bg,
      foregroundColor: Clay.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: Clay.heading(14, weight: FontWeight.w600),
    ),
    cardTheme: CardThemeData(
      color: Clay.surface,
      elevation: 0,
      shape: cardShape,
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, Clay.buttonHeight),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: controlShape,
        textStyle: text.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, Clay.buttonHeight),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: controlShape,
        textStyle: text.labelLarge,
        foregroundColor: Clay.ink,
        backgroundColor: Clay.surface,
        side: const BorderSide(color: Clay.divider, width: 1.5),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Clay.primary,
        minimumSize: const Size(Clay.tapTarget, Clay.tapTarget),
        textStyle: Clay.body(14, weight: FontWeight.w700),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: Clay.ink),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Clay.surface,
      hintStyle: Clay.body(15, color: Clay.inkPlaceholder),
      labelStyle: Clay.body(15, color: Clay.inkCaption),
      border: inputBorder(Clay.divider),
      enabledBorder: inputBorder(Clay.divider),
      focusedBorder: inputBorder(Clay.primary, 1.5),
      errorBorder: inputBorder(Clay.error),
      focusedErrorBorder: inputBorder(Clay.error, 1.5),
    ),
    dividerTheme: const DividerThemeData(
      color: Clay.divider,
      space: 1,
      thickness: 1,
    ),
    // A desktop notice: a small toast, not a bar across the window.
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Clay.ink,
      contentTextStyle: Clay.body(13, color: Colors.white),
      behavior: SnackBarBehavior.floating,
      width: 360,
      shape: controlShape,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Clay.surface,
      shape: cardShape,
      constraints: const BoxConstraints(minWidth: 280, maxWidth: 440),
      titleTextStyle: Clay.heading(15, weight: FontWeight.w600),
      contentTextStyle: Clay.body(13, color: Clay.inkMuted, height: 1.5),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 500),
      textStyle: Clay.body(12, color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Clay.ink.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Clay.surface,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Clay.radius)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Clay.surface,
      shape: controlShape,
      textStyle: Clay.body(13),
      labelTextStyle: WidgetStatePropertyAll(Clay.body(13)),
      menuPadding: const EdgeInsets.symmetric(vertical: 4),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Clay.primary,
      linearTrackColor: Clay.primaryTint,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Clay.primary : Clay.divider,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Clay.surface,
      selectedColor: Clay.primaryTint,
      side: const BorderSide(color: Clay.divider),
      shape: const StadiumBorder(),
      labelStyle: Clay.body(13, weight: FontWeight.w700),
      showCheckmark: false,
    ),
  );
}
