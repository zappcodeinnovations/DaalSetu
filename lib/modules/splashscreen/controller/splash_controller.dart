import 'dart:async';
import 'package:daalsetu/routes/app_routes.dart';
import 'package:daalsetu/utils/app_preferences.dart';
import 'package:flutter/material.dart';

class SplashController {

  Future<void> handleNavigation(BuildContext context) async {
    await Future.delayed(const Duration(seconds: 3));

    final onboardingDone =
        await AppPreferences.isOnboardingCompleted();

    final loggedIn =
        await AppPreferences.isLoggedIn();

    if (!onboardingDone) {
      Navigator.pushReplacementNamed(
          context, AppRoutes.onboarding);
    } 
    else if (!loggedIn) {
      Navigator.pushReplacementNamed(
          context, AppRoutes.login);
    } 
    else {
      Navigator.pushReplacementNamed(
          context, AppRoutes.mainNav);
    }
  }
}
