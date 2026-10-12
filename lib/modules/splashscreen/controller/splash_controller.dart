import 'dart:async';
import '../../../routes/app_routes.dart';
import '../../../utils/app_preferences.dart';
import 'package:flutter/material.dart';

class SplashController {

  Future<void> handleNavigation(BuildContext context) async {
    await Future.delayed(const Duration(seconds: 3));
    if (!context.mounted) return;

    final onboardingDone =
        await AppPreferences.isOnboardingCompleted();
    if (!context.mounted) return;

    if (!onboardingDone) {
      Navigator.pushReplacementNamed(
          context, AppRoutes.onboarding);
      return;
    }

    final loggedIn =
        await AppPreferences.isLoggedIn();
    if (!context.mounted) return;

    if (!loggedIn) {
      Navigator.pushReplacementNamed(
          context, AppRoutes.login);
    } 
    else {
      Navigator.pushReplacementNamed(
          context, AppRoutes.mainNav);
    }
  }
}
