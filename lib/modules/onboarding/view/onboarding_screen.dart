import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:agro_broker/modules/onboarding/controller/onboarding_controller.dart';
// Ensure you have google_fonts in pubspec.yaml, or remove the style usage if not
// import 'package:google_fonts/google_fonts.dart'; 

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final OnboardingController _controller = Get.find<OnboardingController>();

  // professional color palette
  final Color _primaryColor = const Color(0xFF2E7D32); // Agro Green
  final Color _backgroundColor = const Color(0xFFFFFFFF);
  final Color _textColor = const Color(0xFF1F2937);
  final Color _subTextColor = const Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          /// 1. Background Decoration (Subtle Gradient/Blob)
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primaryColor.withOpacity(0.1),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                /// 2. Header (Skip Button)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Only show Skip if not on last page
                      if (_controller.currentPage != _controller.pages.length - 1)
                        TextButton(
                          onPressed: () => _controller.completeOnboarding(),
                          style: TextButton.styleFrom(
                            foregroundColor: _subTextColor,
                            textStyle: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          child: const Text("Skip"),
                        ),
                      // Placeholder to keep height consistent if button is hidden
                      if (_controller.currentPage == _controller.pages.length - 1)
                        const SizedBox(height: 48, width: 48), 
                    ],
                  ),
                ),

                /// 3. Main Content (PageView)
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

                /// 4. Bottom Controls (Dots & Button)
                _buildBottomControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(dynamic page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image Container with subtle shadow
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Image.asset(
              page.image,
              height: 220,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 50),
          
          // Title
          Text(
            page.title,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: _textColor,
              height: 1.2,
              letterSpacing: -0.5,
              // fontFamily: GoogleFonts.poppins().fontFamily, // Optional
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Description
          Text(
            page.description,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: _subTextColor,
              // fontFamily: GoogleFonts.inter().fontFamily, // Optional
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    bool isLastPage = _controller.currentPage == _controller.pages.length - 1;

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
                width: _controller.currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _controller.currentPage == index
                      ? _primaryColor
                      : _primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),

          // Next / Get Started Button
          ElevatedButton(
            onPressed: () {
              if (isLastPage) {
                _controller.completeOnboarding();
              } else {
                _controller.pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isLastPage ? 32 : 24, 
                vertical: 16
              ),
              elevation: 4,
              shadowColor: _primaryColor.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isLastPage ? "Get Started" : "Next",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isLastPage) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}