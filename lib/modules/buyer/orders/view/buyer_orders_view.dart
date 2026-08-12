import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../services/seller_services.dart'; // We can reuse the generic contract fetcher
import '../../../seller/contracts/model/seller_contract_model.dart';
import '../../../../theme/glass_widgets.dart';

class BuyerOrdersView extends StatefulWidget {
  const BuyerOrdersView({super.key});

  @override
  State<BuyerOrdersView> createState() => _BuyerOrdersViewState();
}

class _BuyerOrdersViewState extends State<BuyerOrdersView> {
  bool isLoading = true;
  List<SellerContractModel> contracts = [];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      setState(() => isLoading = true);
      // Reuse the generic contracts API which filters by the logged-in user's role
      final data = await SellerServices.getContracts(); 
      setState(() {
        contracts = data.map((e) => SellerContractModel.fromJson(e)).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      Get.snackbar("Error", "Failed to fetch orders");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const primaryColor = Color(0xFFFFB300);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("My Orders", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchOrders,
        color: primaryColor,
        child: isLoading 
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : contracts.isEmpty
            ? const Center(child: Text("No orders found"))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: contracts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final contract = contracts[index];
                  return GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Order: #${contract.contractNumber}",
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                (contract.status ?? 'ACTIVE').toUpperCase(),
                                style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _infoRow(IconlyLight.buy, "${contract.commodity} (${contract.quantity} ${contract.unit})", theme),
                        _infoRow(IconlyLight.wallet, "Amount: ₹${contract.totalAmount}", theme),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Date: ${contract.createdAt ?? 'N/A'}",
                              style: theme.textTheme.bodySmall,
                            ),
                            const Icon(IconlyLight.arrow_right_2, size: 18, color: primaryColor),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
