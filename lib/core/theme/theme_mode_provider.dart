import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'theme_mode';

/// The user's chosen appearance (light/dark/system), loaded from
/// `SharedPreferences` on first read. `AsyncValue.valueOrNull` defaults to
/// [ThemeMode.system] for the brief moment before that finishes — there's
/// no loading UI to show for a theme mode, it just resolves a frame or two
/// after launch.
class ThemeModeController extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() => loadSavedThemeMode();

  Future<void> setThemeMode(ThemeMode mode) async {
    state = AsyncData(mode);
    await saveThemeMode(mode);
  }
}

final themeModeProvider = AsyncNotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

Future<ThemeMode> loadSavedThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString(_prefsKey);
  for (final mode in ThemeMode.values) {
    if (mode.name == saved) return mode;
  }
  return ThemeMode.system;
}

Future<void> saveThemeMode(ThemeMode mode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_prefsKey, mode.name);
}
