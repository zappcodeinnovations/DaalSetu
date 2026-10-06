import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../services/buyer_services.dart';
import '../../../../services/seller_services.dart';
import '../../../../theme/glass_widgets.dart';

class BuyerOrdersView extends StatefulWidget {
  const BuyerOrdersView({super.key});

  @override
  State<BuyerOrdersView> createState() => _BuyerOrdersViewState();
}

class _BuyerOrdersViewState extends State<BuyerOrdersView> {
  bool isLoading = true;
  List<Map<String, dynamic>> orders = [];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      setState(() => isLoading = true);
      List<Map<String, dynamic>> fetched = [];

      // 1. First attempt: Load recent orders from Buyer Dashboard API
      try {
        final dashData = await BuyerServices.getDashboard();
        final actual = dashData.containsKey('body') ? dashData['body'] : dashData;
        if (actual is Map<String, dynamic> && actual['recent_orders'] is List) {
          fetched = List<Map<String, dynamic>>.from(actual['recent_orders']);
        }
      } catch (e) {
        print("Dashboard orders fetch notice: $e");
      }

      // 2. Second attempt if empty: Check contracts
      if (fetched.isEmpty) {
        try {
          final contracts = await SellerServices.getSellerContracts();
          fetched = contracts.map((c) {
            if (c is Map<String, dynamic>) {
              return {
                'id': c['contract_number'] ?? c['id']?.toString() ?? '',
                'commodity': c['commodity'] ?? c['title'] ?? 'Commodity',
                'quantity': '${c['quantity'] ?? ''} ${c['unit'] ?? ''}'.trim(),
                'value': c['total_amount'] ?? c['rate'] ?? '0',
                'transport_status': c['status'] ?? 'Active',
                'created_at': c['created_at'] ?? 'Today',
              };
            }
            return <String, dynamic>{};
          }).where((e) => e.isNotEmpty).toList();
        } catch (e) {
          print("Contracts fetch notice: $e");
        }
      }

      setState(() {
        orders = fetched;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.iconTheme.color, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Recent Deals & Orders",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchOrders,
        color: primaryColor,
        child: isLoading
            ? Center(child: CircularProgressIndicator(color: primaryColor))
            : orders.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(IconlyLight.bag, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            "No Orders Found",
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "When you confirm deals, your orders will appear here.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      String status = order['transport_status']?.toString() ?? 'Pending';
                      Color statusColor = Colors.orange;
                      if (status.toLowerCase().contains("transit")) statusColor = Colors.blue;
                      if (status.toLowerCase().contains("complete") || status.toLowerCase().contains("delivered") || status.toLowerCase().contains("active")) {
                        statusColor = Colors.green;
                      }

                      return GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: primaryColor.withOpacity(0.12),
                              child: Icon(IconlyBold.bag, color: primaryColor, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order['commodity']?.toString() ?? "Commodity",
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: theme.textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Order ID: ${order['id'] ?? 'N/A'}",
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(IconlyLight.buy, size: 12, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        order['quantity']?.toString() ?? "-",
                                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(IconlyLight.calendar, size: 12, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        order['created_at']?.toString() ?? "Today",
                                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "₹${order['value'] ?? '0'}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "per Qtl",
                                  style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    status,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
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
}
