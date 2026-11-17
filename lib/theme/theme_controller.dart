import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  final themeMode = ThemeMode.light.obs;

  /// Whether dark mode is currently active
  bool get isDark => themeMode.value == ThemeMode.dark;

  @override
  void onInit() {
    super.onInit();
    loadTheme();
  }

  /// Toggle between light and dark theme
  Future<void> toggleTheme() async {
    if (isDark) {
      await setLightTheme();
    } else {
      await setDarkTheme();
    }
  }

  /// SET LIGHT THEME
  Future<void> setLightTheme() async {
    themeMode.value = ThemeMode.light;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("themeMode", "light");
  }

  /// SET DARK THEME
  Future<void> setDarkTheme() async {
    themeMode.value = ThemeMode.dark;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("themeMode", "dark");
  }

  /// SET SYSTEM THEME
  Future<void> setSystemTheme() async {
    themeMode.value = ThemeMode.system;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("themeMode", "system");
  }

  /// LOAD SAVED THEME
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString("themeMode");

    switch (savedTheme) {
      case "light":
        themeMode.value = ThemeMode.light;
        break;
      case "dark":
        themeMode.value = ThemeMode.dark;
        break;
      case "system":
        themeMode.value = ThemeMode.system;
        break;
      default:
        themeMode.value = ThemeMode.light;
    }
  }
}
