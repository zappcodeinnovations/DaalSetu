import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../controller/transporter_bidding_controller.dart';
import '../model/transporter_bid_model.dart';
import '../../../../routes/app_routes.dart';

const _gold = Color(0xFFFFB300);

Widget _statusChip(String status) {
  final s = status.toLowerCase();
  final color = s == 'accepted' ? Colors.green : s == 'rejected' ? Colors.red : Colors.orange;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
    child: Text(s.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
  );
}

Widget _row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
    );

/// Web "Shipment": Active Shipment Offer's (tab 0) and My Deals (tab 1).
class TransporterBiddingView extends StatelessWidget {
  final int initialTab;
  const TransporterBiddingView({super.key, this.initialTab = 0});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TransporterBiddingController());
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text("Shipments", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
          bottom: TabBar(
            indicatorColor: _gold,
            labelColor: _gold,
            unselectedLabelColor: Colors.grey,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [Tab(text: "Active Shipment Offers"), Tab(text: "My Deals")],
          ),
        ),
        body: TabBarView(children: [_OffersTab(controller), _MyDealsTab(controller)]),
      ),
    );
  }
}

class _OffersTab extends StatelessWidget {
  final TransporterBiddingController controller;
  const _OffersTab(this.controller);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            onChanged: (v) => controller.offerSearch.value = v,
            decoration: InputDecoration(
              hintText: "Search contract or product...",
              prefixIcon: const Icon(IconlyLight.search, color: _gold),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Theme.of(context).cardColor,
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.isLoadingOffers.value && controller.offers.isEmpty) {
              return const Center(child: CircularProgressIndicator(color: _gold));
            }
            return RefreshIndicator(
              color: _gold,
              onRefresh: controller.fetchOffers,
              child: controller.offers.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 100),
                        Icon(IconlyLight.ticket_star, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              controller.offersError.value.isNotEmpty ? controller.offersError.value : "No shipments open for bidding right now",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(color: Colors.grey.shade600),
                            ),
                          ),
                        ),
                        if (controller.offersError.value.isNotEmpty)
                          Center(
                            child: TextButton(
                              onPressed: () => Get.toNamed(AppRoutes.transporterCompany),
                              child: const Text("Complete Company Profile"),
                            ),
                          ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: controller.offers.length,
                      itemBuilder: (context, i) => _offerCard(context, controller.offers[i]),
                    ),
            );
          }),
        ),
      ],
    );
  }

  Widget _offerCard(BuildContext context, ShipmentOfferModel offer) {
    final hasBid = offer.myBid != null;
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text("Contract #${offer.contractId}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15))),
                if (hasBid) _statusChip(offer.myBidStatus ?? 'pending'),
              ],
            ),
            Text(offer.productTitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const Divider(height: 18),
            _row("Pickup", offer.pickupLocation),
            _row("Delivery", offer.deliveryLocation),
            _row("Loading", offer.loadingDateRange),
            _row("Quantity", "${offer.dealQuantity} ${offer.quantityUnit}${offer.bagCount != null ? ' • ${offer.bagCount} bags' : ''}"),
            _row("Lowest Bid", offer.currentLowestBid != null ? "₹${offer.currentLowestBid}" : "No bids yet"),
            _row("Total Bids", "${offer.activeBidCount}"),
            if (hasBid) _row("My Bid", "₹${offer.myBid}${offer.myBidPosition != null ? '  (Rank #${offer.myBidPosition})' : ''}"),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showCompetingBids(context, offer),
                    style: OutlinedButton.styleFrom(foregroundColor: _gold, side: const BorderSide(color: _gold)),
                    child: const Text("VIEW BIDS"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showBidDialog(context, offer),
                    style: ElevatedButton.styleFrom(backgroundColor: _gold),
                    child: Text(hasBid ? "UPDATE BID" : "PLACE BID", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBidDialog(BuildContext context, ShipmentOfferModel offer) {
    final amount = TextEditingController(text: offer.myBid ?? '');
    Get.dialog(AlertDialog(
      title: Text(offer.myBid != null ? "Update Freight Bid" : "Place Freight Bid", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${offer.pickupLocation} → ${offer.deliveryLocation}", style: const TextStyle(fontSize: 12)),
          if (offer.currentLowestBid != null)
            Text("Current lowest bid: ₹${offer.currentLowestBid}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 12),
          TextField(
            controller: amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: "Total freight amount (₹)", border: OutlineInputBorder()),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text("CANCEL")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _gold),
          onPressed: () {
            final value = double.tryParse(amount.text.trim());
            if (value == null || value <= 0) {
              Get.snackbar("Error", "Enter a valid bid amount", snackPosition: SnackPosition.BOTTOM);
              return;
            }
            Get.back();
            controller.placeBid(offer, amount.text.trim());
          },
          child: const Text("SUBMIT", style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }

  Future<void> _showCompetingBids(BuildContext context, ShipmentOfferModel offer) async {
    final bids = await controller.fetchContractBids(offer.id);
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Get.theme.cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Bids on Contract #${offer.contractId}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text("Transporter identities are hidden.", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            if (bids.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text("No bids yet")),
            ...bids.map((b) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text("${b['transporter_unique_id'] ?? 'Transporter'}"),
                  subtitle: Text("${b['bid_date'] ?? ''}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("₹${b['bid_amount']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      _statusChip('${b['status'] ?? 'pending'}'),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _MyDealsTab extends StatelessWidget {
  final TransporterBiddingController controller;
  const _MyDealsTab(this.controller);

  static const _filters = {'all': 'All', 'pending': 'Pending', 'accepted': 'Accepted', 'rejected': 'Rejected'};

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 52,
          child: Obx(() => ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                children: _filters.entries
                    .map((e) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(e.value),
                            selected: controller.bidStatus.value == e.key,
                            selectedColor: _gold.withValues(alpha: 0.25),
                            onSelected: (_) => controller.setBidStatus(e.key),
                          ),
                        ))
                    .toList(),
              )),
        ),
        Expanded(
          child: Obx(() {
            if (controller.isLoadingBids.value && controller.myBids.isEmpty) {
              return const Center(child: CircularProgressIndicator(color: _gold));
            }
            return RefreshIndicator(
              color: _gold,
              onRefresh: controller.fetchMyBids,
              child: controller.myBids.isEmpty
                  ? ListView(children: [
                      const SizedBox(height: 120),
                      Icon(IconlyLight.document, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Center(child: Text("No bids yet", style: GoogleFonts.poppins(color: Colors.grey.shade600))),
                    ])
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: controller.myBids.length,
                      itemBuilder: (context, i) => _bidCard(context, controller.myBids[i]),
                    ),
            );
          }),
        ),
      ],
    );
  }

  Widget _bidCard(BuildContext context, MyBidModel bid) {
    final a = bid.assignment;
    final hasAssignment = (a['truck_number'] ?? '').isNotEmpty || (a['driver_name'] ?? '').isNotEmpty;
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text("Contract #${bid.contractId}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15))),
                _statusChip(bid.status),
              ],
            ),
            Text(bid.productTitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const Divider(height: 18),
            _row("My Bid", "₹${bid.bidAmount}"),
            _row("Route", "${bid.loadingFrom} → ${bid.loadingTo}"),
            _row("Quantity", "${bid.dealQuantity} ${bid.quantityUnit}"),
            if (bid.adminRemark != null) _row("Admin Remark", bid.adminRemark!),
            if (hasAssignment) ...[
              _row("Vehicle", a['truck_number']?.isNotEmpty == true ? a['truck_number']! : '-'),
              _row("Driver", "${a['driver_name'] ?? '-'} ${a['driver_mobile']?.isNotEmpty == true ? '• ${a['driver_mobile']}' : ''}"),
            ],
            if (bid.assignmentLocked)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text("Dispatched — vehicle/driver can no longer be changed.", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ),
            if (bid.canAssignDriver) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showAssignDialog(context, bid),
                  icon: const Icon(Icons.local_shipping, color: Colors.white, size: 18),
                  label: Text(hasAssignment ? "CHANGE VEHICLE & DRIVER" : "ASSIGN VEHICLE & DRIVER",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: _gold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAssignDialog(BuildContext context, MyBidModel bid) {
    if (controller.vehicles.isEmpty || controller.drivers.isEmpty) {
      Get.snackbar("Fleet needed", "Add an active vehicle and driver first.", snackPosition: SnackPosition.BOTTOM);
      return;
    }
    int? vehicleId = bid.assignedVehicleId;
    int? driverId = bid.assignedDriverId;
    Get.dialog(StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text("Assign Vehicle & Driver", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              initialValue: controller.vehicles.any((v) => v.id == vehicleId) ? vehicleId : null,
              isExpanded: true,
              decoration: const InputDecoration(labelText: "Vehicle", border: OutlineInputBorder()),
              items: controller.vehicles.map((v) => DropdownMenuItem(value: v.id, child: Text(v.label, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (v) => setState(() => vehicleId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: controller.drivers.any((d) => d.id == driverId) ? driverId : null,
              isExpanded: true,
              decoration: const InputDecoration(labelText: "Driver", border: OutlineInputBorder()),
              items: controller.drivers.map((d) => DropdownMenuItem(value: d.id, child: Text(d.label, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (d) => setState(() {
                driverId = d;
                // Pre-select the driver's own vehicle, like the web form.
                final linked = controller.drivers.firstWhereOrNull((x) => x.id == d)?.linkedVehicleId;
                if (linked != null && controller.vehicles.any((v) => v.id == linked)) vehicleId = linked;
              }),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _gold),
            onPressed: () {
              if (vehicleId == null || driverId == null) {
                Get.snackbar("Error", "Please select both vehicle and driver.", snackPosition: SnackPosition.BOTTOM);
                return;
              }
              Get.back();
              controller.assignDriver(bid, vehicleId!, driverId!);
            },
            child: const Text("ASSIGN", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ));
  }
}
