import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../../../theme/glass_widgets.dart';
import '../controller/buyer_delivery_challan_controller.dart';
import '../model/buyer_delivery_challan_model.dart';

class BuyerDeliveryChallanDetailView extends StatelessWidget {
  BuyerDeliveryChallanDetailView({super.key});

  final BuyerDeliveryChallanController controller = Get.find<BuyerDeliveryChallanController>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final int challanId = Get.arguments ?? 0;

    // Fetch details when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchChallanDetails(challanId);
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(IconlyLight.arrow_left_2),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Challan Details",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isDetailLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value.isNotEmpty && controller.currentChallan.value == null) {
          return Center(
            child: Text(
              controller.errorMessage.value,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          );
        }

        final challan = controller.currentChallan.value;
        if (challan == null) {
          return const Center(child: Text("Challan details not found."));
        }

        return Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderInfo(context, challan),
                  const SizedBox(height: 16),
                  _buildEntitiesInfo(context, challan),
                  const SizedBox(height: 16),
                  _buildTransportInfo(context, challan),
                  const SizedBox(height: 16),
                  _buildItemsList(context, challan.items ?? []),
                  const SizedBox(height: 16),
                  _buildAmountDetails(context, challan),
                  if (challan.narration != null && challan.narration!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildNarration(context, challan.narration!),
                  ],
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
            if (challan.status?.toLowerCase() == 'delivered' || challan.status?.toLowerCase() == 'dispatched')
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _showReceiveDialog(context, challan.id!),
                    child: controller.isReceiving.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            "Mark as Received",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  void _showReceiveDialog(BuildContext context, int challanId) {
    final remarksController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text("Receive Challan"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Are you sure you want to mark this challan as received?"),
            const SizedBox(height: 16),
            TextField(
              controller: remarksController,
              decoration: const InputDecoration(
                labelText: "Remarks (Optional)",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () {
              Get.back(); // close dialog
              controller.receiveChallan(challanId, remarksController.text);
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo(BuildContext context, BuyerDeliveryChallanModel challan) {
    final theme = Theme.of(context);
    String status = challan.status ?? "Unknown";
    Color statusColor = _getStatusColor(status);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                challan.challanNumber ?? "N/A",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(0.5)),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(IconlyLight.calendar, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                "Date: ${challan.challanDate ?? "N/A"}",
                style: GoogleFonts.inter(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(IconlyLight.time_circle, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                "Created: ${_formatDate(challan.createdAt)}",
                style: GoogleFonts.inter(fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEntitiesInfo(BuildContext context, BuyerDeliveryChallanModel challan) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(context, "Seller", challan.sellerNameDisplay ?? "N/A", IconlyLight.profile),
          const Divider(height: 24),
          _buildInfoRow(context, "Transporter", challan.transporterNameDisplay ?? "N/A", IconlyLight.send),
          if (challan.dispatchedByName != null) ...[
            const Divider(height: 24),
            _buildInfoRow(context, "Dispatched By", challan.dispatchedByName!, IconlyLight.arrow_up_circle),
          ],
          if (challan.receivedByName != null) ...[
            const Divider(height: 24),
            _buildInfoRow(context, "Received By", challan.receivedByName!, IconlyLight.arrow_down_circle),
          ],
        ],
      ),
    );
  }

  Widget _buildTransportInfo(BuildContext context, BuyerDeliveryChallanModel challan) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Transport Details",
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(context, "Truck No", challan.truckNumber ?? "N/A", IconlyLight.discovery),
          const SizedBox(height: 12),
          _buildInfoRow(context, "Driver Name", challan.driverName ?? "N/A", IconlyLight.profile),
          const SizedBox(height: 12),
          _buildInfoRow(context, "Driver Mobile", challan.driverMobile ?? "N/A", IconlyLight.call),
        ],
      ),
    );
  }

  Widget _buildItemsList(BuildContext context, List<DeliveryChallanItem> items) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Items (${items.length})",
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final item = items[index];
              return Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(IconlyBold.bag, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName ?? "Product",
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${item.quantity} ${item.unit} (${item.bagCount} bags)",
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "₹${item.amount}",
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "₹${item.rate} / ${item.unit}",
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAmountDetails(BuildContext context, BuyerDeliveryChallanModel challan) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Amount Details",
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildAmountRow(context, "Lorry Freight (per bag)", challan.lorryFreightPerBag),
          const SizedBox(height: 8),
          _buildAmountRow(context, "Loading Charges", challan.loadingCharges),
          const SizedBox(height: 8),
          _buildAmountRow(context, "Other Expenses", challan.otherExp),
          const SizedBox(height: 8),
          _buildAmountRow(context, "Less Advance", challan.lessAdvance),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Amount",
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                "₹${challan.totalAmount ?? '0.0'}",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildAmountRow(BuildContext context, String label, String? amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 14)),
        Text("₹${amount ?? '0.0'}", style: GoogleFonts.inter(fontSize: 14)),
      ],
    );
  }

  Widget _buildNarration(BuildContext context, String narration) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Narration / Details",
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            narration,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    status = status.toLowerCase();
    if (status.contains('delivered') || status.contains('received')) return Colors.green;
    if (status.contains('dispatched') || status.contains('transit')) return Colors.blue;
    if (status.contains('cancel')) return Colors.red;
    return Colors.orange;
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "N/A";
    try {
      final date = DateTime.parse(dateStr);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return dateStr;
    }
  }
}
