import 'package:daalsetu/network/api_client.dart';
import 'package:flutter/material.dart';

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
      if (data is! List)
        throw const FormatException('Invalid drivers response.');
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
    final action = driverId == null
        ? 'unassign ${widget.assignedDriverName ?? 'the driver'}'
        : 'assign ${driverName ?? 'this driver'}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm driver assignment'),
        content: Text('Do you want to $action for ${widget.vehicleNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await ApiClient.patch(
        endpoint: '/api/vehicles/${widget.vehicleId}/',
        data: {'driver_profile_id': driverId},
        requireAuth: true,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            driverId == null
                ? 'Driver unassigned.'
                : 'Driver assigned successfully.',
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update driver: $error')),
      );
      setState(() => _saving = false);
    }
  }

  String _driverName(Map<String, dynamic> driver) =>
      (driver['driver_name'] ??
              driver['name'] ??
              driver['username'] ??
              'Driver')
          .toString();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .72,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assign Driver',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.vehicleNumber,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Could not load drivers',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loadDrivers,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if ((widget.assignedDriverName ?? '').trim().isNotEmpty)
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.person_remove_outlined,
                color: Colors.red,
              ),
              title: const Text(
                'Unassign current driver',
                style: TextStyle(color: Colors.red),
              ),
              subtitle: Text(widget.assignedDriverName!),
              enabled: !_saving,
              onTap: _saving ? null : () => _setDriver(null),
            ),
          ),
        if (_drivers.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No free active drivers are available for this transporter.',
              textAlign: TextAlign.center,
            ),
          )
        else
          ..._drivers.map((driver) {
            final driverId = driver['id'];
            return Card(
              child: ListTile(
                leading: CircleAvatar(child: const Icon(Icons.person_outline)),
                title: Text(_driverName(driver)),
                subtitle: Text(
                  [driver['phone_number'], driver['license_number']]
                      .where(
                        (value) =>
                            value != null && value.toString().trim().isNotEmpty,
                      )
                      .join(' • '),
                ),
                trailing: const Icon(Icons.chevron_right),
                enabled: !_saving && driverId != null,
                onTap: _saving || driverId == null
                    ? null
                    : () =>
                          _setDriver(driverId, driverName: _driverName(driver)),
              ),
            );
          }),
      ],
    );
  }
}
