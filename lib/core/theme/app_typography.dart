import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// TravelStories type system: Fraunces (warm editorial serif) for
/// display/headline moments, Inter (clean, highly legible) for UI and body
/// text — a travel-magazine feel that still reads well at small sizes.
class AppTypography {
  AppTypography._();

  static TextTheme textTheme(Color onSurface) {
    return TextTheme(
      displayLarge: GoogleFonts.fraunces(
        fontSize: 57,
        height: 1.12,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        color: onSurface,
      ),
      displayMedium: GoogleFonts.fraunces(
        fontSize: 45,
        height: 1.16,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      displaySmall: GoogleFonts.fraunces(
        fontSize: 36,
        height: 1.22,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      headlineLarge: GoogleFonts.fraunces(
        fontSize: 32,
        height: 1.25,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      headlineMedium: GoogleFonts.fraunces(
        fontSize: 28,
        height: 1.29,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      headlineSmall: GoogleFonts.fraunces(
        fontSize: 24,
        height: 1.33,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        height: 1.27,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: onSurface,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        height: 1.43,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: onSurface,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        color: onSurface,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        height: 1.43,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: onSurface,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        height: 1.33,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: onSurface,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        height: 1.43,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: onSurface,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        height: 1.33,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: onSurface,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        height: 1.45,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: onSurface,
      ),
    );
  }
}
