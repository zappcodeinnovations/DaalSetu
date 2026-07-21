import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:agro_broker/routes/app_routes.dart';
import 'package:agro_broker/utils/app_preferences.dart';
import '../model/onboarding_model.dart';

class OnboardingController extends GetxController {

  final PageController pageController = PageController();

  int currentPage = 0;

  final List<OnboardingModel> pages = [
    OnboardingModel(
      title: "Welcome to AgroBroker",
      description: "Buy & sell commodities easily.",
      image: "assets/images/onboard1.png",
    ),
    OnboardingModel(
      title: "Secure Payments",
      description: "Track contracts and payments securely.",
      image: "assets/images/onboard2.png",
    ),
    OnboardingModel(
      title: "Multi Role Platform",
      description: "Buyers, Sellers & Transporters in one app.",
      image: "assets/images/onboard3.png",
    ),
  ];

  Future<void> completeOnboarding() async {
    await AppPreferences.setOnboardingCompleted();

    // Navigate using GetX
    Get.offAllNamed(AppRoutes.login);
  }
}
