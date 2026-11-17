import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';

import '../controller/onboarding_controller.dart';
import '../theme/onboarding_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final OnboardingController _controller = Get.find<OnboardingController>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // ── 1. Warm Top Ambient Glow (Centralized Token) ───────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 320,
            child: Container(
              decoration: BoxDecoration(
                gradient: OnboardingColors.ambientGlowGradient(isDark),
              ),
            ),
          ),

          // ── 2. Subtle Decorative Corner Accent ────────────────────────────
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    OnboardingColors.primary.withValues(alpha: isDark ? 0.08 : 0.12),
                    OnboardingColors.primary.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),

          // ── 3. Main Content Flow ──────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Top Bar with Brand Pill & Skip Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Mini Brand Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.06) : OnboardingColors.skipPillBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.12) : OnboardingColors.skipPillBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: OnboardingColors.primary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "DAALSETU",
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: OnboardingColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Skip Pill Button
                      if (_controller.currentPage != _controller.pages.length - 1)
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.06) : OnboardingColors.skipPillBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? Colors.white.withValues(alpha: 0.15) : OnboardingColors.skipPillBorder,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => _controller.completeOnboarding(),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                child: Text(
                                  "Skip",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: OnboardingColors.skipPillText,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 32, width: 32),
                    ],
                  ),
                ),

                // PageView with Carousel Pages
                Expanded(
                  child: PageView.builder(
                    controller: _controller.pageController,
                    itemCount: _controller.pages.length,
                    onPageChanged: (index) {
                      setState(() {
                        _controller.currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final page = _controller.pages[index];
                      return _buildPageContent(page, isDark);
                    },
                  ),
                ),

                // Bottom Controls: Animated Pill Indicators & Vibrant CTA Button
                _buildBottomControls(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(dynamic page, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image with Dual-Ring Accent & Ambient Shadow
          Container(
            width: 230,
            height: 230,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.white.withValues(alpha: 0.05) : OnboardingColors.imageFrameBg,
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.15) : OnboardingColors.border,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: OnboardingColors.imageFrameShadow.withValues(alpha: isDark ? 0.15 : 0.12),
                  blurRadius: 32,
                  spreadRadius: 4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                page.image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(IconlyLight.image, size: 64, color: OnboardingColors.primary),
                ),
              ),
            ),
          ),
          const SizedBox(height: 44),

          // Title
          Text(
            page.title,
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: isDark ? OnboardingColors.titleDark : OnboardingColors.titleLight,
              height: 1.25,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 14),

          // Description
          Text(
            page.description,
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: isDark ? OnboardingColors.descriptionDark : OnboardingColors.descriptionLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(bool isDark) {
    final bool isLastPage =
        _controller.currentPage == _controller.pages.length - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Dot Page Indicators
          Row(
            children: List.generate(
              _controller.pages.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 6),
                width: _controller.currentPage == index ? 32 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _controller.currentPage == index
                      ? OnboardingColors.activeDot
                      : (isDark ? OnboardingColors.inactiveDotDark : OnboardingColors.inactiveDot),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: _controller.currentPage == index
                      ? [
                          BoxShadow(
                            color: OnboardingColors.activeDot.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
              ),
            ),
          ),

          // Next / Get Started Action Button
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: OnboardingColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: OnboardingColors.primary.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  if (isLastPage) {
                    _controller.completeOnboarding();
                  } else {
                    _controller.pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLastPage ? 28 : 22,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isLastPage ? "Get Started" : "Next",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      if (!isLastPage) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          IconlyLight.arrow_right_2,
                          size: 18,
                          color: Colors.white,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
