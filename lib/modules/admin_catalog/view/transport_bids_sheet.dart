import 'package:daalsetu/network/api_client.dart';
import 'package:flutter/material.dart';
import '../../../utils/app_snackbar.dart';

Future<bool> showTransportBidsSheet(
  BuildContext context,
  Map<String, dynamic> consignment,
) async {
  final contractId = int.tryParse('${consignment['id'] ?? ''}');
  if (contractId == null) {
    AppSnackbar.showSnackBar(context, 
      const SnackBar(content: Text('Invalid consignment selected.')),
    );
    return false;
  }
  return await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => TransportBidsSheet(
          contractId: contractId,
          contractNumber: '${consignment['contract_id'] ?? ''}',
        ),
      ) ??
      false;
}

class TransportBidsSheet extends StatefulWidget {
  const TransportBidsSheet({
    super.key,
    required this.contractId,
    required this.contractNumber,
  });

  final int contractId;
  final String contractNumber;

  /// TSK-036: Automatically elevate remaining active bids to top in contract section
  static List<Map<String, dynamic>> sortBids(List<Map<String, dynamic>> list) {
    final sorted = List<Map<String, dynamic>>.from(list);
    sorted.sort((a, b) {
      final statusA = '${a['status'] ?? 'pending'}'.toLowerCase();
      final statusB = '${b['status'] ?? 'pending'}'.toLowerCase();
      final isPendingA = statusA == 'pending' || statusA == 'active' || statusA == 'reserved';
      final isPendingB = statusB == 'pending' || statusB == 'active' || statusB == 'reserved';

      // 1. Prioritize active/pending bids over concluded/rejected ones
      if (isPendingA && !isPendingB) return -1;
      if (!isPendingA && isPendingB) return 1;

      // 2. Secondary sort: latest created_at first
      final dateA = DateTime.tryParse('${a['created_at'] ?? ''}');
      final dateB = DateTime.tryParse('${b['created_at'] ?? ''}');
      if (dateA != null && dateB != null) {
        return dateB.compareTo(dateA);
      }
      return 0;
    });
    return sorted;
  }

  @override
  State<TransportBidsSheet> createState() => _TransportBidsSheetState();
}

class _TransportBidsSheetState extends State<TransportBidsSheet> {
  bool loading = true;
  String? error;
  int? processingBidId;
  bool changed = false;
  Map<String, dynamic> contract = const {};
  List<Map<String, dynamic>> bids = const [];

  @override
  void initState() {
    super.initState();
    loadBids();
  }

  String _message(Object value) =>
      value.toString().replaceFirst('Exception: ', '');

