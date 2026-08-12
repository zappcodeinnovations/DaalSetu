import 'package:iconly/iconly.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controller/onboarding_controller.dart';

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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1A1206), const Color(0xFF0D1117)]
                : [const Color(0xFFFFF8E1), Colors.white],
          ),
        ),
        child: Stack(
          children: [
            // Decorative circle
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.12),
                      theme.colorScheme.primary.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // Skip button
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_controller.currentPage !=
                            _controller.pages.length - 1)
                          TextButton(
                            onPressed: () =>
                                _controller.completeOnboarding(),
                            child: Text(
                              "Skip",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                          ),
                        if (_controller.currentPage ==
                            _controller.pages.length - 1)
                          const SizedBox(height: 48, width: 48),
                      ],
                    ),
                  ),

                  // PageView
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
                        return _buildPageContent(page);
                      },
                    ),
                  ),

                  // Bottom Controls
                  _buildBottomControls(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageContent(dynamic page) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image with glass frame
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.8),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.6),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Image.asset(
              page.image,
              height: 180,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 50),

          Text(
            page.title,
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            page.description,
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.5,
              color: theme.textTheme.bodyMedium?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    final theme = Theme.of(context);
    bool isLastPage =
        _controller.currentPage == _controller.pages.length - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Dot Indicators
          Row(
            children: List.generate(
              _controller.pages.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 6),
                width: _controller.currentPage == index ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _controller.currentPage == index
                      ? theme.colorScheme.primary
                      : theme.colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: _controller.currentPage == index
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ]
                      : [],
                ),
              ),
            ),
          ),

          // Next/Get Started Button
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  const Color(0xFFFF8F00),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.35),
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
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      if (!isLastPage) ...[
                        const SizedBox(width: 6),
                        const Icon(IconlyLight.arrow_right_2,
                            size: 18, color: Colors.white),
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
