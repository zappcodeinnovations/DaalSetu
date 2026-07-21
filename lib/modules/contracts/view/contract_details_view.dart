import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/contract_controller.dart';

class ContractDetailScreen extends StatefulWidget {
  const ContractDetailScreen({super.key});

  @override
  State<ContractDetailScreen> createState() => _ContractDetailScreenState();
}

class _ContractDetailScreenState extends State<ContractDetailScreen> {
  final controller = Get.find<ContractController>();

  late int contractId;

  @override
  void initState() {
    super.initState();

    contractId = Get.arguments;

    Future.microtask(() {
      controller.fetchContractDetail(contractId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text("Contract Details")),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final contract = controller.contractDetail.value;

        if (contract == null) {
          return const Center(child: Text("No Data"));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              /// PRODUCT CARD
              _productCard(contract),

              const SizedBox(height: 16),

              /// BUYER SELLER
              Row(
                children: [
                  Expanded(
                    child: _partyCard("SELLER", contract.displaySellerId),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _partyCard("BUYER", contract.displayBuyerId)),
                ],
              ),

              const SizedBox(height: 16),

              /// DEAL BOX
              _dealBox(contract),

              const SizedBox(height: 16),

              /// ROUTE CARD
              _routeCard(contract),

              const SizedBox(height: 16),

              /// REMARKS
              _remarksCard(contract),

              const SizedBox(height: 20),

              /// DATES
              _dateSection(contract),
            ],
          ),
        );
      }),
    );
  }

  /// PRODUCT CARD
  Widget _productCard(contract) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                contract.productCategory.toUpperCase(),
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: theme.colorScheme.primary.withOpacity(.15),
                ),
                child: Text(
                  contract.contractId,
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            contract.productTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// PARTY CARD
  Widget _partyCard(String title, String value) {
    final theme = Theme.of(context);

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: theme.colorScheme.primary,
            child: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(title, style: theme.textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }

  /// DEAL BOX
  Widget _dealBox(contract) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "DEAL AMOUNT",
                style: TextStyle(color: Colors.white70),
              ),
              Text(
                "₹${contract.dealAmount}",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Container(width: 1, height: 40, color: Colors.white54),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text("QUANTITY", style: TextStyle(color: Colors.white70)),
              Text(
                "${contract.dealQuantity} ${contract.quantityUnit}",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ROUTE
  Widget _routeCard(contract) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Transit Route",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(contract.loadingFrom),
              const Icon(Icons.arrow_forward),
              Text(contract.loadingTo),
            ],
          ),
        ],
      ),
    );
  }

  /// REMARKS
  Widget _remarksCard(contract) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Contract Remarks",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _remark("Buyer Remark", contract.buyerRemark),
          _remark("Seller Remark", contract.sellerRemark),
          _remark("Admin Remark", contract.adminRemark),
        ],
      ),
    );
  }

  Widget _remark(String title, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  /// CREATED & CONFIRMED
  Widget _dateSection(contract) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _dateRow("Created At", contract.createdAt),
          const SizedBox(height: 8),
          _dateRow("Confirmed At", contract.confirmedAt),
        ],
      ),
    );
  }

  Widget _dateRow(String title, String value) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: theme.textTheme.bodyMedium),
        Text(value, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
