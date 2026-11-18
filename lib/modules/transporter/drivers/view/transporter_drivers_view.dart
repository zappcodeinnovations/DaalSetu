import 'package:daalsetu/widgets/hero_header.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../vehicles/model/vehicle_model.dart';
import '../controller/transporter_driver_controller.dart';
import './transporter_driver_form.dart';
import './transporter_driver_detail.dart';
import '../model/driver_model.dart';
import 'package:daalsetu/widgets/app_shell.dart';
import '../../../../utils/app_snackbar.dart';

/// Web "Registered Drivers": search, status filter, register, edit, delete, assign vehicle, view license.
class TransporterDriversView extends StatelessWidget {
  TransporterDriversView({super.key});

  final TransporterDriverController controller = Get.put(
    TransporterDriverController(),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Inside the bottom-nav shell the floating bar covers the bottom ~90px.
    final inNavShell = !Navigator.of(context).canPop();

    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: HeroHeader(
        title: "My Drivers",
        subtitle: "Register drivers and assign vehicles",
        leading: AppBarLeading(
          showBack: !inNavShell,
          child: !inNavShell
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
                  onPressed: () => Get.back(),
                )
              : null,
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
              onTap: () => Get.to(() => const TransporterDriverForm()),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(IconlyLight.add_user, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Register Driver",
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
                hintText: "Search name, phone, license, vehicle...",
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
          _buildFilterTabs(context),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.drivers.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              final filtered = controller.filteredDrivers;
              return RefreshIndicator(
                onRefresh: controller.fetchDrivers,
                child: filtered.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 100),
                          Icon(
                            IconlyLight.user_1,
                            size: 64,
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              controller.drivers.isEmpty
                                  ? "No drivers registered yet"
                                  : "No drivers match this filter",
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
                        itemBuilder: (context, index) =>
                            _buildDriverCard(context, filtered[index]),
                      ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Obx(() {
        controller.drivers.length; // rebuild counts when the list changes
        return ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          children: TransporterDriverController.filterLabels.entries
              .map((e) => _buildFilterPill(context, e.key, e.value))
              .toList(),
        );
      }),
    );
  }

  Widget _buildFilterPill(BuildContext context, String key, String label) {
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

  Widget _buildDriverCard(BuildContext context, DriverModel driver) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isActive = driver.status.toLowerCase() == 'active';
    final vehicle = driver.assignedVehicle;
    final badgeText = !isActive
        ? 'INACTIVE'
        : (vehicle == null ? 'UNASSIGNED' : 'ON VEHICLE');
    final badgeColor = !isActive
        ? Colors.grey
        : (vehicle == null ? Colors.orange : Colors.green);

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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12),
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
                    fontSize: 20,
                    color: const Color(0xFFE65100),
                  ),
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
                            driver.driverName,
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
                        _buildStatusBadge(badgeText, badgeColor),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _iconLine(context, IconlyLight.call, driver.phoneNumber),
                    const SizedBox(height: 2),
                    _iconLine(
                      context,
                      IconlyLight.document,
                      driver.licenseNumber,
                    ),
                  ],
                ),
              ),
              _buildMenu(context, driver),
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
                      IconlyLight.time_circle,
                      "Experience",
                      "${driver.experience ?? 0} Yrs",
                    ),
                  ),
                  Expanded(
                    child: _buildDetailColumn(
                      context,
                      IconlyLight.calendar,
                      "License Expiry",
                      _formatDate(driver.licenseExpiry),
                    ),
                  ),
                  Expanded(
                    child: _buildDetailColumn(
                      context,
                      Icons.local_shipping_outlined,
                      "Vehicle",
                      vehicle?.vehicleNumber ?? "—",
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
                    onPressed: () => _openDetail(driver),
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
                      gradient: isActive
                          ? const LinearGradient(
                              colors: [Color(0xFFFF9800), Color(0xFFE65100)],
                            )
                          : null,
                      color: isActive ? null : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: isActive
                          ? () => _showAssignVehicleSheet(context, driver)
                          : null,
                      icon: const Icon(Icons.local_shipping_outlined, size: 16),
                      label: Text(
                        vehicle == null ? "Assign Vehicle" : "Change Vehicle",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: _buttonStyle(
                        ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white70,
                          disabledBackgroundColor: Colors.transparent,
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

  Widget _buildMenu(BuildContext context, DriverModel driver) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      padding: EdgeInsets.zero,
      onSelected: (action) async {
        switch (action) {
          case 'view':
            _openDetail(driver);
            break;
          case 'edit':
            _openEdit(driver);
            break;
          case 'vehicle':
            if (context.mounted) _showAssignVehicleSheet(context, driver);
            break;
          case 'license':
            final ok = await launchUrl(
              Uri.parse(driver.licenseUploadUrl!),
              mode: LaunchMode.externalApplication,
            );
            if (!ok) {
              AppSnackbar.snackbar(
                "Error",
                "Unable to open license document",
                snackPosition: SnackPosition.BOTTOM,
              );
            }
            break;
          case 'delete':
            _confirmDelete(driver);
            break;
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'view',
          child: ListTile(
            dense: true,
            leading: Icon(IconlyLight.show),
            title: Text('View Details'),
          ),
        ),
        const PopupMenuItem(
          value: 'edit',
          child: ListTile(
            dense: true,
            leading: Icon(IconlyLight.edit),
            title: Text('Edit'),
          ),
        ),
        if (driver.status.toLowerCase() == 'active')
          const PopupMenuItem(
            value: 'vehicle',
            child: ListTile(
              dense: true,
              leading: Icon(Icons.local_shipping_outlined),
              title: Text('Assign Vehicle'),
            ),
          ),
        if (driver.licenseUploadUrl != null)
          const PopupMenuItem(
            value: 'license',
            child: ListTile(
              dense: true,
              leading: Icon(IconlyLight.document),
              title: Text('View License'),
            ),
          ),
        const PopupMenuItem(
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

  Future<void> _openDetail(DriverModel driver) async {
    final details = await controller.fetchDriverDetails(driver.id);
    Get.to(() => TransporterDriverDetail(driver: details ?? driver));
  }

  Future<void> _openEdit(DriverModel driver) async {
    final details = await controller.fetchDriverDetails(driver.id);
    Get.to(() => TransporterDriverForm(driver: details ?? driver));
  }

  Future<void> _confirmDelete(DriverModel driver) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text("Delete Driver"),
        content: Text("Delete ${driver.driverName}? This cannot be undone."),
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
    if (confirmed == true) await controller.deleteDriver(driver.id);
  }

  /// Available vehicles without another driver, plus "Unassign" (POST assign-vehicle).
  Future<void> _showAssignVehicleSheet(
    BuildContext context,
    DriverModel driver,
  ) async {
    final vehiclesFuture = controller.fetchAssignableVehicles(driver);
    final picked = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.7,
          ),
          child: FutureBuilder<List<VehicleModel>>(
            future: vehiclesFuture,
            builder: (ctx, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final vehicles = snap.data ?? const <VehicleModel>[];
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Assign Vehicle - ${driver.driverName}",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (driver.assignedVehicle != null)
                    ListTile(
                      leading: const Icon(Icons.link_off, color: Colors.red),
                      title: const Text(
                        "Unassign current vehicle",
                        style: TextStyle(color: Colors.red),
                      ),
                      subtitle: Text(driver.assignedVehicle!.vehicleNumber),
                      onTap: () => Navigator.pop(ctx, -1),
                    ),
                  if (vehicles.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        "No available vehicles. Only vehicles with status Available and no driver can be assigned.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: Colors.grey),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: vehicles.map((v) {
                          final current = v.id == driver.assignedVehicle?.id;
                          return ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.local_shipping_outlined),
                            ),
                            title: Text(v.vehicleNumber),
                            subtitle: Text(
                              [
                                v.vehicleBrandDisplay,
                                v.vehicleType,
                                "${v.loadCapacityTons} Ton",
                              ].where((s) => s.trim().isNotEmpty).join(' • '),
                            ),
                            trailing: current
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                : null,
                            onTap: () =>
                                Navigator.pop(ctx, current ? null : v.id),
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
    await controller.assignVehicle(driver.id, picked == -1 ? null : picked);
  }

  Widget _iconLine(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 12, color: theme.textTheme.bodyMedium?.color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: theme.textTheme.bodyMedium?.color,
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

  String _formatDate(String? dateStr) {
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
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
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
