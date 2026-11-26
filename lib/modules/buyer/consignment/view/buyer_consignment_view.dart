import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../services/buyer_services.dart';
import '../../../../theme/glass_widgets.dart';
import '../../../../utils/app_snackbar.dart';
import 'package:daalsetu/widgets/app_shell.dart';
import 'package:daalsetu/widgets/hero_header.dart';

/// The one stage a consignment is in: Received > Dispatch > Ready > Pending. (`received_label`
/// is never empty - it says "Pending" until delivery - so reading it first hid every Ready and
/// Dispatched shipment behind "Pending".)
@visibleForTesting
String consignmentStageLabel(Map<String, dynamic> item) {
  final status = (item['status'] ?? '').toString().toLowerCase();
  if (item['is_delivered'] == true || status == 'received' || status == 'completed') {
    return 'Consignment Received';
  }
  if (item['is_dispatched'] == true || status == 'dispatched' || status == 'in_transit') {
    return 'Dispatch';
  }
  final visibleAt = item['transporter_visible_at']?.toString().trim();
  if (visibleAt != null && visibleAt.isNotEmpty && visibleAt != 'null') {
    return 'Consignment Ready';
  }
  final workflow = (item['workflow_status'] ?? item['workflow_stage'] ?? '').toString().toLowerCase();
  if (workflow == 'ready' || workflow == 'consignment_ready') {
    return 'Consignment Ready';
  }
  if (workflow == 'dispatch' || workflow == 'dispatched') {
    return 'Dispatch';
  }
  if (workflow == 'received') {
    return 'Consignment Received';
  }
  return 'Pending';
}

class BuyerConsignmentView extends StatefulWidget {
  const BuyerConsignmentView({super.key});

  @override
  State<BuyerConsignmentView> createState() => _BuyerConsignmentViewState();
}

class _BuyerConsignmentViewState extends State<BuyerConsignmentView> {
  final _searchController = TextEditingController();
  final _allConsignments = <Map<String, dynamic>>[];
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

  static const _stageOfFilter = <String, String>{
    'pending': 'Pending',
    'ready': 'Consignment Ready',
    'dispatch': 'Dispatch',
    'received': 'Consignment Received',
  };

  static const _workflowLabels = <String, String>{
    'all': 'All Status',
    'pending': 'Pending',
    'ready': 'Consignment Ready',
    'dispatch': 'Dispatch',
    'received': 'Consignment Received',
  };

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

  void _applyFilter() {
    final stage = _stageOfFilter[_workflow];
    final query = _searchController.text.trim().toLowerCase();
    var list = _allConsignments.toList();
    if (stage != null) {
      list = list.where((item) => consignmentStageLabel(item) == stage).toList();
    }
    if (query.isNotEmpty) {
      list = list.where((item) {
        final contractId = (item['contract_id'] ?? '').toString().toLowerCase();
        final productTitle = (item['product_title'] ?? '').toString().toLowerCase();
        final sellerName = (item['seller_name'] ?? '').toString().toLowerCase();
        final from = (item['loading_from'] ?? '').toString().toLowerCase();
        final to = (item['loading_to'] ?? '').toString().toLowerCase();
        return contractId.contains(query) ||
            productTitle.contains(query) ||
            sellerName.contains(query) ||
            from.contains(query) ||
            to.contains(query);
      }).toList();
    }
    setState(() {
      _items
        ..clear()
        ..addAll(list);
    });
  }

  /// Only the latest request may fill the list (an older, slower answer must not overwrite it).
  int _requestId = 0;

  Future<void> _load({bool silent = false}) async {
    final requestId = ++_requestId;
    if (!silent) {
      setState(() {
        _loading = true;
        _error = '';
      });
    }
    try {
      final response = await BuyerServices.getConsignments(
        workflowStatus: _workflow,
        search: _searchController.text,
      );
      final raw = response['results'];
      if (mounted && requestId == _requestId) {
        final list = (raw is List
                ? raw.whereType<Map>().map(
                    (item) => Map<String, dynamic>.from(item),
                  )
                : const <Map<String, dynamic>>[])
            .toList();
        _allConsignments
          ..clear()
          ..addAll(list);
        _applyFilter();
      }
    } catch (error) {
      if (mounted && requestId == _requestId && !silent) {
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted && requestId == _requestId && !silent) {
        setState(() => _loading = false);
      }
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
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Confirm'),
          ),
          OutlinedButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
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
      appBar: HeroHeader(
        leading: AppBarLeading(
          child: Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  onPressed: () => Get.back(),
                )
              : null,
        ),
        title: "Consignments",
        subtitle: "Stock consignments & delivery receipts",
        trailing: IconButton(
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
          tooltip: 'Refresh',
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _applyFilter(),
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
                    if (_workflow != value) {
                      setState(() => _workflow = value);
                      _applyFilter();
                      _load(silent: true);
                    }
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
    final contract = item['contract_id'] ?? '-';
    final status = consignmentStageLabel(item);
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
            'Trade value: ${_formatTradeValue(item['trade_value'])}',
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

  String _formatTradeValue(dynamic raw) {
    if (raw == null) return '-';
    final s = raw.toString().replaceAll('₹', '').trim();
    if (s.isEmpty || s == '-') return '-';
    final numVal = double.tryParse(s);
    if (numVal == null) return '₹$s';

    final isNegative = numVal < 0;
    final absVal = numVal.abs();
    final parts = absVal.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];

    // Indian numbering format (e.g., 1,95,000.00)
    String formattedInt = '';
    if (integerPart.length <= 3) {
      formattedInt = integerPart;
    } else {
      final lastThree = integerPart.substring(integerPart.length - 3);
      final remaining = integerPart.substring(0, integerPart.length - 3);
      final chunks = <String>[];
      for (int i = remaining.length; i > 0; i -= 2) {
        final start = (i - 2 < 0) ? 0 : i - 2;
        chunks.insert(0, remaining.substring(start, i));
      }
      formattedInt = "${chunks.join(',')},$lastThree";
    }

    return '₹${isNegative ? '-' : ''}$formattedInt.$decimalPart';
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
    String displayStatus = status.trim();
    final lower = displayStatus.toLowerCase();
    if (lower == 'received' || lower == 'consignment received' || lower.contains('received')) {
      displayStatus = 'Consignment Received';
    } else if (lower == 'ready' || lower == 'consignment ready') {
      displayStatus = 'Consignment Ready';
    } else if (lower == 'dispatch' || lower == 'dispatched') {
      displayStatus = 'Dispatch';
    } else if (lower == 'pending') {
      displayStatus = 'Pending';
    }

    final color = displayStatus == 'Consignment Received'
        ? Colors.green
        : displayStatus == 'Dispatch'
        ? Colors.blue
        : (displayStatus == 'Consignment Ready'
            ? const Color(0xFF2563EB)
            : theme.colorScheme.primary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        displayStatus,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _label(String value) => _workflowLabels[value] ?? value;
}
