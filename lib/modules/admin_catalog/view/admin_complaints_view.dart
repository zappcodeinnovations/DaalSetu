import 'package:daalsetu/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

class AdminComplaintsView extends StatefulWidget {
  final int? initialOpenCount;
  const AdminComplaintsView({super.key, this.initialOpenCount});

  @override
  State<AdminComplaintsView> createState() => _AdminComplaintsViewState();
}

class _AdminComplaintsViewState extends State<AdminComplaintsView> {
  String selectedFilter = 'All';
  final TextEditingController searchController = TextEditingController();

  final List<Map<String, dynamic>> _complaints = [
    {
      'id': 'CMP-1042',
      'category': 'Quality',
      'title': 'Moisture & Foreign Matter Variance',
      'contract_id': 'JBC2610183467',
      'raised_by': 'Test Buyer (Buyer)',
      'against': 'Agro Supplier Ltd (Seller)',
      'severity': 'High',
      'status': 'Open',
      'created_at': '18 Oct 2026, 02:40 PM',
      'description':
          'Reported moisture content of 14.2% vs contracted 12% max. Sample sent to lab for re-verification.',
    },
    {
      'id': 'CMP-1039',
      'category': 'Logistics',
      'title': 'Delayed Dispatch by Transporter',
      'contract_id': 'JBC2610186577',
      'raised_by': 'MerryLand Foods (Buyer)',
      'against': 'TransCo Logistics (Transporter)',
      'severity': 'Medium',
      'status': 'Under Review',
      'created_at': '17 Oct 2026, 11:15 AM',
      'description':
          'Vehicle not placed at warehouse within agreed SLA of 24h. Pickup rescheduled.',
    },
    {
      'id': 'CMP-1031',
      'category': 'Weight',
      'title': 'Gross Weight Discrepancy at Weighbridge',
      'contract_id': 'JBC2607288709',
      'raised_by': 'Farmland Mills (Buyer)',
      'against': 'Direct Agro (Seller)',
      'severity': 'High',
      'status': 'Open',
      'created_at': '16 Oct 2026, 04:20 PM',
      'description':
          'Bilty gross weight is 50.100 Qtl but weighbridge slips indicate 49.350 Qtl. Shortage of 75kg.',
    },
    {
      'id': 'CMP-1025',
      'category': 'Payment',
      'title': 'TDS Certificate Not Provided',
      'contract_id': 'JBC2607283936',
      'raised_by': 'Quality Foods Ltd (Buyer)',
      'against': 'Admin Desk',
      'severity': 'Low',
      'status': 'Resolved',
      'created_at': '14 Oct 2026, 09:30 AM',
      'description':
          'TDS Form 16A was missing for Q2 brokerage invoice. Certificate emailed and verified.',
    },
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredList {
    final query = searchController.text.trim().toLowerCase();
    return _complaints.where((c) {
      if (selectedFilter != 'All' && c['category'] != selectedFilter) {
        return false;
      }
      if (query.isEmpty) return true;
      final text = '${c['id']} ${c['title']} ${c['contract_id']} ${c['raised_by']} ${c['description']}'.toLowerCase();
      return text.contains(query);
    }).toList();
  }

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return AppTheme.errorRed;
      case 'medium':
        return AppTheme.secondaryOrange;
      default:
        return AppTheme.primaryGold;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return AppTheme.errorRed;
      case 'under review':
        return AppTheme.secondaryOrange;
      case 'resolved':
        return AppTheme.successGreen;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final openCount = widget.initialOpenCount ?? _complaints.where((c) => c['status'] != 'Resolved').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaints & Issues'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Complaints list updated.')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // KPI Metric Banner
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            child: Row(
              children: [
                Expanded(
                  child: _kpiPill(
                    context,
                    label: 'Open Issues',
                    count: '$openCount',
                    color: AppTheme.errorRed,
                    icon: IconlyBold.danger,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _kpiPill(
                    context,
                    label: 'In Investigation',
                    count: '1',
                    color: AppTheme.secondaryOrange,
                    icon: IconlyBold.time_circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _kpiPill(
                    context,
                    label: 'Resolved MTD',
                    count: '12',
                    color: AppTheme.successGreen,
                    icon: IconlyBold.shield_done,
                  ),
                ),
              ],
            ),
          ),

          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by ticket ID, contract, party...',
                prefixIcon: const Icon(IconlyLight.search, size: 20),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
                ),
              ),
            ),
          ),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: ['All', 'Quality', 'Logistics', 'Weight', 'Payment'].map((category) {
                final isSelected = selectedFilter == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => selectedFilter = category);
                    },
                    selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),

          // Complaints List
          Expanded(
            child: _filteredList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(IconlyLight.info_circle, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'No complaints found matching criteria',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _filteredList[index];
                      return _complaintCard(context, item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _kpiPill(
    BuildContext context, {
    required String label,
    required String count,
    required Color color,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const Spacer(),
              Text(
                count,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _complaintCard(BuildContext context, Map<String, dynamic> item) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(item['status'] as String);
    final sevColor = _severityColor(item['severity'] as String);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item['id'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: sevColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${item['severity']} Priority',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: sevColor,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    item['status'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item['title'] as String,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              item['description'] as String,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
                height: 1.35,
              ),
            ),
            const Divider(height: 20),
            Row(
              children: [
                Icon(Icons.description_outlined, size: 14, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  'Contract: ${item['contract_id']}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  item['created_at'] as String,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showTicketActionDialog(context, item);
                    },
                    icon: const Icon(Icons.support_agent_outlined, size: 16),
                    label: const Text('Update Status'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Notified party for ${item['id']}'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text('Contact Party'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTicketActionDialog(BuildContext context, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update ${item['id']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Status: ${item['status']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            const Text('Change status to:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Open', 'Under Review', 'Resolved'].map((st) {
                return ChoiceChip(
                  label: Text(st),
                  selected: item['status'] == st,
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        item['status'] = st;
                      });
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Status updated to $st')),
                      );
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
