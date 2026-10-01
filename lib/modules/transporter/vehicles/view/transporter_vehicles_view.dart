import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../../../theme/glass_widgets.dart';
import '../controller/transporter_vehicle_controller.dart';
import './transporter_vehicle_form.dart';
import './transporter_vehicle_detail.dart';
import '../model/vehicle_model.dart';

class TransporterVehiclesView extends StatelessWidget {
  const TransporterVehiclesView({super.key});

  @override
  Widget build(BuildContext context) {
    final TransporterVehicleController controller = Get.put(TransporterVehicleController());
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(IconlyLight.filter), // Hamburger substitute
          onPressed: () {},
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "My Vehicles",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            Text(
              "Manage and track all your vehicles",
              style: GoogleFonts.inter(
                fontSize: 10,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(IconlyLight.search),
            onPressed: () {},
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(IconlyLight.notification),
                onPressed: () {},
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.deepOrange,
                    shape: BoxShape.circle,
                  ),
                  child: const Text('3', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: FloatingActionButton(
          onPressed: () => Get.to(() => const TransporterVehicleForm()),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          child: const Icon(IconlyLight.plus, size: 32),
        ),
      ),
      body: Column(
        children: [
          _buildFilterTabs(context, controller),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.vehicles.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final filtered = controller.filteredVehicles;

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(IconlyLight.document, size: 64, color: theme.colorScheme.primary.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text("No vehicles found", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => controller.fetchVehicles(),
                child: ListView.separated(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final vehicle = filtered[index];
                    return _buildVehicleCard(context, controller, vehicle);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(BuildContext context, TransporterVehicleController controller) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Obx(() {
        return Row(
          children: [
            _buildFilterPill(context, controller, 'All'),
            _buildFilterPill(context, controller, 'Active'),
            _buildFilterPill(context, controller, 'In Transit'),
            _buildFilterPill(context, controller, 'Maintenance'),
          ],
        );
      }),
    );
  }

  Widget _buildFilterPill(BuildContext context, TransporterVehicleController controller, String filter) {
    final theme = Theme.of(context);
    final isSelected = controller.selectedFilter.value == filter;
    final count = controller.getCount(filter);

    return GestureDetector(
      onTap: () => controller.selectedFilter.value = filter,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
          ),
        ),
        child: Text(
          "$filter ($count)",
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleCard(BuildContext context, TransporterVehicleController controller, VehicleModel vehicle) {
    final theme = Theme.of(context);
    
    String badgeText = vehicle.vehicleStatusDisplay.toUpperCase();
    if (badgeText.isEmpty) badgeText = 'UNKNOWN';
    Color badgeColor = Colors.grey;
    if (badgeText == 'ACTIVE' || badgeText == 'AVAILABLE') {
      badgeText = 'ACTIVE';
      badgeColor = Colors.green;
    } else if (badgeText == 'IN TRANSIT') {
      badgeColor = Colors.orange;
    } else if (badgeText == 'MAINTENANCE') {
      badgeColor = Colors.redAccent;
    }

    String modelStr = vehicle.vehicleBrandDisplay;
    if (vehicle.modelName != null && vehicle.modelName!.isNotEmpty) {
      modelStr += ' ${vehicle.modelName}';
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset('assets/images/truck.png', width: 80, height: 80, fit: BoxFit.contain),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            vehicle.vehicleNumber,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textTheme.bodyLarge?.color),
                          ),
                        ),
                        _buildStatusBadge(badgeText, badgeColor),
                        const SizedBox(width: 4),
                        Icon(Icons.more_vert, size: 16, color: theme.textTheme.bodyMedium?.color),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(modelStr, style: GoogleFonts.inter(fontSize: 12, color: theme.textTheme.bodyMedium?.color)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(IconlyLight.user_1, size: 14, color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(vehicle.assignedDriverName ?? "Unassigned", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(IconlyLight.bag, size: 14, color: theme.colorScheme.primary), // Using bag as fallback for payload
                        const SizedBox(width: 6),
                        Text("Payload: ${vehicle.loadCapacityTons} Ton", style: GoogleFonts.inter(fontSize: 12, color: theme.textTheme.bodyMedium?.color)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: theme.dividerColor.withOpacity(0.5), height: 1),
          ),
          
          // Details Grid Row
          Row(
            children: [
              Expanded(child: _buildDetailColumn(context, Icons.local_gas_station_outlined, "Fuel Type", "", vehicle.fuelType.isNotEmpty ? vehicle.fuelType : "—")),
              Container(width: 1, height: 30, color: theme.dividerColor.withOpacity(0.5)),
              Expanded(child: _buildDetailColumn(context, IconlyLight.calendar, "Year", "", "${vehicle.manufacturingYear ?? "—"}")),
              Container(width: 1, height: 30, color: theme.dividerColor.withOpacity(0.5)),
              Expanded(child: _buildDetailColumn(context, IconlyLight.shield_done, "Insurance", _formatDateDay(vehicle.insuranceExpiryDate), _formatDateMonthYear(vehicle.insuranceExpiryDate))),
              Container(width: 1, height: 30, color: theme.dividerColor.withOpacity(0.5)),
              Expanded(child: _buildDetailColumn(context, Icons.build_circle_outlined, "Fitness", _formatDateDay(vehicle.permitExpiryDate), _formatDateMonthYear(vehicle.permitExpiryDate))),
            ],
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: theme.dividerColor.withOpacity(0.5), height: 1),
          ),
          
          // Actions Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final details = await controller.fetchVehicleDetails(vehicle.id);
                    if (details != null) Get.to(() => TransporterVehicleDetail(vehicle: details));
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.2)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("View Details", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {}, // Trigger assign driver flow
                  icon: const Icon(IconlyLight.add_user, size: 16),
                  label: const Text("Assign Driver", style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailColumn(BuildContext context, IconData icon, String title, String highlightedValue, String normalValue) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text(title, style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (highlightedValue.isNotEmpty)
              Text(
                "$highlightedValue ",
                style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
              ),
            Expanded(
              child: Text(
                normalValue,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDateDay(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "";
    try {
      final date = DateTime.parse(dateStr);
      return date.day.toString().padLeft(2, '0');
    } catch (e) {
      return "";
    }
  }

  String _formatDateMonthYear(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "—";
    try {
      final date = DateTime.parse(dateStr);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
