import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../services/buyer_services.dart';
import '../../delivery_challan/model/buyer_challan_model.dart';
import '../../../../theme/glass_widgets.dart';

class BuyerTransportTrackingView extends StatefulWidget {
  const BuyerTransportTrackingView({super.key});

  @override
  State<BuyerTransportTrackingView> createState() => _BuyerTransportTrackingViewState();
}

class _BuyerTransportTrackingViewState extends State<BuyerTransportTrackingView> {
  bool isLoading = true;
  List<BuyerChallanModel> activeShipments = [];

  @override
  void initState() {
    super.initState();
    _fetchTrackingData();
  }

  Future<void> _fetchTrackingData() async {
    try {
      setState(() => isLoading = true);
      final data = await BuyerServices.getDeliveryChallans();
      final list = (data['results'] as List?) ?? (data['challans'] as List?) ?? (data['data'] as List?) ?? [];
      setState(() {
        // Filter only for shipments that are currently 'dispatched' (on the way)
        activeShipments = list
            .map((e) => BuyerChallanModel.fromJson(e))
            .where((c) => (c.status ?? '').toLowerCase() == 'dispatched')
            .toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      Get.snackbar("Error", "Failed to load tracking data");
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
        title: Text("Transport Tracking", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchTrackingData,
        color: primaryColor,
        child: isLoading 
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : activeShipments.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(IconlyLight.location, size: 64, color: theme.disabledColor),
                    const SizedBox(height: 16),
                    const Text("No active shipments in transit"),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: activeShipments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final shipment = activeShipments[index];
                  return GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              shipment.truckNumber,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                "IN TRANSIT",
                                style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _infoRow(IconlyLight.user_1, "Driver: ${shipment.dispatchedByName}", theme),
                        _infoRow(IconlyLight.location, "From: ${shipment.sellerName}", theme),
                        const Divider(height: 24),
                        Row(
                          children: [
                            const Icon(IconlyLight.time_circle, size: 16, color: primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              "Dispatched: ${shipment.dispatchedAt?.day}/${shipment.dispatchedAt?.month} at ${shipment.dispatchedAt?.hour}:${shipment.dispatchedAt?.minute}",
                              style: theme.textTheme.bodySmall,
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
