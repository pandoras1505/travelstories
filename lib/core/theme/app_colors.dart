import 'package:flutter/material.dart';

/// TravelStories brand palette: warm ocean teal + sunset coral, on a warm
/// (not blue-tinted) neutral scale — evokes photography, warmth, travel.
class AppColors {
  AppColors._();

  // Brand — teal (primary)
  static const Color teal = Color(0xFF0B6E6E);
  static const Color tealLight = Color(0xFF3F9A96);
  static const Color tealDark = Color(0xFF054A4A);

  // Brand — coral (secondary / accent)
  static const Color coral = Color(0xFFFF7A59);
  static const Color coralLight = Color(0xFFFFA58C);
  static const Color coralDark = Color(0xFFD65A3D);

  // Brand — amber (tertiary: highlights, ratings, badges)
  static const Color amber = Color(0xFFF2A93B);
  static const Color amberDark = Color(0xFFC9860F);

  // Warm neutral scale (used for surfaces/text instead of cold grays)
  static const Color neutral50 = Color(0xFFFFFBF7);
  static const Color neutral100 = Color(0xFFF5EFE9);
  static const Color neutral200 = Color(0xFFE8DFD5);
  static const Color neutral300 = Color(0xFFD3C6B8);
  static const Color neutral400 = Color(0xFFAA9A89);
  static const Color neutral500 = Color(0xFF7D6F60);
  static const Color neutral600 = Color(0xFF5C5044);
  static const Color neutral700 = Color(0xFF413830);
  static const Color neutral800 = Color(0xFF2A241F);
  static const Color neutral900 = Color(0xFF1A1613);

  // Semantic
  static const Color success = Color(0xFF3F9142);
  static const Color successDark = Color(0xFF6BC26E);
  static const Color warning = Color(0xFFE0A22B);
  static const Color error = Color(0xFFD64545);
  static const Color errorDark = Color(0xFFFF6B5E);
  static const Color info = Color(0xFF3E7CB1);
  static const Color infoDark = Color(0xFF6FA8D6);
}
