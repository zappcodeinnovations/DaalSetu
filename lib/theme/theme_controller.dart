import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  final themeMode = ThemeMode.light.obs;

  @override
  void onInit() {
    super.onInit();
    loadTheme();
  }

  /// SET LIGHT THEME
  void setLightTheme() async {
    themeMode.value = ThemeMode.light;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("themeMode", "light");
  }

  /// SET DARK THEME
  void setDarkTheme() async {
    themeMode.value = ThemeMode.dark;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("themeMode", "dark");
  }

  /// SET SYSTEM THEME
  void setSystemTheme() async {
    themeMode.value = ThemeMode.system;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("themeMode", "system");
  }

  /// LOAD SAVED THEME
  void loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString("themeMode");

    switch (savedTheme) {
      case "light":
        themeMode.value = ThemeMode.light;
        break;
      case "dark":
        themeMode.value = ThemeMode.dark;
        break;
      default:
        themeMode.value = ThemeMode.light;
    }
  }
}
