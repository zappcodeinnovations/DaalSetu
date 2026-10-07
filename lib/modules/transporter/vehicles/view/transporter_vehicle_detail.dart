import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../theme/glass_widgets.dart';
import '../controller/transporter_vehicle_controller.dart';
import '../model/vehicle_model.dart';
import './transporter_vehicle_form.dart';
import './transporter_vehicles_view.dart';

class TransporterVehicleDetail extends StatelessWidget {
  final VehicleModel vehicle;

  const TransporterVehicleDetail({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.iconTheme.color),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Vehicle Details",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        actions: [
          IconButton(
            tooltip: "Edit",
            icon: const Icon(IconlyLight.edit),
            onPressed: () async {
              final saved = await Get.to(() => TransporterVehicleForm(vehicle: vehicle));
              if (saved == true) Get.back();
            },
          ),
          IconButton(
            tooltip: "Delete",
            icon: const Icon(IconlyLight.delete, color: Colors.red),
            onPressed: () async {
              final deleted = await TransporterVehiclesView.confirmDelete(Get.find<TransporterVehicleController>(), vehicle);
              if (deleted) Get.back();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(IconlyLight.document, size: 32, color: theme.colorScheme.primary),
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
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              vehicle.vehicleType,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey,
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
                  const Divider(height: 32),
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
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("Documentation"),
                  _buildDetailRow("RC Number", vehicle.rcNumber?.isNotEmpty == true ? vehicle.rcNumber! : "N/A"),
                  _buildDetailRow("Insurance No.", vehicle.insuranceNumber?.isNotEmpty == true ? vehicle.insuranceNumber! : "N/A"),
                  _buildDetailRow("Insurance Expiry", vehicle.insuranceExpiryDate ?? "N/A"),
                  _buildDetailRow("Permit Type", vehicle.permitType == 'other' && (vehicle.permitTypeOther ?? '').isNotEmpty ? vehicle.permitTypeOther! : (vehicle.permitTypeDisplay?.isNotEmpty == true ? vehicle.permitTypeDisplay! : "N/A")),
                  _buildDetailRow("Permit Expiry", vehicle.permitExpiryDate ?? "N/A"),
                  if (vehicle.rcUploadUrl != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final ok = await launchUrl(Uri.parse(vehicle.rcUploadUrl!), mode: LaunchMode.externalApplication);
                          if (!ok) Get.snackbar("Error", "Unable to open RC document", snackPosition: SnackPosition.BOTTOM);
                        },
                        icon: const Icon(IconlyLight.document, size: 18),
                        label: const Text("View RC Document"),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Assigned Driver",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(IconlyLight.user_1, color: theme.colorScheme.primary),
                    ],
                  ),
                  const Divider(height: 24),
                  if (vehicle.hasDriver) ...[
                    _buildDetailRow("Driver Name", vehicle.assignedDriverName!),
                    if (vehicle.driverPhoneNumber != null && vehicle.driverPhoneNumber!.isNotEmpty)
                      _buildDetailRow("Phone", vehicle.driverPhoneNumber!),
                  ] else ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
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
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
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
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
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
