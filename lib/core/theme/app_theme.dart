import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Builds the light and dark [ThemeData] for TravelStories: Material 3,
/// warm teal/coral brand colors, editorial typography, generously rounded
/// surfaces. All screens should consume colors/text styles via [Theme.of]
/// rather than reaching for [AppColors] directly, so dark mode stays correct.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(_lightScheme);

  static ThemeData get dark => _build(_darkScheme);

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.teal,
    onPrimary: AppColors.neutral50,
    primaryContainer: Color(0xFFCCE9E7),
    onPrimaryContainer: AppColors.tealDark,
    secondary: AppColors.coral,
    onSecondary: AppColors.neutral50,
    secondaryContainer: Color(0xFFFFDCD0),
    onSecondaryContainer: AppColors.coralDark,
    tertiary: AppColors.amber,
    onTertiary: AppColors.neutral900,
    tertiaryContainer: Color(0xFFFCE7C2),
    onTertiaryContainer: AppColors.amberDark,
    error: AppColors.error,
    onError: AppColors.neutral50,
    errorContainer: Color(0xFFFAD4D0),
    onErrorContainer: AppColors.error,
    surface: AppColors.neutral50,
    onSurface: AppColors.neutral900,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Color(0xFFFDF8F3),
    surfaceContainer: AppColors.neutral100,
    surfaceContainerHigh: Color(0xFFEFE7DE),
    surfaceContainerHighest: AppColors.neutral200,
    onSurfaceVariant: AppColors.neutral600,
    outline: AppColors.neutral300,
    outlineVariant: AppColors.neutral200,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppColors.neutral800,
    onInverseSurface: AppColors.neutral50,
    inversePrimary: AppColors.tealLight,
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.tealLight,
    onPrimary: AppColors.tealDark,
    primaryContainer: Color(0xFF10504F),
    onPrimaryContainer: Color(0xFFB8E4E1),
    secondary: AppColors.coralLight,
    onSecondary: AppColors.coralDark,
    secondaryContainer: Color(0xFF7A3A26),
    onSecondaryContainer: Color(0xFFFFD9CB),
    tertiary: AppColors.amber,
    onTertiary: AppColors.neutral900,
    tertiaryContainer: Color(0xFF6B4E14),
    onTertiaryContainer: Color(0xFFFCE7C2),
    error: AppColors.errorDark,
    onError: Color(0xFF5C1410),
    errorContainer: Color(0xFF7A251F),
    onErrorContainer: Color(0xFFFAD4D0),
    surface: AppColors.neutral900,
    onSurface: AppColors.neutral100,
    surfaceContainerLowest: Color(0xFF120F0C),
    surfaceContainerLow: Color(0xFF1F1B17),
    surfaceContainer: AppColors.neutral800,
    surfaceContainerHigh: Color(0xFF332C25),
    surfaceContainerHighest: AppColors.neutral700,
    onSurfaceVariant: AppColors.neutral300,
    outline: AppColors.neutral600,
    outlineVariant: AppColors.neutral700,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppColors.neutral100,
    onInverseSurface: AppColors.neutral900,
    inversePrimary: AppColors.tealDark,
  );

  static ThemeData _build(ColorScheme scheme) {
    final textTheme = AppTypography.textTheme(scheme.onSurface);
    final brightness = scheme.brightness;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
        clipBehavior: Clip.antiAlias,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainer,
        selectedColor: scheme.primaryContainer,
        labelStyle: textTheme.labelMedium?.copyWith(color: scheme.onSurface),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        shape: const StadiumBorder(),
        side: BorderSide.none,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.onSurface.withValues(alpha: 0.12),
          disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.fullRadius,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.fullRadius,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outline),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.fullRadius,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.fullRadius,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return (selected ? textTheme.labelMedium : textTheme.labelMedium)
              ?.copyWith(
                color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
              );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
    );
  }
}
