import 'package:iconly/iconly.dart';
import './contract_details_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/contract_controller.dart';

class ContractsScreen extends StatelessWidget {
  ContractsScreen({super.key});

  final controller = Get.put(ContractController());

  final filters = ["All", "Active", "Pending", "Completed", "Cancelled"];
  final selectedFilter = "All".obs;

  final selectedContracts = <int>{}.obs;
  final isSelectionMode = false.obs;

  final searchController = TextEditingController();

  /// FILTER + SEARCH
  List get filteredContracts {
    var list = controller.contracts.toList();

    if (selectedFilter.value != "All") {
      list = list
          .where(
            (c) => c.status.toLowerCase() == selectedFilter.value.toLowerCase(),
          )
          .toList();
    }

    if (searchController.text.isNotEmpty) {
      list = list.where((c) {
        return c.productTitle.toLowerCase().contains(
              searchController.text.toLowerCase(),
            ) ||
            c.contractId.toLowerCase().contains(
              searchController.text.toLowerCase(),
            ) ||
            c.displayBuyerId.toLowerCase().contains(
              searchController.text.toLowerCase(),
            ) ||
            c.displaySellerId.toLowerCase().contains(
              searchController.text.toLowerCase(),
            );
      }).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async {
        if (isSelectionMode.value) {
          isSelectionMode.value = false;
          selectedContracts.clear();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Obx(
            () => Text(
              isSelectionMode.value
                  ? "${selectedContracts.length} selected"
                  : "Contracts",
            ),
          ),
          actions: [
            /// SELECT ALL / DESELECT
            Obx(() {
              if (!isSelectionMode.value) return const SizedBox();

              final allSelected =
                  selectedContracts.length == controller.contracts.length;

              return IconButton(
                icon: Icon(allSelected ? IconlyLight.close_square : IconlyLight.tick_square),
                onPressed: () {
                  if (allSelected) {
                    selectedContracts.clear();
                  } else {
                    selectedContracts.clear();
                    selectedContracts.addAll(
                      controller.contracts.map((c) => c.id),
                    );
                  }
                },
              );
            }),

            /// DELETE
            Obx(() {
              if (!isSelectionMode.value) return const SizedBox();

              return IconButton(
                icon: const Icon(IconlyLight.delete),
                onPressed: () {
                  for (var id in selectedContracts) {
                    controller.deleteContract(id);
                  }

                  selectedContracts.clear();
                  isSelectionMode.value = false;
                },
              );
            }),
          ],
        ),

        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final contracts = filteredContracts;

          return Column(
            children: [
              /// SEARCH
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: searchController,
                  onChanged: (_) => selectedFilter.refresh(),
                  decoration: InputDecoration(
                    hintText: "Search ID, Commodity or Dealer",
                    prefixIcon: const Icon(IconlyLight.search),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              /// FILTER CHIPS
              SizedBox(
                height: 45,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: filters.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (_, index) {
                    final filter = filters[index];

                    return Obx(() {
                      final isSelected = selectedFilter.value == filter;

                      return GestureDetector(
                        onTap: () => selectedFilter.value = filter,
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : Colors.grey.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            filter,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    });
                  },
                ),
              ),

              const SizedBox(height: 10),

              /// CONTRACT LIST
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: contracts.length,
                  itemBuilder: (_, index) {
                    final contract = contracts[index];

                    return Obx(() {
                      final isSelected = selectedContracts.contains(
                        contract.id,
                      );

                      return GestureDetector(
                        onTap: () {
                          if (isSelectionMode.value) {
                            if (isSelected) {
                              selectedContracts.remove(contract.id);
                            } else {
                              selectedContracts.add(contract.id);
                            }

                            if (selectedContracts.isEmpty) {
                              isSelectionMode.value = false;
                            }

                            return;
                          }

                          Get.to(
                            () => ContractDetailScreen(),
                            arguments: contract.id,
                          );
                        },

                        onLongPress: () {
                          isSelectionMode.value = true;
                          selectedContracts.add(contract.id);
                        },

                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary.withOpacity(.12)
                                : theme.cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : Colors.grey.withOpacity(.1),
                            ),
                          ),

                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// LEFT CHECKBOX
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: isSelectionMode.value
                                    ? Padding(
                                        padding: const EdgeInsets.only(
                                          right: 10,
                                        ),
                                        child: Icon(
                                          isSelected
                                              ? IconlyLight.tick_square
                                              : IconlyLight.discovery,
                                          color: isSelected
                                              ? theme.colorScheme.primary
                                              : Colors.grey,
                                        ),
                                      )
                                    : const SizedBox(),
                              ),

                              /// CARD CONTENT
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            contract.productTitle,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),

                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _statusColor(
                                              contract.status,
                                            ).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            contract.status.toUpperCase(),
                                            style: TextStyle(
                                              color: _statusColor(
                                                contract.status,
                                              ),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 6),

                                    Text(
                                      contract.productCategory,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    /// BUYER SELLER
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _userTile(
                                            icon: IconlyLight.profile,
                                            title: "Seller",
                                            value: contract.displaySellerId,
                                          ),
                                        ),
                                        Expanded(
                                          child: _userTile(
                                            icon: IconlyLight.work,
                                            title: "Buyer",
                                            value: contract.displayBuyerId,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),

                                    /// DEAL
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "₹ ${contract.dealAmount}",
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange,
                                          ),
                                        ),
                                        Text(
                                          "${contract.dealQuantity} ${contract.quantityUnit}",
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 10),

                                    /// ROUTE
                                    Row(
                                      children: [
                                        const Icon(IconlyLight.location, size: 18),
                                        const SizedBox(width: 6),
                                        Text(contract.loadingFrom),
                                        const Spacer(),
                                        const Icon(IconlyLight.arrow_right_2),
                                        const Spacer(),
                                        Text(contract.loadingTo),
                                        const SizedBox(width: 6),
                                        const Icon(
                                          IconlyLight.send,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    });
                  },
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _userTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey)),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "active":
        return Colors.green;
      case "pending":
        return Colors.orange;
      case "cancelled":
        return Colors.red;
      case "completed":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
