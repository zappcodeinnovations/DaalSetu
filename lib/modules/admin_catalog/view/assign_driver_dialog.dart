import 'package:daalsetu/network/api_client.dart';
import 'package:flutter/material.dart';
import '../../../utils/app_snackbar.dart';
import 'assign_picker_sheet.dart';

/// Lets an admin select an active, unassigned driver for a vehicle.
///
/// The API applies the final transporter and assignment checks, while the
/// filtered list keeps the picker limited to drivers that can actually be used.
class AssignDriverDialog extends StatefulWidget {
  const AssignDriverDialog({
    super.key,
    required this.vehicleId,
    required this.vehicleNumber,
    this.transporterId,
    this.assignedDriverName,
  });

  final String vehicleId;
  final String vehicleNumber;
  final String? transporterId;
  final String? assignedDriverName;

  @override
  State<AssignDriverDialog> createState() => _AssignDriverDialogState();
}

class _AssignDriverDialogState extends State<AssignDriverDialog> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<Map<String, dynamic>> _drivers = const [];

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final parameters = <String>[
        'status=active',
        'exclude_assigned=true',
        'current_vehicle_id=${Uri.encodeQueryComponent(widget.vehicleId)}',
      ];
      final transporterId = widget.transporterId?.trim() ?? '';
      if (transporterId.isNotEmpty) {
        parameters.add(
          'transporter_id=${Uri.encodeQueryComponent(transporterId)}',
        );
      }
      final response = await ApiClient.get(
        endpoint: '/api/drivers/?${parameters.join('&')}',
        requireAuth: true,
      );
      final data = response is Map
          ? (response['results'] ??
                response['data'] ??
                response['value'] ??
                response)
          : response;
      if (data is! List) {
        throw const FormatException('Invalid drivers response.');
      }
      if (!mounted) return;
      setState(() {
        _drivers = data
            .whereType<Map>()
            .map((driver) => Map<String, dynamic>.from(driver))
            .toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _setDriver(Object? driverId, {String? driverName}) async {
    final unassign = driverId == null;
    final action = unassign
        ? 'unassign ${widget.assignedDriverName ?? 'the driver'}'
        : 'assign ${driverName ?? 'this driver'}';
    final confirmed = await confirmAssignment(
      context,
      title: 'Confirm driver assignment',
      message: 'Do you want to $action for ${widget.vehicleNumber}?',
      confirmText: unassign ? 'Unassign' : 'Assign',
      confirmColor: unassign ? Colors.red : const Color(0xFFF05A28),
    );
    if (!confirmed || !mounted) return;

    setState(() => _saving = true);
    try {
      await ApiClient.patch(
        endpoint: '/api/vehicles/${widget.vehicleId}/',
        data: {'driver_profile_id': driverId},
        requireAuth: true,
      );
      if (!mounted) return;
      AppSnackbar.showSnackBar(
        context,
        SnackBar(content: Text(unassign ? 'Driver unassigned.' : 'Driver assigned successfully.')),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      AppSnackbar.showSnackBar(context, SnackBar(content: Text('Could not update driver: $error')));
      setState(() => _saving = false);
    }
  }

  String _driverName(Map<String, dynamic> driver) =>
      (driver['driver_name'] ?? driver['name'] ?? driver['username'] ?? 'Driver').toString();

  @override
  Widget build(BuildContext context) {
    final items = <AssignPickerItem>[
      for (final driver in _drivers)
        if (driver['id'] != null)
          AssignPickerItem(
            id: driver['id'] as Object,
            title: _driverName(driver),
            subtitle: [driver['phone_number'], driver['license_number']]
                .where((value) => value != null && value.toString().trim().isNotEmpty)
                .join(' • '),
          ),
    ];
    return AssignPickerSheet(
      title: 'Assign Driver',
      subtitle: widget.vehicleNumber,
      icon: Icons.badge_outlined,
      noun: 'driver',
      items: items,
      loading: _loading,
      saving: _saving,
      error: _error,
      onRetry: _loadDrivers,
      currentLabel: widget.assignedDriverName,
      emptyText: 'No free active drivers are available for this transporter.',
      onClose: () => Navigator.pop(context),
      onAssign: (item) => _setDriver(item.id, driverName: item.title),
      onUnassign: () => _setDriver(null),
    );
  }
}
