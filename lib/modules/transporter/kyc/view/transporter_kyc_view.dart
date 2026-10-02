import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../../profile/controller/profile_controller.dart';
import '../../../../theme/app_theme.dart';

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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: theme.textTheme.bodyLarge?.color,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "KYC Verification",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(IconlyLight.swap, color: primary),
            tooltip: "Refresh",
            onPressed: controller.fetchProfile,
          ),
          const SizedBox(width: 8),
        ],
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
                        color: isDark ? AppTheme.cardColor : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isApproved
                              ? AppTheme.successGreen.withValues(alpha: 0.3)
                              : AppTheme.primaryGold.withValues(alpha: 0.3),
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
                              color: (isApproved ? AppTheme.successGreen : AppTheme.primaryGold)
                                  .withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isApproved ? Icons.verified : IconlyBold.time_circle,
                              color: isApproved ? AppTheme.successGreen : AppTheme.primaryGold,
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
                                    color: isApproved ? AppTheme.successGreen : AppTheme.primaryGold,
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

                    Text(
                      "Submitted KYC Documents",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
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
        color: isDark ? AppTheme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppTheme.borderColor : AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 20),
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
              color: (isVerified ? AppTheme.successGreen : Colors.orange).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isVerified ? "VERIFIED" : "SUBMITTED",
              style: TextStyle(
                color: isVerified ? AppTheme.successGreen : Colors.orange,
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
