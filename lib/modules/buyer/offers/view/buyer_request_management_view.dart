import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../services/buyer_services.dart';
import '../../../../services/seller_services.dart';
import '../../../../theme/glass_widgets.dart';
import '../../../../utils/app_snackbar.dart';
import 'buyer_offer_details_view.dart';

enum BuyerRequestMode { requirements, offers }

/// Role-safe buyer workspaces matching the web panel's request filters.
/// The backend decides which records a buyer may see; this widget only exposes
/// the buyer's own tabs and server-side filters.
class BuyerRequestManagementView extends StatefulWidget {
  final BuyerRequestMode mode;

  const BuyerRequestManagementView({super.key, required this.mode});

  @override
  State<BuyerRequestManagementView> createState() =>
      _BuyerRequestManagementViewState();
}

class _BuyerRequestManagementViewState
    extends State<BuyerRequestManagementView> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _dateFormat = DateFormat('yyyy-MM-dd');

  final List<Map<String, dynamic>> _rows = [];
  final List<Map<String, dynamic>> _branches = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasNextPage = false;
  int _currentPage = 1;
  String _error = '';
  String _status = 'all';
  String _branch = 'all';
  DateTimeRange? _dateRange;

  bool get _isRequirement => widget.mode == BuyerRequestMode.requirements;

  List<String> get _statuses => _isRequirement
      ? const [
          'all',
          'open',
          'negotiation_in_progress',
          'fulfilled',
          'closed',
          'expired',
        ]
      : const [
          'all',
          'requested',
          'negotiating',
          'seller_confirmed',
          'buyer_confirmed',
          'deal_confirmed',
          'rejected',
          'cancelled',
        ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadNextPageWhenNeeded);
    _load();
    _loadBranches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadNextPageWhenNeeded() {
    if (!_isRequirement ||
        _loading ||
        _loadingMore ||
        !_hasNextPage ||
        !_scrollController.hasClients) {
      return;
    }
    if (_scrollController.position.extentAfter < 280) {
      _load(reset: false);
    }
  }

  Future<void> _loadBranches() async {
    try {
      final response = await SellerServices.getBranches();
      final data = response['data'];
      final candidates = <dynamic>[
        if (data is Map) ...?(data['my_branches'] as List?),
        if (data is Map && data['primary_branch'] is Map)
          data['primary_branch'],
      ];
      final seen = <String>{};
      final mapped = <Map<String, dynamic>>[];
      for (final item in candidates) {
        if (item is! Map) continue;
        final row = Map<String, dynamic>.from(item);
        final id = row['id']?.toString();
        if (id != null && seen.add(id)) mapped.add(row);
      }
      if (mounted) setState(() => _branches.addAll(mapped));
    } catch (_) {
      // Branch filtering remains optional if the account has no branch API access.
    }
  }

  Future<void> _load({bool reset = true}) async {
    if (!reset && (!_isRequirement || _loadingMore || !_hasNextPage)) return;
    final requestedPage = reset ? 1 : _currentPage + 1;
    setState(() {
      if (reset) {
        _loading = true;
        _error = '';
        _currentPage = 1;
        _hasNextPage = false;
      } else {
        _loadingMore = true;
      }
    });
    try {
      final response = _isRequirement
          ? await BuyerServices.getBuyerRequirements(
              tab: 'my',
              status: _status,
              search: _searchController.text,
              page: requestedPage,
            )
          : await BuyerServices.getBuyerOfferRequests(
              tab: 'my',
              status: _status,
              search: _searchController.text,
              branch: _branch,
              dateFrom: _dateRange == null
                  ? ''
                  : _dateFormat.format(_dateRange!.start),
              dateTo: _dateRange == null
                  ? ''
                  : _dateFormat.format(_dateRange!.end),
            );
      final raw = _isRequirement
          ? response['results']
          : response['buyer_offers'];
      final items = raw is List
          ? raw
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : <Map<String, dynamic>>[];
      final pagination = response['pagination'];
      final hasNext =
          _isRequirement && pagination is Map && pagination['has_next'] == true;
      if (mounted) {
        setState(() {
          if (reset) _rows.clear();
          final knownIds = _rows
              .map((row) => (row['id'] ?? row['rfq_id']).toString())
              .toSet();
          for (final item in items) {
            final itemId = (item['id'] ?? item['rfq_id']).toString();
            if (knownIds.add(itemId)) _rows.add(item);
          }
          _currentPage = requestedPage;
          _hasNextPage = hasNext;
        });
      }
    } catch (error) {
      if (mounted) {
        if (reset) {
          setState(
            () => _error = error.toString().replaceFirst('Exception: ', ''),
          );
        } else {
          AppSnackbar.showError(
            title: 'Could not load more requirements',
            message: error.toString().replaceFirst('Exception: ', ''),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _dateRange,
    );
    if (result != null && mounted) setState(() => _dateRange = result);
  }

  void _showFilters() {
    var selectedStatus = _status;
    var selectedBranch = _branch;
    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter ${_isRequirement ? 'requirements' : 'buyer offers'}',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: _statuses
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(_label(value)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setSheetState(() => selectedStatus = value ?? 'all'),
                ),
                if (!_isRequirement && _branches.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedBranch,
                    decoration: const InputDecoration(
                      labelText: 'Target branch',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: 'all',
                        child: Text('All branches'),
                      ),
                      ..._branches.map((branch) {
                        final id = branch['id']?.toString() ?? '';
                        final name =
                            branch['location_name'] ??
                            branch['branch_name'] ??
                            branch['city'] ??
                            'Branch $id';
                        return DropdownMenuItem(
                          value: id,
                          child: Text(name.toString()),
                        );
                      }),
                    ],
                    onChanged: (value) =>
                        setSheetState(() => selectedBranch = value ?? 'all'),
                  ),
                ],
                if (!_isRequirement) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _pickDateRange,
                    icon: const Icon(Icons.date_range_outlined),
                    label: Text(
                      _dateRange == null
                          ? 'Filter by date range'
                          : '${DateFormat('dd MMM').format(_dateRange!.start)} – ${DateFormat('dd MMM').format(_dateRange!.end)}',
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _status = 'all';
                          _branch = 'all';
                          _dateRange = null;
                        });
                        Get.back();
                        _load();
                      },
                      child: const Text('Reset'),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _status = selectedStatus;
                          _branch = selectedBranch;
                        });
                        Get.back();
                        _load();
                      },
                      child: const Text('Apply filters'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _cancelBuyerOffer(Map<String, dynamic> item) async {
    final id = int.tryParse((item['id'] ?? '').toString());
    if (id == null) return;
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Cancel buyer offer?'),
        content: const Text(
          'This request will no longer be available for negotiation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Get.back(result: true),
            child: const Text('Cancel offer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final response = await BuyerServices.buyerOfferAction(id, {
        'action': 'buyer_cancel',
      });
      AppSnackbar.showSuccess(
        title: 'Cancelled',
        message: response['message'] ?? 'Buyer offer cancelled.',
      );
      _load();
    } catch (error) {
      AppSnackbar.showError(
        title: 'Could not cancel offer',
        message: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _showHistory(Map<String, dynamic> item) async {
    Map<String, dynamic> source = item;
    try {
      if (_isRequirement) {
        final reference = item['rfq_id'] ?? item['id'];
        if (reference != null) {
          source = await BuyerServices.getBuyerRequirementDetails(reference);
        }
      } else {
        final id = int.tryParse((item['id'] ?? '').toString());
        if (id != null) source = await BuyerServices.getBuyerOfferDetails(id);
      }
    } catch (error) {
      AppSnackbar.showError(
        title: 'Could not load history',
        message: error.toString().replaceFirst('Exception: ', ''),
      );
      return;
    }
    final raw =
        source['negotiation_history_rows'] ??
        source['negotiations'] ??
        source['history'] ??
        source['responses'] ??
        const [];
    final history = raw is List
        ? raw.whereType<Map>().toList()
        : <Map>[];
    if (history.isEmpty && source['quotations'] is List) {
      for (final quotation in source['quotations'] as List) {
        if (quotation is! Map) continue;
        final quote = Map<String, dynamic>.from(quotation);
        final messages = quote['messages'];
        if (messages is List) {
          for (final message in messages.whereType<Map>()) {
            history.add(Map<String, dynamic>.from(message));
          }
        }
      }
    }
    Get.bottomSheet(
      SafeArea(
        child: Container(
          constraints: BoxConstraints(maxHeight: Get.height * .72),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: Get.theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Negotiation history',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: history.isEmpty
                    ? const Center(child: Text('No negotiation history yet.'))
                    : ListView.separated(
                        itemCount: history.length,
                        separatorBuilder: (_, __) => const Divider(height: 18),
                        itemBuilder: (_, index) {
                          final row = history[index];
                          final actor =
                              row['actor'] ??
                              row['sender_role'] ??
                              row['role'] ??
                              'Update';
                          final note =
                              row['remark'] ??
                              row['message'] ??
                              row['note'] ??
                              '';
                          final price =
                              row['offered_amount'] ??
                              row['counter_price'] ??
                              row['price'];
                          final qty =
                              row['offered_quantity'] ??
                              row['counter_quantity'] ??
                              row['quantity'];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              actor.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              [
                                if (price != null) '₹$price',
                                if (qty != null) 'Qty $qty',
                                if (note.toString().trim().isNotEmpty)
                                  note.toString(),
                              ].join(' • '),
                            ),
                            trailing: Text(
                              _formatDate(
                                row['created_at'] ?? row['updated_at'],
                              ),
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _closeBuyerRequirement(Map<String, dynamic> item) async {
    final reference = item['rfq_id'] ?? item['id'];
    if (reference == null) return;
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Close requirement?'),
        content: const Text(
          'Sellers will no longer be able to submit or negotiate quotations.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Keep open'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Get.back(result: true),
            child: const Text('Close requirement'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final response = await BuyerServices.closeBuyerRequirement(reference);
      AppSnackbar.showSuccess(
        title: 'Requirement closed',
        message: response['message'] ?? 'Buyer requirement closed.',
      );
      _load();
    } catch (error) {
      AppSnackbar.showError(
        title: 'Could not close requirement',
        message: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heading = _isRequirement ? 'My Requirements' : 'Buyer Offers';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _load(),
                  decoration: InputDecoration(
                    hintText: 'Search $heading',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _load();
                            },
                            icon: const Icon(Icons.clear),
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Filters',
                onPressed: _showFilters,
                icon: Badge(
                  isLabelVisible:
                      _status != 'all' ||
                      _branch != 'all' ||
                      _dateRange != null,
                  child: const Icon(Icons.tune_rounded),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 38,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _statuses.length,
            separatorBuilder: (_, __) => const SizedBox(width: 7),
            itemBuilder: (_, index) {
              final status = _statuses[index];
              return ChoiceChip(
                label: Text(_label(status)),
                selected: _status == status,
                onSelected: (_) {
                  setState(() => _status = status);
                  _load();
                },
              );
            },
          ),
        ),
        const SizedBox(height: 6),
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
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  )
                : _rows.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 80),
                      Center(
                        child: Text(
                          'No ${_isRequirement ? 'requirements' : 'buyer offers'} found.',
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 104),
                    itemCount:
                        _rows.length + (_isRequirement && _loadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      if (index == _rows.length) {
                        return const Padding(
                          padding: EdgeInsets.all(12),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return _card(context, _rows[index], theme);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _card(
    BuildContext context,
    Map<String, dynamic> item,
    ThemeData theme,
  ) {
    final id = item['id'] ?? item['rfq_id'] ?? item['transaction_id'] ?? '-';
    final title =
        item['title'] ??
        item['product_title'] ??
        item['commodity'] ??
        'Untitled request';
    final status = item['status']?.toString() ?? 'pending';
    final category = item['category_name'] ?? item['category'] ?? '';
    final seller = item['seller_name'] ?? item['seller'] ?? '';
    final qty =
        item['required_quantity'] ??
        item['requested_quantity'] ??
        item['quantity'] ??
        '-';
    final unit = item['quantity_unit'] ?? item['unit'] ?? 'QTL';
    final price =
        item['target_price'] ?? item['requested_amount'] ?? item['amount'];
    final numericId = int.tryParse((item['id'] ?? '').toString());
    final quoteCount =
        item['quotation_count'] ??
        (item['quotations'] is List
            ? (item['quotations'] as List).length
            : null);
    final actionPermissions = item['actions'] is Map
        ? Map<String, dynamic>.from(item['actions'] as Map)
        : const <String, dynamic>{};
    final canCancel =
        !_isRequirement && actionPermissions['can_buyer_cancel'] == true;
    final canClose =
        _isRequirement && actionPermissions['can_close'] == true;

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
              _statusBadge(status, theme),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${_isRequirement ? 'RFQ' : 'Request'}: $id',
            style: theme.textTheme.bodySmall,
          ),
          if (category.toString().isNotEmpty ||
              seller.toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              [
                if (category.toString().isNotEmpty) category.toString(),
                if (seller.toString().isNotEmpty) 'Seller: $seller',
              ].join(' • '),
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 5,
            children: [
              Text('Qty: $qty $unit', style: theme.textTheme.bodySmall),
              if (price != null)
                Text(
                  '₹$price / ${item['price_unit'] ?? unit}',
                  style: theme.textTheme.bodySmall,
                ),
              if (quoteCount != null)
                Text(
                  '$quoteCount quotation(s)',
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
          const Divider(height: 22),
          Row(
            children: [
              TextButton.icon(
                onPressed: numericId == null
                    ? null
                    : () => Get.to(
                        () => BuyerOfferDetailsView(
                          offerId: numericId,
                          preferBuyerOffer: !_isRequirement,
                          preferBuyerRequirement: _isRequirement,
                        ),
                      ),
                icon: const Icon(Icons.visibility_outlined, size: 17),
                label: const Text('Details'),
              ),
              TextButton.icon(
                onPressed: () => _showHistory(item),
                icon: const Icon(Icons.history_rounded, size: 17),
                label: const Text('History'),
              ),
              const Spacer(),
              if (canCancel)
                TextButton(
                  onPressed: () => _cancelBuyerOffer(item),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Cancel'),
                ),
              if (canClose)
                TextButton(
                  onPressed: () => _closeBuyerRequirement(item),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Close'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status, ThemeData theme) {
    final normalized = status.toLowerCase();
    final color = normalized.contains('reject') || normalized.contains('cancel')
        ? Colors.red
        : normalized.contains('confirm') ||
              normalized.contains('fulfill') ||
              normalized.contains('deal')
        ? Colors.green
        : normalized.contains('negotiat')
        ? Colors.orange
        : theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _label(status),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  String _label(String value) => value
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');

  String _formatDate(dynamic value) {
    if (value == null || value.toString().isEmpty) return '';
    final parsed = DateTime.tryParse(value.toString());
    return parsed == null
        ? value.toString()
        : DateFormat('dd MMM, hh:mm a').format(parsed.toLocal());
  }
}
