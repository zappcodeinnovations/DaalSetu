import 'package:flutter/material.dart';
import 'package:daalsetu/network/api_client.dart';
import 'package:daalsetu/theme/app_theme.dart';
import '../../../utils/app_snackbar.dart';
import 'assign_picker_sheet.dart';

class AssignVehicleDialog extends StatefulWidget {
  final String driverId;
  final String driverName;

  /// Vehicle number the driver has now, if any (shown, and offered for Unassign).
  final String? assignedVehicleNumber;

  /// Only vehicles of this transporter can be assigned.
  final String? transporterId;

  const AssignVehicleDialog({
    super.key,
    required this.driverId,
    required this.driverName,
    this.assignedVehicleNumber,
    this.transporterId,
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
        endpoint: (widget.transporterId ?? '').isNotEmpty
            ? '/api/vehicles/?vehicle_status=available&transporter_id=${Uri.encodeQueryComponent(widget.transporterId!)}'
            : '/api/vehicles/?vehicle_status=available',
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

  Future<void> _setVehicle(Object? vehicleId, {String? number}) async {
    final unassign = vehicleId == null;
    final confirmed = await confirmAssignment(
      context,
      title: unassign ? 'Confirm Unassign' : 'Confirm Assignment',
      message: unassign
          ? 'Unassign ${widget.assignedVehicleNumber ?? 'the vehicle'} from ${widget.driverName}?'
          : 'Assign ${number ?? 'this vehicle'} to ${widget.driverName}?',
      confirmText: unassign ? 'Unassign' : 'Assign',
      confirmColor: unassign ? Colors.red : const Color(0xFFF05A28),
    );
    if (!confirmed || !mounted) return;

    try {
      setState(() => _isAssigning = true);
      await ApiClient.post(
        endpoint: '/api/drivers/${widget.driverId}/assign-vehicle/',
        body: {'vehicle_id': vehicleId},
        requireAuth: true,
      );
      AppSnackbar.snackbar(
        'Success',
        unassign ? 'Vehicle unassigned successfully' : 'Vehicle assigned successfully',
        backgroundColor: AppTheme.successGreen,
        colorText: Colors.white,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      AppSnackbar.snackbar(
        'Error',
        'Failed to ${unassign ? 'unassign' : 'assign'} vehicle: $e',
        backgroundColor: AppTheme.errorRed,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isAssigning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = <AssignPickerItem>[
      for (final v in _vehicles)
        if (v['id'] != null)
          AssignPickerItem(
            id: v['id'] as Object,
            title: v['vehicle_number']?.toString() ?? 'Unknown',
            subtitle: "${v['vehicle_brand_display'] ?? ''} ${v['vehicle_type'] ?? ''}".trim(),
          ),
    ];
    return AssignPickerSheet(
      title: 'Assign Vehicle',
      subtitle: 'Driver: ${widget.driverName}',
      icon: Icons.local_shipping_outlined,
      noun: 'vehicle',
      items: items,
      loading: _isLoading,
      saving: _isAssigning,
      error: _error,
      onRetry: _fetchVehicles,
      currentLabel: widget.assignedVehicleNumber,
      emptyText: 'No available vehicles found.',
      onClose: () => Navigator.pop(context, false),
      onAssign: (item) => _setVehicle(item.id, number: item.title),
      onUnassign: () => _setVehicle(null),
    );
  }
}