  Future<void> loadBids() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final response = await ApiClient.get(
        endpoint: '/api/transport-bids/?contract_id=${widget.contractId}',
        requireAuth: true,
      );
      if (!mounted) return;
      final rawBids = response is Map ? response['bids'] : null;
      setState(() {
        contract = response is Map && response['contract'] is Map
            ? Map<String, dynamic>.from(response['contract'] as Map)
            : const {};
        final parsedList = (rawBids is List ? rawBids : const [])
            .whereType<Map>()
            .map(Map<String, dynamic>.from)
            .toList();
        bids = TransportBidsSheet.sortBids(parsedList);
      });
    } catch (exception) {
      if (!mounted) return;
      setState(() => error = _message(exception));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  /// Asks for an amount (+ optional note). Returns null when cancelled.
  Future<({String amount, String note})?> _askAmount(String title, {String initial = '', bool withNote = false}) async {
    final amount = TextEditingController(text: initial);
    final note = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(prefixText: '₹ ', labelText: 'Amount', border: OutlineInputBorder()),
            ),
            if (withNote) ...[
              const SizedBox(height: 10),
              TextField(
                controller: note,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Note (optional)', border: OutlineInputBorder()),
              ),
            ],
          ],
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Save')),
          OutlinedButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
        ],
      ),
    );
    if (result != true) return null;
    final value = double.tryParse(amount.text.trim());
    if (value == null || value <= 0) {
      if (mounted) {
        AppSnackbar.showSnackBar(context, const SnackBar(content: Text('Enter an amount greater than 0.')));
      }
      return null;
    }
    return (amount: amount.text.trim(), note: note.text.trim());
  }

  Future<void> _post(String endpoint, Map<String, dynamic> body, {int? bidId}) async {
    setState(() => processingBidId = bidId ?? -1);
    try {
      final response = await ApiClient.post(endpoint: endpoint, body: body, requireAuth: true);
      if (!mounted) return;
      changed = true;
      AppSnackbar.showSnackBar(context, SnackBar(content: Text((response['message'] ?? 'Saved.').toString())));
      await loadBids();
    } catch (exception) {
      if (!mounted) return;
      AppSnackbar.showSnackBar(context, SnackBar(
        content: Text(_message(exception)),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    } finally {
      if (mounted) setState(() => processingBidId = null);
    }
  }

  /// Admin price transporters accept or negotiate (MoM 16).
  Future<void> setMaxBid({bool clear = false}) async {
    String value = '';
    if (!clear) {
      final input = await _askAmount('Set max bid (admin price)', initial: '${contract['max_bid'] ?? ''}');
      if (input == null) return;
      value = input.amount;
    }
    await _post('/api/contracts/${widget.contractId}/transport-max-bid/', {'max_bid': value});
  }

  Future<void> counterBid(Map<String, dynamic> bid) async {
    final bidId = int.tryParse('${bid['bid_id'] ?? ''}');
    if (bidId == null) return;
    final input = await _askAmount('Counter offer',
        initial: '${bid['admin_counter_amount'] ?? bid['bid_amount'] ?? ''}', withNote: true);
    if (input == null) return;
    await _post('/api/transport-bids/$bidId/',
        {'action': 'counter', 'counter_amount': input.amount, 'note': input.note}, bidId: bidId);
  }

  Widget _maxBidBar() {
    final maxBid = contract['max_bid'];
    final canSet = contract['can_set_max_bid'] == true;
    if (maxBid == null && !canSet) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2C394F) : const Color(0xFFFFE0B2),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF57C00).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.price_change_outlined, size: 18, color: Color(0xFFE65100)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              maxBid == null
                  ? 'No admin price: transporters bid freely.'
                  : 'Admin price: ₹$maxBid (accept or negotiate)',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          if (canSet) ...[
            TextButton(
              onPressed: processingBidId != null ? null : setMaxBid,
              child: Text(maxBid == null ? 'Set Price' : 'Change',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
            ),
            if (maxBid != null)
              TextButton(
                onPressed: processingBidId != null ? null : () => setMaxBid(clear: true),
                child: const Text('Open Bidding'),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> runAction(Map<String, dynamic> bid, String action) async {
    final bidId = int.tryParse('${bid['bid_id'] ?? ''}');
    if (bidId == null) return;
    final isAccept = action == 'accept';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          isAccept ? 'Accept transport bid?' : 'Reject transport bid?',
        ),
        content: Text(
          isAccept
              ? 'All other pending bids for this contract will be rejected.'
              : 'The transporter will be notified that this bid was rejected.',
        ),
        actions: [
          FilledButton(
            style: isAccept
                ? null
                : FilledButton.styleFrom(
                    backgroundColor: Theme.of(dialogContext).colorScheme.error,
                  ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(isAccept ? 'Accept' : 'Reject'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => processingBidId = bidId);
    try {
      final response = await ApiClient.post(
        endpoint: '/api/transport-bids/$bidId/',
        body: {'action': action},
        requireAuth: true,
      );
      if (!mounted) return;
      changed = true;
      AppSnackbar.showSnackBar(context, 
        SnackBar(
          content: Text((response['message'] ?? 'Bid updated.').toString()),
        ),
      );
      await loadBids();
    } catch (exception) {
      if (!mounted) return;
      AppSnackbar.showSnackBar(context, 
        SnackBar(
          content: Text(_message(exception)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => processingBidId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = contract['contract_id']?.toString().isNotEmpty == true
        ? contract['contract_id'].toString()
        : widget.contractNumber.isNotEmpty
        ? widget.contractNumber
        : 'Contract';
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .82,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 12, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE65100), Color(0xFFF57C00)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.local_shipping_outlined, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transport Bids',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$title${contract['product_title'] == null ? '' : ' • ${contract['product_title']}'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context, changed),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (!loading && error == null) _maxBidBar(),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 44),
              const SizedBox(height: 12),
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: loadBids,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }
    if (bids.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Text(
            'No transport bids yet. Mark the consignment ready to receive bids.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: loadBids,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: bids.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, index) => _bidCard(bids[index]),
      ),
    );
  }

  Widget _bidCard(Map<String, dynamic> bid) {
    final bidId = int.tryParse('${bid['bid_id'] ?? ''}');
    final status = '${bid['status'] ?? 'pending'}';
    final isPending = status.toLowerCase() == 'pending' || status.toLowerCase() == 'reserved';
    final canAccept = bid['can_accept'] == true || (bid['can_accept'] == null && isPending);
    final canReject = bid['can_reject'] == true || (bid['can_reject'] == null && isPending);
    final canCounter = bid['can_counter'] == true;
    final isProcessing = processingBidId == bidId;
    final company = '${bid['transporter_company'] ?? ''}'.trim();
    final person = '${bid['transporter_name'] ?? ''}'.trim();
    final mobile = '${bid['mobile'] ?? ''}'.trim();
    final bidType = '${bid['bid_type'] ?? 'bid'}';
    final history = (bid['negotiation_history'] is List ? bid['negotiation_history'] as List : const [])
        .whereType<Map>()
        .toList();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2C394F) : const Color(0xFFFFE0B2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.local_shipping_rounded, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company.isNotEmpty ? company : '${bid['transporter_unique_id'] ?? 'Transporter'}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      if (person.isNotEmpty || mobile.isNotEmpty)
                        Text(
                          [person, mobile].where((part) => part.isNotEmpty).join(' • '),
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                    ],
                  ),
                ),
                _status(status),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'Bid amount: ',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    Text(
                      '₹${bid['bid_amount'] ?? '—'}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFE65100),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${bid['bid_date'] ?? ''}',
                  style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color),
                ),
              ],
            ),

            if (bidType != 'bid' && '${bid['bid_type_label'] ?? ''}'.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (bidType == 'negotiation' ? Colors.orange : Colors.blue).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: (bidType == 'negotiation' ? Colors.orange : Colors.blue).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${bid['bid_type_label']}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: bidType == 'negotiation' ? Colors.orange.shade800 : Colors.blue.shade800,
                  ),
                ),
              ),
            ],

            if ('${bid['transporter_note'] ?? ''}'.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Note: ${bid['transporter_note']}',
                style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
              ),
            ],

            if (bid['admin_counter_amount'] != null) ...[
              const SizedBox(height: 6),
              Text(
                'Your counter: ₹${bid['admin_counter_amount']} (awaiting transporter)',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],

            if (history.length > 1)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text('Negotiation history (${history.length})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                children: history
                    .map((step) => Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              '${step['at'] ?? ''} • ${step['by'] == 'admin' ? 'Admin' : 'Transporter'}: '
                              '${'${step['action'] ?? ''}'.replaceAll('_', ' ')} '
                              '${'${step['amount'] ?? ''}'.isEmpty ? '' : '₹${step['amount']}'}'
                              '${'${step['note'] ?? ''}'.isEmpty ? '' : ' – ${step['note']}'}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ))
                    .toList(),
              ),

            if (canAccept || canReject || canCounter) ...[
              const SizedBox(height: 12),
              if (isProcessing)
                const SizedBox(
                  height: 36,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                // One horizontal row: the buttons share the width equally and never wrap.
                Row(
                  children: [
                    if (canAccept)
                      Expanded(child: FilledButton.icon(
                        onPressed: () => runAction(bid, 'accept'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const FittedBox(fit: BoxFit.scaleDown, child: Text('Accept', style: TextStyle(fontWeight: FontWeight.bold))),
                      )),
                    if (canAccept && (canCounter || canReject)) const SizedBox(width: 8),
                    if (canCounter)
                      Expanded(child: OutlinedButton.icon(
                        onPressed: () => counterBid(bid),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                        label: const FittedBox(fit: BoxFit.scaleDown, child: Text('Counter')),
                      )),
                    if (canCounter && canReject) const SizedBox(width: 8),
                    if (canReject)
                      Expanded(child: OutlinedButton.icon(
                        onPressed: () => runAction(bid, 'reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFD32F2F),
                          side: const BorderSide(color: Color(0xFFD32F2F)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: const FittedBox(fit: BoxFit.scaleDown, child: Text('Reject', style: TextStyle(fontWeight: FontWeight.bold))),
                      )),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _status(String value) {
    final (Color color, Color bg) = switch (value.toLowerCase()) {
      'accepted' => (const Color(0xFF2E7D32), const Color(0xFFE8F5E9)),
      'rejected' => (const Color(0xFFD32F2F), const Color(0xFFFFEBEE)),
      _ => (const Color(0xFFF57C00), const Color(0xFFFFF3E0)),
    };
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: 0.15) : bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        value.replaceFirst(
          value.isEmpty ? '' : value[0],
          value.isEmpty ? '' : value[0].toUpperCase(),
        ),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }
}
