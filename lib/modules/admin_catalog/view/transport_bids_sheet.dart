import 'package:daalsetu/network/api_client.dart';
import 'package:flutter/material.dart';

Future<bool> showTransportBidsSheet(
  BuildContext context,
  Map<String, dynamic> consignment,
) async {
  final contractId = int.tryParse('${consignment['id'] ?? ''}');
  if (contractId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
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
        bids = (rawBids is List ? rawBids : const [])
            .whereType<Map>()
            .map(Map<String, dynamic>.from)
            .toList();
      });
    } catch (exception) {
      if (!mounted) return;
      setState(() => error = _message(exception));
    } finally {
      if (mounted) setState(() => loading = false);
    }
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
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: isAccept
                ? null
                : FilledButton.styleFrom(
                    backgroundColor: Theme.of(dialogContext).colorScheme.error,
                  ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(isAccept ? 'Accept' : 'Reject'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((response['message'] ?? 'Bid updated.').toString()),
        ),
      );
      await loadBids();
    } catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
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
        : 'Contract #${widget.contractId}';
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
    final canAccept = bid['can_accept'] == true;
    final canReject = bid['can_reject'] == true;
    final isProcessing = processingBidId == bidId;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${bid['transporter_unique_id'] ?? 'Transporter'}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
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
            const SizedBox(height: 4),
            Text('Submitted: ${bid['bid_date'] ?? '—'}'),
            if (canAccept || canReject) ...[
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
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Accept'),
                      ),
                    if (canReject)
                      OutlinedButton.icon(
                        onPressed: () => runAction(bid, 'reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Reject'),
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
