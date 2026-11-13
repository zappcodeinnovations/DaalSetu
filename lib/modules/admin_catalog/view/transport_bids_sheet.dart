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
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Save')),
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
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.price_change_outlined),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                maxBid == null
                    ? 'No admin price: transporters bid freely.'
                    : 'Admin price: ₹$maxBid (accept or negotiate)',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (canSet) ...[
              TextButton(onPressed: processingBidId != null ? null : setMaxBid, child: Text(maxBid == null ? 'Set Price' : 'Change')),
              if (maxBid != null)
                TextButton(
                  onPressed: processingBidId != null ? null : () => setMaxBid(clear: true),
                  child: const Text('Open Bidding'),
                ),
            ],
          ],
        ),
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
          TextButton(
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
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
              child: Row(
                children: [
                  const Icon(Icons.gavel_outlined),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transport Bids',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '$title${contract['product_title'] == null ? '' : ' • ${contract['product_title']}'}',
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company.isNotEmpty ? company : '${bid['transporter_unique_id'] ?? 'Transporter'}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      if (person.isNotEmpty || mobile.isNotEmpty)
                        Text(
                          [person, mobile].where((part) => part.isNotEmpty).join(' • '),
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                    ],
                  ),
                ),
                _status(status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Bid amount: ₹${bid['bid_amount'] ?? '—'}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (bidType != 'bid' && '${bid['bid_type_label'] ?? ''}'.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Chip(
                  label: Text('${bid['bid_type_label']}'),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: bidType == 'negotiation' ? Colors.orange.shade50 : Colors.blue.shade50,
                ),
              ),
            if ('${bid['transporter_note'] ?? ''}'.isNotEmpty)
              Text('Note: ${bid['transporter_note']}', style: const TextStyle(fontStyle: FontStyle.italic)),
            if (bid['admin_counter_amount'] != null)
              Text('Your counter: ₹${bid['admin_counter_amount']} (awaiting transporter)',
                  style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Submitted: ${bid['bid_date'] ?? '—'}'),
            if (history.length > 1)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text('Negotiation history (${history.length})', style: const TextStyle(fontSize: 13)),
                children: history
                    .map((step) => Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${step['at'] ?? ''} • ${step['by'] == 'admin' ? 'Admin' : 'Transporter'}: '
                            '${'${step['action'] ?? ''}'.replaceAll('_', ' ')} '
                            '${'${step['amount'] ?? ''}'.isEmpty ? '' : '₹${step['amount']}'}'
                            '${'${step['note'] ?? ''}'.isEmpty ? '' : ' – ${step['note']}'}',
                            style: const TextStyle(fontSize: 12),
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
                Wrap(
                  spacing: 8,
                  children: [
                    if (canAccept)
                      FilledButton.icon(
                        onPressed: () => runAction(bid, 'accept'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    if (canCounter)
                      OutlinedButton.icon(
                        onPressed: () => counterBid(bid),
                        icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                        label: const Text('Counter'),
                      ),
                    if (canReject)
                      OutlinedButton.icon(
                        onPressed: () => runAction(bid, 'reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                          side: BorderSide(color: Theme.of(context).colorScheme.error),
                        ),
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _status(String value) {
    final color = switch (value.toLowerCase()) {
      'accepted' => Colors.green,
      'rejected' => Colors.red,
      _ => Colors.orange,
    };
    return Chip(
      label: Text(
        value.replaceFirst(
          value.isEmpty ? '' : value[0],
          value.isEmpty ? '' : value[0].toUpperCase(),
        ),
      ),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w700),
      side: BorderSide(color: color.withValues(alpha: .35)),
      backgroundColor: color.withValues(alpha: .10),
    );
  }
}
