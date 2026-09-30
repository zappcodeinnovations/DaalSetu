import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get.dart';
import 'package:agro_broker/network/api_client.dart';
import 'package:agro_broker/theme/app_theme.dart';

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
      
      Get.snackbar("Success", "Vehicle assigned successfully",
          backgroundColor: AppTheme.successGreen, colorText: Colors.white);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to assign vehicle: $e",
          backgroundColor: AppTheme.errorRed, colorText: Colors.white);
    } finally {
      if (mounted) {
        setState(() => _isAssigning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "Assign Vehicle to ${widget.driverName}",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context, false),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
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
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final v = _vehicles[index];
                              return ListTile(
                                tileColor: Theme.of(context).cardColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                                  ),
                                ),
                                leading: const CircleAvatar(
                                  child: Icon(Icons.local_shipping_outlined),
                                ),
                                title: Text(
                                  v['vehicle_number']?.toString() ?? 'Unknown',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  "${v['vehicle_brand_display'] ?? ''} ${v['vehicle_type'] ?? ''}".trim(),
                                ),
                                trailing: _isAssigning
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : FilledButton.tonal(
                                        onPressed: _isAssigning ? null : () => _assignVehicle(v),
                                        child: const Text("Select"),
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
