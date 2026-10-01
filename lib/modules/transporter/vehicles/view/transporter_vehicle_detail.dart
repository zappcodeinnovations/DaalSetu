import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../../../theme/glass_widgets.dart';
import '../model/vehicle_model.dart';

class TransporterVehicleDetail extends StatelessWidget {
  final VehicleModel vehicle;

  const TransporterVehicleDetail({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Vehicle Details",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
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
                          color: theme.colorScheme.primary.withOpacity(0.1),
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
                              vehicle.vehicleStatus == 'available' ? Colors.green : Colors.orange,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  _buildSectionHeader("Basic Information"),
                  _buildDetailRow("Brand", vehicle.vehicleBrandDisplay),
                  _buildDetailRow("Model", vehicle.modelName?.isNotEmpty == true ? vehicle.modelName! : "N/A"),
                  _buildDetailRow("Manufacturing Year", vehicle.manufacturingYear?.toString() ?? "N/A"),
                  _buildDetailRow("Fuel Type", vehicle.fuelType.toUpperCase()),
                  
                  const SizedBox(height: 16),
                  _buildSectionHeader("Specifications"),
                  _buildDetailRow("Load Capacity", "${vehicle.loadCapacityTons} Tons"),
                  _buildDetailRow("Body Type", vehicle.bodyTypeDisplay),
                  _buildDetailRow("Number of Axles", vehicle.numberOfAxles?.toString() ?? "N/A"),
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
                  _buildDetailRow("Permit Type", vehicle.permitTypeDisplay?.isNotEmpty == true ? vehicle.permitTypeDisplay! : "N/A"),
                  _buildDetailRow("Permit Expiry", vehicle.permitExpiryDate ?? "N/A"),
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
                  if (vehicle.assignedDriver != null && vehicle.assignedDriverName?.isNotEmpty == true) ...[
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
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
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
