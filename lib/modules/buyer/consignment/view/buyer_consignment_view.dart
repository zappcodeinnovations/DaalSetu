import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../services/buyer_services.dart';
import '../../../../theme/glass_widgets.dart';
import '../../../../utils/app_snackbar.dart';

class BuyerConsignmentView extends StatefulWidget {
  const BuyerConsignmentView({super.key});

  @override
  State<BuyerConsignmentView> createState() => _BuyerConsignmentViewState();
}

class _BuyerConsignmentViewState extends State<BuyerConsignmentView> {
  final _searchController = TextEditingController();
  final _items = <Map<String, dynamic>>[];
  String _workflow = 'all';
  String _error = '';
  bool _loading = true;

  static const _workflows = <String>[
    'all',
    'pending',
    'ready',
    'dispatch',
    'received',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final response = await BuyerServices.getConsignments(
        workflowStatus: _workflow,
        search: _searchController.text,
      );
      final raw = response['results'];
      if (mounted) {
        setState(() {
          _items
            ..clear()
            ..addAll(
              raw is List
                  ? raw.whereType<Map>().map(
                      (item) => Map<String, dynamic>.from(item),
                    )
                  : const <Map<String, dynamic>>[],
            );
        });
      }
    } catch (error) {
      if (mounted)
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _update(Map<String, dynamic> item, String action) async {
    final contractId = int.tryParse(
      (item['id'] ?? item['contract_id'] ?? '').toString(),
    );
    if (contractId == null) return;
    final actionLabel = action == 'received'
        ? 'mark as received'
        : 'mark ready for loading';
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: Text(
          'Confirm ${action == 'received' ? 'receipt' : 'dispatch readiness'}',
        ),
        content: Text('Do you want to $actionLabel for this consignment?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final response = await BuyerServices.updateConsignment(
        contractId,
        action: action,
      );
      AppSnackbar.showSuccess(
        title: 'Updated',
        message: response['message'] ?? 'Consignment updated successfully.',
      );
      _load();
    } catch (error) {
      AppSnackbar.showError(
        title: 'Update failed',
        message: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Consignment Management',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                hintText: 'Search contract, product, seller or route',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: _load,
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _workflows.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final value = _workflows[index];
                return ChoiceChip(
                  label: Text(_label(value)),
                  selected: _workflow == value,
                  onSelected: (_) {
                    setState(() => _workflow = value);
                    _load();
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error.isNotEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 80),
                        Center(child: Text(_error)),
                        TextButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    )
                  : _items.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 80),
                        Center(child: Text('No consignments found.')),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, index) => _card(theme, _items[index]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(ThemeData theme, Map<String, dynamic> item) {
    final title = item['product_title'] ?? item['title'] ?? 'Consignment';
    final contract = item['contract_id'] ?? item['id'] ?? '-';
    final status =
        item['received_label'] ??
        item['ready_label'] ??
        item['status'] ??
        'Pending';
    final route =
        '${item['loading_from'] ?? '-'} → ${item['loading_to'] ?? '-'}';
    final canReady = item['can_mark_ready'] == true;
    final canReceive = item['can_mark_received'] == true;
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title.toString(),
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
              ),
              _status(status.toString(), theme),
            ],
          ),
          const SizedBox(height: 5),
          Text('Contract: $contract', style: theme.textTheme.bodySmall),
          const SizedBox(height: 10),
          _line(Icons.route_outlined, route.toString()),
          _line(
            Icons.inventory_2_outlined,
            '${item['deal_quantity'] ?? '-'} ${item['quantity_unit'] ?? ''}',
          ),
          _line(
            Icons.currency_rupee_rounded,
            'Trade value: ₹${item['trade_value'] ?? '-'}',
          ),
          if ((item['assigned_transporter'] ?? '').toString().isNotEmpty)
            _line(
              Icons.local_shipping_outlined,
              'Transporter: ${item['assigned_transporter']}',
            ),
          if (canReady || canReceive) ...[
            const Divider(height: 22),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () => _update(
                  item,
                  canReceive ? 'received' : 'ready_for_loading',
                ),
                icon: Icon(
                  canReceive
                      ? Icons.check_circle_outline
                      : Icons.inventory_outlined,
                  size: 18,
                ),
                label: Text(canReceive ? 'Mark received' : 'Ready for loading'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _line(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Icon(icon, size: 15),
        const SizedBox(width: 7),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
      ],
    ),
  );

  Widget _status(String status, ThemeData theme) {
    final lower = status.toLowerCase();
    final color = lower.contains('received') || lower.contains('deliver')
        ? Colors.green
        : lower.contains('dispatch') || lower.contains('transit')
        ? Colors.blue
        : theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _label(String value) =>
      value == 'all' ? 'All' : value[0].toUpperCase() + value.substring(1);
}
