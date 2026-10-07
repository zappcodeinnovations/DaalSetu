import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import '../../../theme/app_theme.dart';
import '../../admin_catalog/view/admin_drawer.dart';
import '../controller/contract_controller.dart';
import '../model/contract_model.dart';
import './contract_details_view.dart';

class ContractsScreen extends StatefulWidget {
  const ContractsScreen({super.key});

  @override
  State<ContractsScreen> createState() => _ContractsScreenState();
}

class _ContractsScreenState extends State<ContractsScreen> {
  final ContractController controller = Get.put(ContractController());
  final TextEditingController searchController = TextEditingController();
  final selectedFilter = 'All'.obs;
  final selectedContracts = <int>{}.obs;
  final isSelectionMode = false.obs;
  final filters = const ['All', 'Active', 'Pending', 'Completed', 'Cancelled'];

  List<ContractModel> get filteredContracts {
    var contracts = controller.contracts.toList();
    if (selectedFilter.value != 'All') {
      contracts = contracts
          .where(
            (item) =>
                item.status.toLowerCase() == selectedFilter.value.toLowerCase(),
          )
          .toList();
    }
    final query = searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      contracts = contracts.where((item) {
        return item.productTitle.toLowerCase().contains(query) ||
            item.productCategory.toLowerCase().contains(query) ||
            item.contractId.toLowerCase().contains(query) ||
            item.displayBuyerId.toLowerCase().contains(query) ||
            item.displaySellerId.toLowerCase().contains(query);
      }).toList();
    }
    return contracts;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isSelectionMode.value,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && isSelectionMode.value) {
          isSelectionMode.value = false;
          selectedContracts.clear();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        drawer: Navigator.canPop(context)
            ? null
            : const AdminDrawer(activeKey: 'buyer_offers'),
        appBar: AppBar(
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  onPressed: () => Get.back(),
                )
              : null,
          title: Obx(
            () => Text(
              isSelectionMode.value
                  ? '${selectedContracts.length} selected'
                  : 'Contracts / Deals Management',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          actions: [
            Obx(() {
              if (!isSelectionMode.value) {
                return IconButton(
                  tooltip: 'Refresh',
                  onPressed: controller.fetchContracts,
                  icon: const Icon(Icons.refresh_rounded),
                );
              }
              return Row(
                children: [
                  IconButton(
                    tooltip: 'Select all',
                    onPressed: () {
                      if (selectedContracts.length ==
                          controller.contracts.length) {
                        selectedContracts.clear();
                      } else {
                        selectedContracts
                          ..clear()
                          ..addAll(controller.contracts.map((item) => item.id));
                      }
                    },
                    icon: const Icon(Icons.select_all_rounded),
                  ),
                  IconButton(
                    tooltip: 'Delete selected',
                    onPressed: _deleteSelected,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              );
            }),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: TextField(
                controller: searchController,
                onChanged: (_) => selectedFilter.refresh(),
                decoration: InputDecoration(
                  hintText: 'Search ID, product, seller or buyer',
                  prefixIcon: const Icon(IconlyLight.search),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final filter = filters[index];
                  return Obx(
                    () => ChoiceChip(
                      label: Text(filter),
                      selected: selectedFilter.value == filter,
                      onSelected: (_) => selectedFilter.value = filter,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.contracts.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                final contracts = filteredContracts;
                return contracts.isEmpty
                    ? _emptyState()
                    : RefreshIndicator(
                        onRefresh: controller.fetchContracts,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                          itemCount: contracts.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, index) => _contractCard(contracts[index]),
                        ),
                      );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contractCard(ContractModel contract) {
    final theme = Theme.of(context);
    return Obx(() {
      final selected = selectedContracts.contains(contract.id);
      return InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          if (isSelectionMode.value) {
            _toggleSelection(contract.id);
          } else {
            Get.to(() => const ContractDetailScreen(), arguments: contract.id);
          }
        },
        onLongPress: () {
          isSelectionMode.value = true;
          selectedContracts.add(contract.id);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: .12)
                : theme.cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.dividerColor.withValues(alpha: .25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isSelectionMode.value) ...[
                    Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 9),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _text(contract.productTitle),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _text(contract.productCategory),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _statusBadge(contract.status),
                ],
              ),
              const SizedBox(height: 12),
              _infoLine(
                Icons.tag_rounded,
                'Contract ID',
                _text(contract.contractId),
              ),
              const Divider(height: 22),
              _party(
                Icons.person_outline_rounded,
                'Seller',
                contract.displaySellerId,
                contract.sellerName,
              ),
              const SizedBox(height: 10),
              _party(
                Icons.business_center_outlined,
                'Buyer',
                contract.displayBuyerId,
                contract.buyerName,
              ),
              const Divider(height: 22),
              Wrap(
                spacing: 20,
                runSpacing: 10,
                children: [
                  _metric(
                    'Deal amount',
                    '₹ ${_text(contract.dealAmount)}'
                        '${contract.amountUnit.isEmpty ? '' : ' ${contract.amountUnit}'}',
                    theme.colorScheme.primary,
                  ),
                  _metric(
                    'Quantity',
                    '${_text(contract.dealQuantity)}'
                        '${contract.quantityUnit.isEmpty ? '' : ' ${contract.quantityUnit}'}',
                    theme.colorScheme.secondary,
                  ),
                ],
              ),
              const Divider(height: 22),
              _infoLine(
                Icons.trip_origin_rounded,
                'Loading from',
                _text(contract.loadingFrom),
              ),
              const SizedBox(height: 8),
              _infoLine(
                Icons.location_on_outlined,
                'Loading to',
                _text(contract.loadingTo),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Tap to view complete details  ›',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _party(IconData icon, String label, String id, String name) {
    final primary = _text(id);
    final secondary = name.trim().isEmpty || name.trim() == id.trim()
        ? ''
        : name.trim();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(
                primary,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (secondary.isNotEmpty)
                Text(secondary, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoLine(IconData icon, String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 8),
      SizedBox(
        width: 88,
        child: Text(label, style: Theme.of(context).textTheme.bodySmall),
      ),
      Expanded(
        child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    ],
  );

  Widget _metric(String label, String value, Color color) => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: 120),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );

  Widget _statusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _text(status).toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _emptyState() => ListView(
    children: const [
      SizedBox(height: 90),
      Icon(Icons.description_outlined, size: 60),
      SizedBox(height: 12),
      Text(
        'No contracts found',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
    ],
  );

  void _toggleSelection(int id) {
    if (selectedContracts.contains(id)) {
      selectedContracts.remove(id);
    } else {
      selectedContracts.add(id);
    }
    if (selectedContracts.isEmpty) isSelectionMode.value = false;
  }

  Future<void> _deleteSelected() async {
    final ids = selectedContracts.toList();
    for (final id in ids) {
      await controller.deleteContract(id);
    }
    selectedContracts.clear();
    isSelectionMode.value = false;
  }

  String _text(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? '—' : text;
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppTheme.successGreen;
      case 'pending':
        return AppTheme.secondaryOrange;
      case 'cancelled':
        return AppTheme.errorRed;
      case 'completed':
        return AppTheme.primaryGold;
      default:
        return AppTheme.textMuted;
    }
  }
}
