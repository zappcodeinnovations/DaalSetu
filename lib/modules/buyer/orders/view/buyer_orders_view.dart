import 'package:daalsetu/widgets/page_auto_refresh.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../services/buyer_services.dart';
import '../../../../services/seller_services.dart';
import '../../../../theme/glass_widgets.dart';
import 'package:daalsetu/widgets/app_shell.dart';
import 'package:daalsetu/widgets/hero_header.dart';

class BuyerOrdersView extends StatefulWidget {
  const BuyerOrdersView({super.key});

  @override
  State<BuyerOrdersView> createState() => _BuyerOrdersViewState();
}

class _BuyerOrdersViewState extends State<BuyerOrdersView> {
  bool isLoading = true;
  List<Map<String, dynamic>> orders = [];
  bool _fetchingOrders = false;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders({bool silent = false}) async {
    if (_fetchingOrders || !mounted) return;
    _fetchingOrders = true;
    try {
      if (!silent) setState(() => isLoading = true);
      List<Map<String, dynamic>> fetched = [];

      // 1. First attempt: Load recent orders from Buyer Dashboard API
      try {
        final dashData = await BuyerServices.getDashboard();
        final actual = dashData.containsKey('body') ? dashData['body'] : dashData;
        if (actual is Map<String, dynamic> && actual['recent_orders'] is List) {
          fetched = List<Map<String, dynamic>>.from(actual['recent_orders']);
        }
      } catch (e) {
        if (silent) rethrow;
        print("Dashboard orders fetch notice: $e");
      }

      // 2. Second attempt if empty: Check contracts
      if (fetched.isEmpty) {
        try {
          final contracts = await SellerServices.getSellerContracts(silent: silent);
          fetched = contracts.map((c) {
            if (c is Map<String, dynamic>) {
              return {
                'id': c['contract_number'] ?? c['contract_id'] ?? '',
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
          if (silent) rethrow;
          print("Contracts fetch notice: $e");
        }
      }

      if (!mounted) return;
      setState(() {
        orders = fetched;
        isLoading = false;
      });
    } catch (e) {
      if (mounted && !silent) setState(() => isLoading = false);
    } finally {
      _fetchingOrders = false;
    }
  }

  @override
  Widget build(BuildContext context) => PageAutoRefresh(
    onRefresh: () => _fetchOrders(silent: true),
    child: _buildPageContent(context),
  );

  Widget _buildPageContent(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: HeroHeader(
        leading: AppBarLeading(
          child: Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  onPressed: () => Get.back(),
                )
              : null,
        ),
        title: "Recent Deals & Orders",
        subtitle: "Confirmed purchases & order fulfillment status",
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

                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _showOrderDetails(context, order, statusColor),
                        child: GlassCard(
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
                                    order['seller_name']?.toString() ??
                                        order['brand']?.toString() ??
                                        order['contract_number']?.toString() ??
                                        'Confirmed Order',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                      ),
                    );
                    },
                  ),
      ),
    );
  }

  void _showOrderDetails(BuildContext context, Map<String, dynamic> order, Color statusColor) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final status = order['transport_status']?.toString() ?? 'Pending';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF162032) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: isDark ? const Color(0xFF2C394F) : const Color(0xFFE2E8F0),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      order['commodity']?.toString() ?? "Order Details",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                order['seller_name']?.toString() ??
                    order['brand']?.toString() ??
                    order['contract_number']?.toString() ??
                    'Confirmed Deal',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade700,
                ),
              ),
              const Divider(height: 28),
              _detailRow(Icons.inventory_2_outlined, "Quantity", order['quantity']?.toString() ?? "-", isDark),
              const SizedBox(height: 12),
              _detailRow(Icons.currency_rupee_rounded, "Price", "₹${order['value'] ?? '0'} per Qtl", isDark),
              const SizedBox(height: 12),
              _detailRow(Icons.calendar_today_outlined, "Order Date", order['created_at']?.toString() ?? "Today", isDark),
              if (order['id'] != null && order['id'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                _detailRow(Icons.tag_rounded, "Order ID", order['id'].toString(), isDark),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    "Close",
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }
}
