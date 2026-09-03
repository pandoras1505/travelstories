import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Soft, warm-tinted elevation shadows (never pure black) so cards and
/// media read as gently lifted rather than harshly boxed.
class AppShadows {
  AppShadows._();

  static List<BoxShadow> card(Brightness brightness) {
    final tint = brightness == Brightness.dark
        ? Colors.black
        : AppColors.neutral900;
    final baseAlpha = brightness == Brightness.dark ? 0.45 : 0.06;
    final softAlpha = brightness == Brightness.dark ? 0.28 : 0.03;
    return [
      BoxShadow(
        color: tint.withValues(alpha: baseAlpha),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
      BoxShadow(
        color: tint.withValues(alpha: softAlpha),
        blurRadius: 3,
        offset: const Offset(0, 1),
      ),
    ];
  }

  static List<BoxShadow> elevated(Brightness brightness) {
    final tint = brightness == Brightness.dark
        ? Colors.black
        : AppColors.neutral900;
    final baseAlpha = brightness == Brightness.dark ? 0.55 : 0.1;
    final softAlpha = brightness == Brightness.dark ? 0.32 : 0.05;
    return [
      BoxShadow(
        color: tint.withValues(alpha: baseAlpha),
        blurRadius: 28,
        offset: const Offset(0, 12),
      ),
      BoxShadow(
        color: tint.withValues(alpha: softAlpha),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ];
  }
}
