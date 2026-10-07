import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../../../routes/app_routes.dart';
import '../../../../theme/glass_widgets.dart';
import '../../drivers/model/driver_model.dart';
import '../controller/transporter_vehicle_controller.dart';
import './transporter_vehicle_form.dart';
import './transporter_vehicle_detail.dart';
import '../model/vehicle_model.dart';

/// Web "Registered Vehicles": search, status filter, view, edit, delete, change status, assign driver.
class TransporterVehiclesView extends StatelessWidget {
  const TransporterVehiclesView({super.key});

  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'busy':
        return Colors.orange;
      case 'maintenance':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  static String brandText(VehicleModel v) {
    if (v.vehicleBrand == 'other' && (v.vehicleBrandOther ?? '').isNotEmpty) {
      return v.vehicleBrandOther!;
    }
    return v.vehicleBrandDisplay;
  }

  @override
  Widget build(BuildContext context) {
    final TransporterVehicleController controller = Get.put(
      TransporterVehicleController(),
    );
    final theme = Theme.of(context);
    // Inside the bottom-nav shell the floating bar covers the bottom ~90px.
    final inNavShell = !Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: !inNavShell,
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
              "Manage your registered vehicles",
              style: GoogleFonts.inter(
                fontSize: 10,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Notifications",
            icon: const Icon(IconlyLight.notification),
            onPressed: () => Get.toNamed(AppRoutes.transporterNotifications),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: inNavShell ? 90 : 0),
        child: FloatingActionButton.extended(
          heroTag: null,
          onPressed: () => _openForm(controller),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          icon: const Icon(IconlyLight.plus),
          label: const Text(
            "Add Vehicle",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: TextField(
              onChanged: (v) => controller.searchQuery.value = v,
              decoration: InputDecoration(
                hintText: "Search number, brand, driver...",
                prefixIcon: const Icon(IconlyLight.search, size: 20),
                isDense: true,
                filled: true,
                fillColor: theme.colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
              ),
            ),
          ),
          _buildFilterTabs(context, controller),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.vehicles.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              final filtered = controller.filteredVehicles;
              return RefreshIndicator(
                onRefresh: controller.fetchVehicles,
                child: filtered.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 100),
                          Icon(
                            IconlyLight.document,
                            size: 64,
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              controller.vehicles.isEmpty
                                  ? "No vehicles registered yet"
                                  : "No vehicles match this filter",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 180),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) => _buildVehicleCard(
                          context,
                          controller,
                          filtered[index],
                        ),
                      ),
              );
            }),
          ),
        ],
      ),
    );
  }

  static Future<void> _openForm(
    TransporterVehicleController controller, [
    VehicleModel? vehicle,
  ]) async {
    await Get.to(() => TransporterVehicleForm(vehicle: vehicle));
  }

  Widget _buildFilterTabs(
    BuildContext context,
    TransporterVehicleController controller,
  ) {
    final filters = {
      'all': 'All',
      ...TransporterVehicleController.statusLabels,
    };
    return SizedBox(
      height: 52,
      child: Obx(() {
        controller.vehicles.length; // rebuild counts when the list changes
        return ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          children: filters.entries
              .map((e) => _buildFilterPill(context, controller, e.key, e.value))
              .toList(),
        );
      }),
    );
  }

  Widget _buildFilterPill(
    BuildContext context,
    TransporterVehicleController controller,
    String key,
    String label,
  ) {
    final theme = Theme.of(context);
    final isSelected = controller.selectedFilter.value == key;
    return GestureDetector(
      onTap: () => controller.selectedFilter.value = key,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
          ),
        ),
        child: Text(
          "$label (${controller.getCount(key)})",
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? Colors.white
                : theme.textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleCard(
    BuildContext context,
    TransporterVehicleController controller,
    VehicleModel vehicle,
  ) {
    final theme = Theme.of(context);
    final color = statusColor(vehicle.vehicleStatus);
    final statusText =
        TransporterVehicleController.statusLabels[vehicle.vehicleStatus] ??
        (vehicle.vehicleStatusDisplay.isEmpty
            ? 'Unknown'
            : vehicle.vehicleStatusDisplay);
    final hasDriver = vehicle.hasDriver;
    final subtitle = [
      brandText(vehicle),
      vehicle.modelName ?? '',
      vehicle.vehicleType,
    ].where((s) => s.trim().isNotEmpty).join(' • ');

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/images/truck.png',
                width: 64,
                height: 64,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            vehicle.vehicleNumber,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildStatusBadge(statusText.toUpperCase(), color),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _iconLine(
                      context,
                      IconlyLight.profile,
                      hasDriver
                          ? vehicle.assignedDriverName!
                          : "No driver assigned",
                      bold: hasDriver,
                    ),
                    const SizedBox(height: 2),
                    _iconLine(
                      context,
                      IconlyLight.bag,
                      "Capacity: ${vehicle.loadCapacityTons} Ton",
                    ),
                  ],
                ),
              ),
              _buildMenu(context, controller, vehicle),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 10, right: 10),
            child: Divider(
              color: theme.dividerColor.withValues(alpha: 0.5),
              height: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Row(
              children: [
                Expanded(
                  child: _buildDetailColumn(
                    context,
                    Icons.local_gas_station_outlined,
                    "Fuel",
                    _cap(vehicle.fuelType),
                  ),
                ),
                Expanded(
                  child: _buildDetailColumn(
                    context,
                    IconlyLight.calendar,
                    "Year",
                    "${vehicle.manufacturingYear ?? "—"}",
                  ),
                ),
                Expanded(
                  child: _buildDetailColumn(
                    context,
                    IconlyLight.shield_done,
                    "Insurance",
                    _formatDate(vehicle.insuranceExpiryDate),
                  ),
                ),
                Expanded(
                  child: _buildDetailColumn(
                    context,
                    IconlyLight.paper,
                    "Permit",
                    _formatDate(vehicle.permitExpiryDate),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openDetail(controller, vehicle),
                    icon: const Icon(IconlyLight.show, size: 16),
                    label: const Text("View", maxLines: 1),
                    style: _buttonStyle(
                      OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        side: BorderSide(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        showAssignDriverSheet(context, controller, vehicle),
                    icon: const Icon(IconlyLight.add_user, size: 16),
                    label: Text(
                      hasDriver ? "Change Driver" : "Assign Driver",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: _buttonStyle(
                      ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _buttonStyle(ButtonStyle base) => base.copyWith(
    minimumSize: const WidgetStatePropertyAll(Size(0, 40)),
    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 8)),
    textStyle: WidgetStatePropertyAll(
      GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
    ),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );

  Widget _buildMenu(
    BuildContext context,
    TransporterVehicleController controller,
    VehicleModel vehicle,
  ) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      padding: EdgeInsets.zero,
      onSelected: (action) {
        switch (action) {
          case 'view':
            _openDetail(controller, vehicle);
            break;
          case 'edit':
            _openForm(controller, vehicle);
            break;
          case 'driver':
            showAssignDriverSheet(context, controller, vehicle);
            break;
          case 'status':
            showStatusSheet(context, controller, vehicle);
            break;
          case 'delete':
            confirmDelete(controller, vehicle);
            break;
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'view',
          child: ListTile(
            dense: true,
            leading: Icon(IconlyLight.show),
            title: Text('View Details'),
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: ListTile(
            dense: true,
            leading: Icon(IconlyLight.edit),
            title: Text('Edit'),
          ),
        ),
        PopupMenuItem(
          value: 'driver',
          child: ListTile(
            dense: true,
            leading: Icon(IconlyLight.add_user),
            title: Text('Assign Driver'),
          ),
        ),
        PopupMenuItem(
          value: 'status',
          child: ListTile(
            dense: true,
            leading: Icon(IconlyLight.swap),
            title: Text('Change Status'),
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            dense: true,
            leading: Icon(IconlyLight.delete, color: Colors.red),
            title: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ),
      ],
    );
  }

  static Future<void> _openDetail(
    TransporterVehicleController controller,
    VehicleModel vehicle,
  ) async {
    final details = await controller.fetchVehicleDetails(vehicle.id);
    Get.to(() => TransporterVehicleDetail(vehicle: details ?? vehicle));
  }

  static Future<bool> confirmDelete(
    TransporterVehicleController controller,
    VehicleModel vehicle,
  ) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text("Delete Vehicle"),
        content: Text(
          "Delete ${vehicle.vehicleNumber}? This cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;
    return controller.deleteVehicle(vehicle.id);
  }

  static Future<void> showStatusSheet(
    BuildContext context,
    TransporterVehicleController controller,
    VehicleModel vehicle,
  ) async {
    final status = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Change Status - ${vehicle.vehicleNumber}",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            ...TransporterVehicleController.statusLabels.entries.map(
              (e) => ListTile(
                leading: Icon(
                  Icons.circle,
                  size: 12,
                  color: statusColor(e.key),
                ),
                title: Text(e.value),
                trailing: vehicle.vehicleStatus == e.key
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () => Navigator.pop(ctx, e.key),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (status != null && status != vehicle.vehicleStatus) {
      await controller.changeStatus(vehicle, status);
    }
  }

  /// Lists active drivers that are free (or already on this vehicle), plus "Unassign".
  static Future<void> showAssignDriverSheet(
    BuildContext context,
    TransporterVehicleController controller,
    VehicleModel vehicle,
  ) async {
    final driversFuture = controller.fetchAssignableDrivers(vehicle);
    final picked = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.7,
          ),
          child: FutureBuilder<List<DriverModel>>(
            future: driversFuture,
            builder: (ctx, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final drivers = snap.data ?? const <DriverModel>[];
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Assign Driver - ${vehicle.vehicleNumber}",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (vehicle.hasDriver)
                    ListTile(
                      leading: const Icon(
                        Icons.person_remove_outlined,
                        color: Colors.red,
                      ),
                      title: const Text(
                        "Unassign current driver",
                        style: TextStyle(color: Colors.red),
                      ),
                      subtitle: Text(vehicle.assignedDriverName ?? ''),
                      onTap: () => Navigator.pop(ctx, -1),
                    ),
                  if (drivers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        "No free active drivers. Register a driver or unassign one from another vehicle.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: Colors.grey),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: drivers.map((d) {
                          final current = d.assignedVehicle?.id == vehicle.id;
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                d.driverName.isEmpty
                                    ? '?'
                                    : d.driverName[0].toUpperCase(),
                              ),
                            ),
                            title: Text(d.driverName),
                            subtitle: Text(
                              "${d.phoneNumber} • ${d.licenseNumber}",
                            ),
                            trailing: current
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                : null,
                            onTap: () =>
                                Navigator.pop(ctx, current ? null : d.id),
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        ),
      ),
    );
    if (picked == null) return;
    await controller.assignDriver(vehicle, picked == -1 ? null : picked);
  }

  Widget _iconLine(
    BuildContext context,
    IconData icon,
    String text, {
    bool bold = false,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
              color: bold
                  ? theme.textTheme.bodyLarge?.color
                  : theme.textTheme.bodyMedium?.color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailColumn(
    BuildContext context,
    IconData icon,
    String title,
    String value,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }

  static String _cap(String s) => s.isEmpty
      ? "—"
      : (s.length <= 3 ? s.toUpperCase() : s[0].toUpperCase() + s.substring(1));

  static String _formatDate(String? dateStr) {
    final date = DateTime.tryParse(dateStr ?? '');
    if (date == null) return "—";
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year % 100}';
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
