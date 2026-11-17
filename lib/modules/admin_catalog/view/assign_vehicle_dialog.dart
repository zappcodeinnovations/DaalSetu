import 'package:flutter/material.dart';
import 'package:daalsetu/network/api_client.dart';
import 'package:daalsetu/theme/app_theme.dart';
import '../../../utils/app_snackbar.dart';

class AssignVehicleDialog extends StatefulWidget {
  final String driverId;
  final String driverName;

  const AssignVehicleDialog({
    super.key,
    required this.driverId,
    required this.driverName,
  });

  @override
  State<AssignVehicleDialog> createState() => _AssignVehicleDialogState();
}

class _AssignVehicleDialogState extends State<AssignVehicleDialog> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _vehicles = [];
  bool _isAssigning = false;

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final response = await ApiClient.get(
        endpoint: '/api/vehicles/?vehicle_status=available',
        requireAuth: true,
      );
      
      final results = response is Map ? (response['results'] ?? response['value'] ?? response) : response;
      if (results is List) {
        setState(() {
          _vehicles = List<Map<String, dynamic>>.from(results);
          _isLoading = false;
        });
      } else {
        throw Exception("Invalid format: expected List");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  // Solid brand colour: the tonal button read as ghost text (QA).
  static final ButtonStyle _primaryAction = FilledButton.styleFrom(
    backgroundColor: const Color(0xFFF05A28),
    foregroundColor: Colors.white,
    textStyle: const TextStyle(fontWeight: FontWeight.w700),
  );

  Future<void> _assignVehicle(Map<String, dynamic> vehicle) async {
    final vehicleId = vehicle['id'];
    
    // Confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Assignment"),
        content: Text("Assign ${vehicle['vehicle_number']} to ${widget.driverName}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: _primaryAction,
            child: const Text("Assign"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() => _isAssigning = true);
      
      await ApiClient.post(
        endpoint: '/api/drivers/${widget.driverId}/assign-vehicle/',
        body: {'vehicle_id': vehicleId},
        requireAuth: true,
      );
      
      AppSnackbar.snackbar("Success", "Vehicle assigned successfully",
          backgroundColor: AppTheme.successGreen, colorText: Colors.white);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      AppSnackbar.snackbar("Error", "Failed to assign vehicle: $e",
          backgroundColor: AppTheme.errorRed, colorText: Colors.white);
    } finally {
      if (mounted) {
        setState(() => _isAssigning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.78,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFDF8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Saffron Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFEA580C), Color(0xFFF57C00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.local_shipping_outlined, color: Color(0xFFEA580C), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Assign Vehicle",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Driver: ${widget.driverName}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context, false),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text("Error: $_error"))
                    : _vehicles.isEmpty
                        ? const Center(child: Text("No available vehicles found."))
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _vehicles.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final v = _vehicles[index];
                              return Container(
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFFFE0B2),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF7ED),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFFFE0B2)),
                                    ),
                                    child: const Icon(Icons.local_shipping_outlined, color: Color(0xFFEA580C), size: 20),
                                  ),
                                  title: Text(
                                    v['vehicle_number']?.toString() ?? 'Unknown',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    "${v['vehicle_brand_display'] ?? ''} ${v['vehicle_type'] ?? ''}".trim(),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: _isAssigning
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : FilledButton(
                                          onPressed: _isAssigning ? null : () => _assignVehicle(v),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: const Color(0xFFF57C00),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: const Text("Select"),
                                        ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
