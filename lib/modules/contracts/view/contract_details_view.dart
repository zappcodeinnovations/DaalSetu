import 'package:agro_broker/modules/contracts/model/contract_details_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:agro_broker/theme/app_theme.dart';

import '../controller/contract_controller.dart';

class ContractDetailScreen extends StatefulWidget {
  const ContractDetailScreen({super.key});

  @override
  State<ContractDetailScreen> createState() => _ContractDetailScreenState();
}

class _ContractDetailScreenState extends State<ContractDetailScreen> {
  final controller = Get.find<ContractController>();
  late final int contractId;

  @override
  void initState() {
    super.initState();
    contractId = Get.arguments as int;
    Future.microtask(() => controller.fetchContractDetail(contractId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contract details')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final contract = controller.contractDetail.value;
        if (contract == null || contract.id != contractId) {
          return const Center(child: Text('Contract details unavailable'));
        }
        return RefreshIndicator(
          onRefresh: () => controller.fetchContractDetail(contractId),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
            children: [
              _header(contract),
              _section('Product & deal', [
                _item('Product', contract.productTitle),
                _item('Category', contract.productCategory),
                _item('Product ID', contract.productId),
                _item('Interest ID', contract.interestId),
                _item(
                  'Deal amount',
                  '₹${contract.dealAmount} ${contract.amountUnit}',
                ),
                _item(
                  'Deal quantity',
                  '${contract.dealQuantity} ${contract.quantityUnit}',
                ),
                _item('Quantity (Qtl)', contract.quantityQtl),
                _item('Bag count', contract.bagCount),
                _item('Bags', contract.bags),
                _item('Packing weight', '${contract.packingWeightKg} kg'),
              ]),
              _section('Buyer', [
                _item('Buyer', contract.displayBuyerId),
                _item('Login/mobile', contract.buyerName),
                _item('Unique ID', contract.buyerUniqueId),
                _item('Database ID', contract.buyerId),
                _item('Remark', contract.buyerRemark),
              ]),
              _section('Seller', [
                _item('Seller', contract.displaySellerId),
                _item('Login/mobile', contract.sellerName),
                _item('Mapped ID', contract.sellerMappedId),
                _item('Database ID', contract.sellerId),
                _item('Remark', contract.sellerRemark),
              ]),
              _section('Loading & transporter', [
                _item('Loading from', contract.loadingFrom),
                _item('Loading to', contract.loadingTo),
                _item(
                  'Ready for loading at',
                  _date(contract.readyForLoadingAt),
                ),
                _item('Ready by user ID', contract.readyForLoadingById),
                _item(
                  'Transporter visible at',
                  _date(contract.transporterVisibleAt),
                ),
                _item(
                  'Visibility reason',
                  _label(contract.transporterVisibilityReason),
                ),
              ]),
              _section('Administration', [
                _item('Admin remark', contract.adminRemark),
                _item('Confirmed by admin ID', contract.confirmedByAdminId),
                _item('Confirmed branch ID', contract.confirmedBranchId),
                _item('Created by user ID', contract.createdByUserId),
                _item('Assigned sub-admin ID', contract.assignedSubAdminId),
              ]),
              _section('Timeline', [
                _item('Created', _date(contract.createdAt)),
                _item('Confirmed', _date(contract.confirmedAt)),
                _item('Updated', _date(contract.updatedAt)),
              ]),
            ],
          ),
        );
      }),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: _changeStatus,
          icon: const Icon(Icons.sync_alt_rounded),
          label: const Text('Change contract status'),
        ),
      ),
    );
  }

  Widget _header(ContractDetailModel contract) {
    final color = _statusColor(contract.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    contract.contractId,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    _label(contract.status),
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Internal ID: ${contract.id}'),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _item(String label, Object? rawValue) {
    final value = rawValue?.toString().trim() ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changeStatus() async {
    final contract = controller.contractDetail.value;
    if (contract == null) return;

    var status = contract.status.toLowerCase();
    const statuses = ['pending', 'active', 'completed', 'cancelled'];
    if (!statuses.contains(status)) status = 'active';
    final remarkController = TextEditingController(text: contract.adminRemark);

    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.viewInsetsOf(context).bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Update contract',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: statuses
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(_label(value)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setModalState(() => status = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: remarkController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Admin remark',
                      hintText: 'Reason or update note',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, {
                        'status': status,
                        'remark': remarkController.text.trim(),
                      }),
                      child: const Text('Save status'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    remarkController.dispose();

    if (result != null) {
      await controller.updateContractStatus(
        contractId: contract.id,
        status: result['status']!,
        adminRemark: result['remark']!,
      );
    }
  }

  String _label(String value) {
    if (value.trim().isEmpty) return '—';
    return value
        .split('_')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  String _date(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    final local = parsed.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppTheme.primaryGold;
      case 'cancelled':
        return AppTheme.errorRed;
      case 'pending':
        return AppTheme.secondaryOrange;
      default:
        return AppTheme.successGreen;
    }
  }
}
