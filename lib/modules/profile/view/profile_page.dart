import 'dart:io';

import 'package:iconly/iconly.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:daalsetu/modules/downloads/service/downloads_service.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/app_theme.dart';
import '../../../services/buyer_services.dart';
import '../../../utils/app_preferences.dart';
import '../controller/profile_controller.dart';
import '../model/profile_model.dart';
import 'package:daalsetu/widgets/app_shell.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  final ProfileController controller = Get.put(ProfileController());

  // Colors mapped to active theme
  // Colors mapped to active theme
  Color get bgColor => Get.theme.scaffoldBackgroundColor;
  Color get cardColor => Get.theme.cardColor;
  Color get cardLighter =>
      Get.isDarkMode ? const Color(0xFF1A2235) : const Color(0xFFF1F5F9);
  Color get textDark => Get.isDarkMode ? Colors.white : const Color(0xFF0F172A);
  Color get textLight =>
      Get.isDarkMode ? const Color(0xFF8D96A7) : const Color(0xFF64748B);

  // Accents
  Color get accentGold => AppTheme.primaryGold;
  Color get accentGreen => AppTheme.successGreen;
  Color get accentBlue => AppTheme.secondaryOrange;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: AppBarLeading(child: IconButton(
          icon: Icon(IconlyLight.arrow_left, color: Get.theme.iconTheme.color),
          onPressed: () => Get.back(),
        )), leadingWidth: AppBarLeading.widthFor(context, hasChild: true),
        title: Obx(
          () => Text(
            "${_roleLabel(controller.profile.value?.role ?? '')} Profile",
            style: TextStyle(
              color: textDark,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.more_horiz, color: textLight),
            onPressed: () {},
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator(color: accentGold));
        }

        final user = controller.profile.value;

        if (user == null) {
          return Center(
            child: Text("No Data", style: TextStyle(color: textLight)),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchProfile,
          color: accentGold,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(context, user),
                const SizedBox(height: 24),

                _buildSectionTitle(
                  context,
                  Icons.person_outline,
                  "GENERAL INFORMATION",
                  showEdit: true,
                ),
                const SizedBox(height: 16),
                _buildGeneralInfoGrid(context, user),
                const SizedBox(height: 12),
                _buildFullWidthCard(
                  context,
                  icon: Icons.person,
                  title: "Account Status",
                  value: user.accountStatus.toLowerCase() == 'active'
                      ? 'active'
                      : user.accountStatus,
                  valueColor: user.accountStatus.toLowerCase() == 'active'
                      ? accentGreen
                      : Colors.orange,
                  trailing: Icon(
                    Icons.check_circle_outline,
                    color: accentGreen,
                  ),
                ),

                const SizedBox(height: 28),

                _buildSectionTitle(
                  context,
                  Icons.work_outline,
                  "COMPLIANCE & BUSINESS",
                ),
                const SizedBox(height: 16),
                _buildKycComplianceCard(context, user),
                const SizedBox(height: 12),
                _buildFullWidthCard(
                  context,
                  icon: Icons.description_outlined,
                  title: "GST Number",
                  value: user.gstNumber.isEmpty
                      ? "Not Available"
                      : user.gstNumber,
                  trailing: user.gstNumber.isNotEmpty
                      ? _buildBadge(
                          "Verified",
                          accentGreen,
                          Icons.check_circle_outline,
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                if (_hasCompanyManagement(user.role))
                  _buildManageCompanyCard(context, user.role),

                const SizedBox(height: 28),

                _buildSectionTitle(
                  context,
                  Icons.insert_drive_file_outlined,
                  "DOCUMENTS",
                ),
                const SizedBox(height: 16),

                _buildDocumentRow(
                  context,
                  title: "PAN Card",
                  iconColor: accentGreen,
                  iconText: "PAN",
                  documentUrl: user.panImage,
                ),
                const SizedBox(height: 12),
                _buildDocumentRow(
                  context,
                  title: "GST Certificate",
                  iconColor: accentBlue,
                  iconText: "GST",
                  documentUrl: user.gstImage,
                ),
                const SizedBox(height: 12),
                _buildDocumentRow(
                  context,
                  title: "Aadhaar Card",
                  iconColor: const Color(0xFF8B5CF6),
                  iconText: "ID",
                  documentUrl: user.aadhaarImage,
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildProfileHeader(BuildContext context, ProfileModel user) {
    final roleLabel = _roleLabel(user.role);
    final status = user.accountStatus.trim().isEmpty
        ? (user.isActive ? 'ACTIVE' : 'INACTIVE')
        : user.accountStatus.toUpperCase();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Get.isDarkMode
              ? Colors.white.withOpacity(0.05)
              : AppTheme.borderLight,
        ),
      ),
      child: Row(
        children: [
          // Glowing Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2A2312), // Dark gold base
              border: Border.all(color: accentGold.withOpacity(0.3), width: 1),
              boxShadow: [
                BoxShadow(
                  color: accentGold.withOpacity(0.15),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipOval(
              child: user.profileImage != null && user.profileImage!.isNotEmpty
                  ? Image.network(
                      controller.profileImageUrl(user.profileImage),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildInitialsAvatar(user),
                    )
                  : _buildInitialsAvatar(user),
            ),
          ),

          const SizedBox(width: 20),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${user.firstName} ${user.lastName}".trim().isEmpty
                      ? "$roleLabel User"
                      : "${user.firstName} ${user.lastName}".trim(),
                  style: TextStyle(
                    color: textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(color: textLight, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildPillBadge(
                      roleLabel.toUpperCase(),
                      accentGold,
                      _roleIcon(user.role),
                    ),
                    const SizedBox(width: 8),
                    _buildPillBadge(
                      status,
                      status == 'ACTIVE' ? accentGreen : Colors.orange,
                      Icons.circle,
                      iconSize: 8,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialsAvatar(ProfileModel user) {
    return Center(
      child: Text(
        user.firstName.isNotEmpty
            ? user.firstName[0].toUpperCase()
            : user.username.isNotEmpty
            ? user.username[0].toUpperCase()
            : "U",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 32,
        ),
      ),
    );
  }

  Widget _buildPillBadge(
    String text,
    Color color,
    IconData icon, {
    double iconSize = 14,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: iconSize),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    IconData icon,
    String title, {
    bool showEdit = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: accentGold, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: textDark,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        if (showEdit)
          InkWell(
            onTap: () async {
              await Get.toNamed(AppRoutes.editProfile);
              controller.fetchProfile();
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: cardLighter,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Get.isDarkMode
                      ? Colors.white.withOpacity(0.05)
                      : AppTheme.borderLight,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit, color: accentGold, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    "Edit",
                    style: TextStyle(
                      color: textDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGeneralInfoGrid(BuildContext context, ProfileModel user) {
    String displayGender = "Not Specified";
    if (user.gender.isNotEmpty) {
      displayGender = user.gender[0].toUpperCase() + user.gender.substring(1);
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildGridItem(
                Icons.call,
                "Mobile Number",
                user.mobile.isEmpty ? "Not Provided" : user.mobile,
                const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGridItem(
                Icons.male,
                "Gender",
                displayGender,
                const Color(0xFF3B82F6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildGridItem(
                Icons.calendar_today,
                "Date of Birth",
                _formatDob(user.dob),
                accentGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGridItem(
                Icons.badge_outlined,
                "PAN Number",
                user.panNumber.isEmpty ? "Not Provided" : user.panNumber,
                const Color(0xFFF97316),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDob(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed == 'null') return "Not Provided";
    if (trimmed.contains('-')) {
      final parts = trimmed.split('-');
      if (parts.length == 3) {
        if (parts[0].length == 4) {
          return '${parts[2].padLeft(2, '0')}/${parts[1].padLeft(2, '0')}/${parts[0]}';
        } else {
          return '${parts[0].padLeft(2, '0')}/${parts[1].padLeft(2, '0')}/${parts[2]}';
        }
      }
    }
    return trimmed;
  }

  Widget _buildGridItem(
    IconData icon,
    String title,
    String value,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Get.isDarkMode
              ? Colors.white.withOpacity(0.05)
              : AppTheme.borderLight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cardLighter,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: textLight, fontSize: 11)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullWidthCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Get.isDarkMode
              ? Colors.white.withOpacity(0.05)
              : AppTheme.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cardLighter,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF8B5CF6),
              size: 18,
            ), // Purple icon for Account Status/GST
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: textLight, fontSize: 11)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildManageCompanyCard(BuildContext context, String role) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141310), // Very dark warm grey
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentGold.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () => Get.toNamed(
          _normalizedRole(role) == 'transporter'
              ? AppRoutes.transporterCompany
              : AppRoutes.sellerCompany,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.domain, color: accentGold, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Manage Company",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Register a company or edit\nyour company details",
                    style: TextStyle(color: textLight, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: textLight),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentRow(
    BuildContext context, {
    required String title,
    required Color iconColor,
    required String iconText,
    required String documentUrl,
  }) {
    final resolvedUrl = controller.profileImageUrl(documentUrl);
    final hasDocument = documentUrl.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Get.isDarkMode
              ? Colors.white.withValues(alpha: 0.05)
              : AppTheme.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                iconText,
                style: TextStyle(
                  color: iconColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasDocument ? 'Uploaded' : 'Not uploaded',
                  style: TextStyle(
                    color: hasDocument ? accentGreen : textLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (hasDocument) ...[
            InkWell(
              onTap: () => _openDocument(resolvedUrl, inApp: true),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Get.isDarkMode
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Get.isDarkMode
                        ? Colors.white.withValues(alpha: 0.1)
                        : AppTheme.borderLight,
                  ),
                ),
                child: Center(
                  child: Text(
                    "View",
                    style: TextStyle(
                      color: accentGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _openDocument(resolvedUrl, inApp: false),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: cardLighter,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Get.isDarkMode
                        ? Colors.white.withValues(alpha: 0.1)
                        : AppTheme.borderLight,
                  ),
                ),
                child: Icon(
                  Icons.file_download_outlined,
                  color: textDark,
                  size: 16,
                ),
              ),
            ),
          ] else ...[
            InkWell(
              onTap: () async {
                await Get.toNamed(AppRoutes.editProfile);
                controller.fetchProfile();
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: cardLighter,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Get.isDarkMode
                        ? Colors.white.withValues(alpha: 0.1)
                        : AppTheme.borderLight,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.upload_file_outlined,
                      size: 14,
                      color: accentGold,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Upload",
                      style: TextStyle(
                        color: accentGold,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openDocument(String url, {required bool inApp}) async {
    if (url.trim().isEmpty) {
      Get.snackbar(
        "Notice",
        "Document file URL is not available.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    try {
      Get.showSnackbar(
        const GetSnackBar(
          message: "Opening document...",
          duration: Duration(seconds: 1),
          snackPosition: SnackPosition.BOTTOM,
        ),
      );

      final uri = Uri.parse(url);
      final isS3OrPresigned = url.contains('X-Amz-') ||
          url.contains('s3.') ||
          url.contains('amazonaws.com');
      final token = await AppPreferences.getAccessToken();

      http.Response response;
      if (isS3OrPresigned) {
        response = await http.get(uri);
      } else {
        response = await http.get(
          uri,
          headers: token != null && token.isNotEmpty
              ? {'Authorization': 'Bearer $token'}
              : {},
        );
        if (response.statusCode == 401 || response.statusCode == 403) {
          response = await http.get(uri);
        }
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched) {
          throw Exception('Document could not be downloaded (${response.statusCode}).');
        }
        return;
      }

      var fileName = uri.pathSegments.isEmpty ? 'profile_document' : uri.pathSegments.last;
      fileName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      if (!fileName.contains('.')) {
        final contentType = response.headers['content-type'] ?? '';
        fileName += contentType.contains('pdf') ? '.pdf' : '.jpg';
      }

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes, flush: true);
      await DownloadsService.saveBytes(
        fileName: fileName,
        bytes: response.bodyBytes,
        mimeType: response.headers['content-type'],
      );

      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched) {
          Get.snackbar(
            'Document Downloaded',
            'Saved to ${file.path}',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
    } catch (error) {
      try {
        final uri = Uri.parse(url);
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched) rethrow;
      } catch (_) {
        Get.snackbar(
          "Error",
          error.toString().replaceFirst('Exception: ', ''),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  Widget _buildKycComplianceCard(BuildContext context, ProfileModel user) {
    final kycStatus = user.kycStatus.trim().isEmpty
        ? 'pending'
        : user.kycStatus.toLowerCase();
    Color kycColor = accentGold;
    IconData kycIcon = Icons.access_time;
    if (kycStatus == 'approved' || kycStatus == 'verified') {
      kycColor = accentGreen;
      kycIcon = Icons.check_circle_outline;
    } else if (kycStatus == 'rejected') {
      kycColor = Colors.red;
      kycIcon = Icons.cancel_outlined;
    }

    final isNotApproved = kycStatus != 'approved' && kycStatus != 'verified';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Get.isDarkMode
              ? Colors.white.withOpacity(0.05)
              : AppTheme.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: accentGold, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "KYC Verification",
                  style: TextStyle(
                    color: textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              _buildBadge(kycStatus.toUpperCase(), kycColor, kycIcon),
            ],
          ),
          if (isNotApproved) ...[
            const SizedBox(height: 12),
            Text(
              "Your KYC is currently ${kycStatus.toUpperCase()}. You can request a re-approval from our verification team.",
              style: TextStyle(color: textLight, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 4),
              child: FilledButton.icon(
                onPressed: () async {
                  try {
                    Get.dialog(
                      const Center(child: CircularProgressIndicator()),
                      barrierDismissible: false,
                    );
                    final res = await BuyerServices.requestKycApproval();
                    if (Get.isDialogOpen ?? false) Get.back();
                    Get.snackbar(
                      "Success",
                      res['message'] ?? "KYC Approval Request Submitted",
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                    );
                  } catch (e) {
                    if (Get.isDialogOpen ?? false) Get.back();
                    Get.snackbar(
                      "Notice",
                      "Request submitted or status updated.",
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                    );
                  }
                },
                icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                label: const Text(
                  "Request KYC Re-approval",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _normalizedRole(String role) =>
      role.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');

  String _roleLabel(String role) {
    switch (_normalizedRole(role)) {
      case 'transporter':
        return 'Transporter';
      case 'seller':
        return 'Seller';
      case 'buyer':
        return 'Buyer';
      case 'both_sellerandbuyer':
      case 'buyer_seller':
      case 'both':
        return 'Seller & Buyer';
      case 'sub_admin':
        return 'Sub Admin';
      case 'admin':
        return 'Admin';
      default:
        return role.trim().isEmpty ? 'User' : role.trim();
    }
  }

  IconData _roleIcon(String role) {
    switch (_normalizedRole(role)) {
      case 'transporter':
        return Icons.local_shipping_outlined;
      case 'seller':
        return Icons.storefront_outlined;
      case 'buyer':
        return Icons.shopping_bag_outlined;
      default:
        return Icons.admin_panel_settings_outlined;
    }
  }

  bool _hasCompanyManagement(String role) {
    final normalized = _normalizedRole(role);
    return normalized == 'seller' ||
        normalized == 'transporter' ||
        normalized == 'both_sellerandbuyer';
  }
}
