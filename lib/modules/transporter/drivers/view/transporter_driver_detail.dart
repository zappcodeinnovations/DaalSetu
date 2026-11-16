import 'package:daalsetu/widgets/hero_header.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:url_launcher/url_launcher.dart';
import '../model/driver_model.dart';
import './transporter_driver_form.dart';
import 'package:daalsetu/widgets/app_shell.dart';
import '../../../../utils/app_snackbar.dart';

class TransporterDriverDetail extends StatelessWidget {
  final DriverModel driver;

  const TransporterDriverDetail({super.key, required this.driver});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: HeroHeader(
        title: "Driver Details",
        subtitle: driver.driverName,
        leading: AppBarLeading(
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
            onPressed: () => Get.back(),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (driver.licenseUploadUrl != null)
              IconButton(
                tooltip: "View License",
                icon: const Icon(IconlyLight.document, color: Colors.white),
                onPressed: () async {
                  final ok = await launchUrl(Uri.parse(driver.licenseUploadUrl!), mode: LaunchMode.externalApplication);
                  if (!ok) AppSnackbar.snackbar("Error", "Unable to open license document", snackPosition: SnackPosition.BOTTOM);
                },
              ),
            IconButton(
              tooltip: "Edit",
              icon: const Icon(IconlyLight.edit, color: Colors.white),
              onPressed: () async {
                final saved = await Get.to(() => TransporterDriverForm(driver: driver));
                if (saved == true) Get.back();
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? const Color(0xFF333333) : const Color(0xFFFFE0B2),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFFFF8E1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? const Color(0xFF3D3D3D) : const Color(0xFFFFE0B2),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          driver.driverName.isEmpty
                              ? '?'
                              : driver.driverName[0].toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: const Color(0xFFE65100),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driver.driverName,
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF2E1500),
                              ),
                            ),
                            const SizedBox(height: 4),
                            _buildBadge(
                              driver.statusDisplay, 
                              driver.status == 'active' ? Colors.green : Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Divider(
                      color: isDark ? const Color(0xFF333333) : const Color(0xFFFFE0B2).withValues(alpha: 0.6),
                      height: 1,
                    ),
                  ),
                  _buildSectionHeader("Personal & License Info"),
                  _buildDetailRow("Phone", driver.phoneNumber),
                  _buildDetailRow("Email", driver.email.isNotEmpty ? driver.email : "N/A"),
                  _buildDetailRow("License", driver.licenseNumber),
                  _buildDetailRow("License Expiry", driver.licenseExpiry ?? "N/A"),
                  _buildDetailRow("Experience", "${driver.experience ?? 0} Years"),
                  _buildDetailRow("Address", driver.address?.isNotEmpty == true ? driver.address! : "N/A"),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? const Color(0xFF333333) : const Color(0xFFFFE0B2),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
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
                            Flexible(
                              child: Text(
                                "Vehicle Assignment",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF2E1500),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildBadge(
                        driver.assignmentStatusDisplay, 
                        driver.assignmentStatus == 'assigned' ? Colors.blue : Colors.orange,
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Divider(
                      color: isDark ? const Color(0xFF333333) : const Color(0xFFFFE0B2).withValues(alpha: 0.6),
                      height: 1,
                    ),
                  ),
                  if (driver.assignedVehicle != null) ...[
                    _buildDetailRow("Vehicle Number", driver.assignedVehicle!.vehicleNumber),
                    _buildDetailRow("Status", driver.assignedVehicle!.vehicleStatusDisplay),
                  ] else ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          "No vehicle currently assigned.",
                          style: GoogleFonts.inter(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 14,
            decoration: BoxDecoration(
              color: const Color(0xFFFFB300),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFE65100),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
