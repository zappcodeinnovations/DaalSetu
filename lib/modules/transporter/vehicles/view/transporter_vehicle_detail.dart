import 'package:daalsetu/widgets/hero_header.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controller/transporter_vehicle_controller.dart';
import '../model/vehicle_model.dart';
import './transporter_vehicle_form.dart';
import './transporter_vehicles_view.dart';
import 'package:daalsetu/widgets/app_shell.dart';
import '../../../../utils/app_snackbar.dart';

class TransporterVehicleDetail extends StatelessWidget {
  final VehicleModel vehicle;

  const TransporterVehicleDetail({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: HeroHeader(
        title: "Vehicle Details",
        subtitle: vehicle.vehicleNumber,
        leading: AppBarLeading(
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
            onPressed: () => Get.back(),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: "Edit",
              icon: const Icon(IconlyLight.edit, color: Colors.white),
              onPressed: () async {
                final saved = await Get.to(() => TransporterVehicleForm(vehicle: vehicle));
                if (saved == true) Get.back();
              },
            ),
            IconButton(
              tooltip: "Delete",
              icon: const Icon(IconlyLight.delete, color: Colors.white),
              onPressed: () async {
                final deleted = await TransporterVehiclesView.confirmDelete(
                  Get.find<TransporterVehicleController>(),
                  vehicle,
                );
                if (deleted) Get.back();
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
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(IconlyLight.document, size: 30, color: Color(0xFFE65100)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vehicle.vehicleNumber,
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF2E1500),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              vehicle.vehicleType,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildBadge(
                              vehicle.vehicleStatusDisplay,
                              TransporterVehiclesView.statusColor(vehicle.vehicleStatus),
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
                  _buildSectionHeader("Basic Information"),
                  _buildDetailRow("Brand", TransporterVehiclesView.brandText(vehicle)),
                  _buildDetailRow("Model", vehicle.modelName?.isNotEmpty == true ? vehicle.modelName! : "N/A"),
                  _buildDetailRow("Manufacturing Year", vehicle.manufacturingYear?.toString() ?? "N/A"),
                  _buildDetailRow("Fuel Type", vehicle.fuelType.toUpperCase()),
                  
                  const SizedBox(height: 16),
                  _buildSectionHeader("Specifications"),
                  _buildDetailRow("Load Capacity", "${vehicle.loadCapacityTons} Tons"),
                  _buildDetailRow("Body Type",
                      vehicle.bodyType == 'other' && (vehicle.bodyTypeOther ?? '').isNotEmpty ? vehicle.bodyTypeOther! : vehicle.bodyTypeDisplay),
                  _buildDetailRow("Number of Axles", vehicle.numberOfAxles?.toString() ?? "N/A"),
                  _buildDetailRow("Dimensions (L×W×H)",
                      [vehicle.lengthFt, vehicle.widthFt, vehicle.heightFt].any((d) => (d ?? '').isNotEmpty)
                          ? "${vehicle.lengthFt ?? '-'} × ${vehicle.widthFt ?? '-'} × ${vehicle.heightFt ?? '-'} ft"
                          : "N/A"),
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
                  _buildSectionHeader("Documentation"),
                  _buildDetailRow("RC Number", vehicle.rcNumber?.isNotEmpty == true ? vehicle.rcNumber! : "N/A"),
                  _buildDetailRow("Insurance No.", vehicle.insuranceNumber?.isNotEmpty == true ? vehicle.insuranceNumber! : "N/A"),
                  _buildDetailRow("Insurance Expiry", vehicle.insuranceExpiryDate ?? "N/A"),
                  _buildDetailRow("Permit Type", vehicle.permitType == 'other' && (vehicle.permitTypeOther ?? '').isNotEmpty ? vehicle.permitTypeOther! : (vehicle.permitTypeDisplay?.isNotEmpty == true ? vehicle.permitTypeDisplay! : "N/A")),
                  _buildDetailRow("Permit Expiry", vehicle.permitExpiryDate ?? "N/A"),
                  if (vehicle.rcUploadUrl != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final ok = await launchUrl(Uri.parse(vehicle.rcUploadUrl!), mode: LaunchMode.externalApplication);
                          if (!ok) AppSnackbar.snackbar("Error", "Unable to open RC document", snackPosition: SnackPosition.BOTTOM);
                        },
                        icon: const Icon(IconlyLight.document, size: 18, color: Color(0xFFE65100)),
                        label: const Text("View RC Document", style: TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFFB300), width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
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
                            "Assigned Driver",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF2E1500),
                            ),
                          ),
                        ],
                      ),
                      const Icon(IconlyLight.user_1, color: Color(0xFFE65100)),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Divider(
                      color: isDark ? const Color(0xFF333333) : const Color(0xFFFFE0B2).withValues(alpha: 0.6),
                      height: 1,
                    ),
                  ),
                  if (vehicle.hasDriver) ...[
                    _buildDetailRow("Driver Name", vehicle.assignedDriverName!),
                    if (vehicle.driverPhoneNumber != null && vehicle.driverPhoneNumber!.isNotEmpty)
                      _buildDetailRow("Phone", vehicle.driverPhoneNumber!),
                  ] else ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          "No driver currently assigned.",
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
    if (text.isEmpty) return const SizedBox.shrink();
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
            width: 140,
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
