import 'package:daalsetu/widgets/hero_header.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../../../routes/app_routes.dart';
import '../../drivers/model/driver_model.dart';
import '../controller/transporter_vehicle_controller.dart';
import './transporter_vehicle_form.dart';
import './transporter_vehicle_detail.dart';
import '../model/vehicle_model.dart';
import 'package:daalsetu/widgets/app_shell.dart';

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

    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: HeroHeader(
        title: "My Vehicles",
        subtitle: "Manage your registered fleet & drivers",
        leading: AppBarLeading(
          showBack: !inNavShell,
          child: !inNavShell
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
                  onPressed: () => Get.back(),
                )
              : null,
        ),
        trailing: IconButton(
          tooltip: "Notifications",
          icon: const Icon(IconlyLight.notification, color: Colors.white),
          onPressed: () => Get.toNamed(AppRoutes.transporterNotifications),
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: inNavShell ? 90 : 0),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF9800), Color(0xFFE65100)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE65100).withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () => _openForm(controller),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(IconlyLight.plus, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Add Vehicle",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              onChanged: (v) => controller.searchQuery.value = v,
              decoration: InputDecoration(
                hintText: "Search number, brand, driver...",
                hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                prefixIcon: const Icon(IconlyLight.search, size: 20, color: Color(0xFFE65100)),
                isDense: true,
                filled: true,
                fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF333333) : const Color(0xFFFFE0B2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF333333) : const Color(0xFFFFE0B2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFFFFB300),
                    width: 1.5,
                  ),
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
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = controller.selectedFilter.value == key;
    return GestureDetector(
      onTap: () => controller.selectedFilter.value = key,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFFFF9800), Color(0xFFE65100)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected
              ? null
              : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? const Color(0xFF333333) : const Color(0xFFFFE0B2)),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFE65100).withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          "$label (${controller.getCount(key)})",
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.grey.shade300 : const Color(0xFF2E1500)),
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
    final isDark = theme.brightness == Brightness.dark;
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

    return Container(
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
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF3D3D3D) : const Color(0xFFFFE0B2),
                  ),
                ),
                child: Image.asset(
                  'assets/images/truck.png',
                  width: 52,
                  height: 52,
                  fit: BoxFit.contain,
                ),
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
                              fontSize: 16,
                              color: isDark ? Colors.white : const Color(0xFF2E1500),
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
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
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
            padding: const EdgeInsets.only(top: 12, bottom: 12, right: 6),
            child: Divider(
              color: isDark ? const Color(0xFF333333) : const Color(0xFFFFE0B2).withValues(alpha: 0.6),
              height: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252525) : const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
              ),
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
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openDetail(controller, vehicle),
                    icon: const Icon(IconlyLight.show, size: 16),
                    label: const Text("View", maxLines: 1),
                    style: _buttonStyle(
                      OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE65100),
                        side: const BorderSide(
                          color: Color(0xFFFFB300),
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF9800), Color(0xFFE65100)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
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
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                        ),
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
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text("Cancel"),
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
