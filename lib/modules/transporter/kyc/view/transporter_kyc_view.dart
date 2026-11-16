import 'package:daalsetu/widgets/hero_header.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../../profile/controller/profile_controller.dart';
import '../../../../theme/app_theme.dart';
import 'package:daalsetu/widgets/app_shell.dart';

class TransporterKycView extends StatelessWidget {
  const TransporterKycView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfileController());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: HeroHeader(
        title: "KYC Verification",
        subtitle: "Identity verification & transport license compliance",
        leading: AppBarLeading(
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: Colors.white,
            ),
            onPressed: () => Get.back(),
          ),
        ),
        trailing: IconButton(
          icon: const Icon(IconlyLight.swap, color: Colors.white),
          tooltip: "Refresh",
          onPressed: controller.fetchProfile,
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Opacity(
                  opacity: 0.05,
                  child: Image.asset(
                    'assets/images/thumb_logo.png',
                    width: 280,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          Obx(() {
            if (controller.isLoading.value && controller.profile.value == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final user = controller.profile.value;
            final isApproved = user?.kycStatus.toLowerCase() == 'approved';
            final kycStatusText = (user?.kycStatus.isNotEmpty == true ? user!.kycStatus : (isApproved ? 'Approved' : 'Pending')).toUpperCase();

            return RefreshIndicator(
              onRefresh: controller.fetchProfile,
              color: primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // KYC Status Banner Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isApproved
                              ? AppTheme.successGreen.withValues(alpha: 0.5)
                              : (isDark ? const Color(0xFF333333) : const Color(0xFFFFE0B2)),
                          width: 1.3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: (isApproved ? AppTheme.successGreen : const Color(0xFFFFB300))
                                  .withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isApproved ? Icons.verified : IconlyBold.time_circle,
                              color: isApproved ? AppTheme.successGreen : const Color(0xFFE65100),
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Verification Status",
                                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  kycStatusText,
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isApproved ? AppTheme.successGreen : const Color(0xFFE65100),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isApproved
                                      ? "Your transporter account is fully verified."
                                      : "Your KYC documents are under review by Super Admin.",
                                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 16,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB300),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Submitted KYC Documents",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Document List
                    _buildDocumentTile(
                      context,
                      title: "PAN Card",
                      value: user != null && user.panNumber.isNotEmpty ? user.panNumber : "Not Provided",
                      icon: IconlyLight.document,
                      isVerified: isApproved,
                    ),
                    const SizedBox(height: 10),

                    _buildDocumentTile(
                      context,
                      title: "GST Registration",
                      value: user != null && user.gstNumber.isNotEmpty ? user.gstNumber : "Not Provided",
                      icon: IconlyLight.paper,
                      isVerified: isApproved,
                    ),
                    const SizedBox(height: 10),

                    _buildDocumentTile(
                      context,
                      title: "PAN Document",
                      value: user != null && user.panImage.isNotEmpty ? "Document Uploaded" : "Not Provided",
                      icon: IconlyLight.document,
                      isVerified: isApproved,
                    ),
                    const SizedBox(height: 10),

                    _buildDocumentTile(
                      context,
                      title: "GST Document",
                      value: user != null && user.gstImage.isNotEmpty ? "Document Uploaded" : "Not Provided",
                      icon: IconlyLight.work,
                      isVerified: isApproved,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDocumentTile(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required bool isVerified,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF333333) : const Color(0xFFFFE0B2),
          width: 1.1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB300).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFE65100), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (isVerified ? AppTheme.successGreen : const Color(0xFFFFB300)).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isVerified ? "VERIFIED" : "SUBMITTED",
              style: TextStyle(
                color: isVerified ? AppTheme.successGreen : const Color(0xFFE65100),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
