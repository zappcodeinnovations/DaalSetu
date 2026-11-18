import 'package:daalsetu/network/api_client.dart';
import 'package:flutter/material.dart';
import '../../../utils/app_snackbar.dart';

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
    final action = driverId == null
        ? 'unassign ${widget.assignedDriverName ?? 'the driver'}'
        : 'assign ${driverName ?? 'this driver'}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm driver assignment'),
        content: Text('Do you want to $action for ${widget.vehicleNumber}?'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
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
      AppSnackbar.showSnackBar(context, 
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
      AppSnackbar.showSnackBar(context, 
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .78,
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
                    child: const Icon(Icons.badge_outlined, color: Color(0xFFEA580C), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Assign Driver',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.vehicleNumber,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFECACA), width: 1.2),
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              leading: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_remove_outlined, color: Colors.red, size: 20),
              ),
              title: const Text(
                'Unassign current driver',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
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
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFFE0B2)),
                  ),
                  child: const Icon(Icons.person_outline, color: Color(0xFFEA580C), size: 20),
                ),
                title: Text(
                  _driverName(driver),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  [driver['phone_number'], driver['license_number']]
                      .where(
                        (value) =>
                            value != null && value.toString().trim().isNotEmpty,
                      )
                      .join(' • '),
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right, color: Color(0xFFEA580C)),
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
