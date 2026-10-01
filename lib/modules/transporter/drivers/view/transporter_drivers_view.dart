import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../../../theme/glass_widgets.dart';
import '../controller/transporter_driver_controller.dart';
import './transporter_driver_form.dart';
import './transporter_driver_detail.dart';
import '../model/driver_model.dart';

class TransporterDriversView extends StatelessWidget {
  TransporterDriversView({super.key});

  final TransporterDriverController controller = Get.put(TransporterDriverController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(IconlyLight.arrow_left_2, color: theme.textTheme.bodyLarge?.color),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "My Drivers",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(IconlyLight.search, color: theme.textTheme.bodyLarge?.color),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(IconlyLight.filter, color: theme.textTheme.bodyLarge?.color),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0), // Above the nav bar
        child: FloatingActionButton.extended(
          heroTag: null,
          onPressed: () => Get.to(() => const TransporterDriverForm()),
          icon: const Icon(IconlyLight.plus),
          label: const Text("Register Driver", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
      body: Column(
        children: [
          _buildFilterTabs(context),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.drivers.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final filtered = controller.filteredDrivers;

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(IconlyLight.user_1, size: 64, color: theme.colorScheme.primary.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text("No drivers found", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => controller.fetchDrivers(),
                child: ListView.separated(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final driver = filtered[index];
                    return _buildDriverCard(context, driver);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Obx(() {
        return Row(
          children: [
            _buildFilterPill(context, 'All'),
            _buildFilterPill(context, 'Active'),
            _buildFilterPill(context, 'Unassigned'),
            _buildFilterPill(context, 'Inactive'),
          ],
        );
      }),
    );
  }

  Widget _buildFilterPill(BuildContext context, String filter) {
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

  Widget _buildDriverCard(BuildContext context, DriverModel driver) {
    final theme = Theme.of(context);
    
    // Determine badges based on status and assignment
    String badgeText = driver.status.toUpperCase() == 'ACTIVE' ? 'ACTIVE' : 'INACTIVE';
    Color badgeColor = driver.status.toUpperCase() == 'ACTIVE' ? Colors.green : Colors.grey;
    
    if (driver.assignmentStatus.toUpperCase() != 'ASSIGNED' && driver.status.toUpperCase() == 'ACTIVE') {
      badgeText = 'UNASSIGNED';
      badgeColor = Colors.orange;
    } else if (driver.statusDisplay.toUpperCase() == 'IN TRANSIT') {
      badgeText = 'IN TRANSIT';
      badgeColor = Colors.orange;
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Avatar, Info, Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: Icon(IconlyLight.user_1, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.driverName,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textTheme.bodyLarge?.color),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(IconlyLight.call, size: 12, color: theme.textTheme.bodyMedium?.color),
                        const SizedBox(width: 4),
                        Text(driver.phoneNumber, style: GoogleFonts.inter(fontSize: 12, color: theme.textTheme.bodyMedium?.color)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(IconlyLight.document, size: 12, color: theme.textTheme.bodyMedium?.color),
                        const SizedBox(width: 4),
                        Text(driver.licenseNumber, style: GoogleFonts.inter(fontSize: 12, color: theme.textTheme.bodyMedium?.color)),
                      ],
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(badgeText, badgeColor),
            ],
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: theme.dividerColor.withOpacity(0.5), height: 1),
          ),
          
          // Details Row: Experience, Expiry, Vehicle
          Row(
            children: [
              Expanded(child: _buildDetailColumn(context, IconlyLight.time_circle, "Experience", "${driver.experience ?? 0}", "Years")),
              Container(width: 1, height: 30, color: theme.dividerColor.withOpacity(0.5)),
              Expanded(child: _buildDetailColumn(context, IconlyLight.calendar, "License Expiry", _formatDateDay(driver.licenseExpiry), _formatDateMonthYear(driver.licenseExpiry))),
              Container(width: 1, height: 30, color: theme.dividerColor.withOpacity(0.5)),
              Expanded(child: _buildDetailColumn(context, IconlyLight.location, "Assigned Vehicle", "", driver.assignedVehicle?.vehicleNumber ?? "—")),
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
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final details = await controller.fetchDriverDetails(driver.id);
                    if (details != null) Get.to(() => TransporterDriverForm(driver: details));
                  },
                  icon: const Icon(IconlyLight.edit, size: 16),
                  label: const Text("Edit", style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.2)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showDeleteConfirmDialog(context, driver.id),
                  icon: const Icon(IconlyLight.delete, size: 16),
                  label: const Text("Delete", style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red.withOpacity(0.2)),
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 10, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text(title, style: GoogleFonts.inter(fontSize: 8, color: theme.textTheme.bodyMedium?.color)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (highlightedValue.isNotEmpty)
              Text(
                "$highlightedValue ",
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
              ),
            Text(
              normalValue,
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text("Delete Driver?"),
        content: const Text("Are you sure you want to delete this driver? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteDriver(id);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
