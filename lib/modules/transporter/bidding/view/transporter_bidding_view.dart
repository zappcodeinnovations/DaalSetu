import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../controller/transporter_bidding_controller.dart';
import '../model/transporter_bid_model.dart';
import '../../../seller/contracts/view/seller_contract_detail_view.dart';
import '../../../../routes/app_routes.dart';
import 'package:daalsetu/widgets/app_shell.dart';
import '../../../../utils/app_snackbar.dart';

const _gold = Color(0xFFFFB300);

Widget _statusChip(String status) {
  final s = status.toLowerCase();
  final color = s == 'accepted'
      ? Colors.green
      : s == 'rejected'
      ? Colors.red
      : Colors.orange;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      s.toUpperCase(),
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
    ),
  );
}

Widget _row(String label, String value) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 3),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 110,
        child: Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    ],
  ),
);

/// Web "Shipment": Active Shipment Offer's (tab 0) and My Deals (tab 1).
class TransporterBiddingView extends StatelessWidget {
  final int initialTab;
  final String? initialStatus;

  /// The web's "My Contract Bids" page: only the transporter's bids, no offers tab
  /// (opened from the dashboard KPI cards).
  final bool myBidsOnly;
  const TransporterBiddingView({
    super.key,
    this.initialTab = 0,
    this.initialStatus,
    this.myBidsOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TransporterBiddingController());
    if (initialStatus != null && initialStatus!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.setBidStatus(initialStatus!);
      });
    }
    final theme = Theme.of(context);
    if (myBidsOnly) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          leading: const AppBarLeading(),
          leadingWidth: AppBarLeading.widthFor(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            "My Contract Bids",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
        ),
        body: _MyDealsTab(controller),
      );
    }
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(leading: const AppBarLeading(), leadingWidth: AppBarLeading.widthFor(context), 
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            "Shipments",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          bottom: TabBar(
            indicatorColor: _gold,
            labelColor: _gold,
            unselectedLabelColor: Colors.grey,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelPadding: const EdgeInsets.symmetric(horizontal: 16),
            labelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: "Active Shipment Offers"),
              Tab(text: "My Deals"),
            ],
          ),
        ),
        body: TabBarView(
          children: [_OffersTab(controller), _MyDealsTab(controller)],
        ),
      ),
    );
  }

  /// Displays the Place/Update Bid dialog styled with DaalSetu's primary orange/yellow theme.
  static void showBidDialog(
    BuildContext context,
    ShipmentOfferModel offer, {
    TransporterBiddingController? controller,
  }) {
    final TransporterBiddingController biddingController = controller ??
        (Get.isRegistered<TransporterBiddingController>()
            ? Get.find<TransporterBiddingController>()
            : Get.put(TransporterBiddingController()));
    final amount = TextEditingController(text: offer.myBid ?? '');
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          color: theme.cardColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header bar styled with primary orange/yellow brand theme
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_gold, Color(0xFFF57C00)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        offer.myBid != null ? "Update Bid" : "Place Bid",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 18,
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),
              // Body
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Contract ID
                    Text(
                      "Contract ID: ${offer.contractId}",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                      ),
                    ),
                    if (offer.currentLowestBid != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        "Current lowest bid: ₹${offer.currentLowestBid}",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Field label: "Bid Amount"
                    Text(
                      "Bid Amount",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Input field matching primary theme accents
                    TextField(
                      controller: amount,
                      cursorColor: _gold,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: "Enter bid amount",
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white38 : Colors.grey.shade400,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white24 : Colors.grey.shade300,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white24 : Colors.grey.shade300,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: _gold,
                            width: 1.8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Action Buttons (Cancel and Submit matching app branding)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Get.back(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                isDark ? Colors.white70 : Colors.grey.shade700,
                            side: BorderSide(
                              color: isDark ? Colors.white24 : Colors.grey.shade300,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _gold,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () {
                            final value = double.tryParse(amount.text.trim());
                            if (value == null || value <= 0) {
                              AppSnackbar.snackbar(
                                "Error",
                                "Enter a valid bid amount",
                                snackPosition: SnackPosition.BOTTOM,
                              );
                              return;
                            }
                            Get.back();
                            biddingController.placeBid(offer, amount.text.trim());
                          },
                          child: const Text(
                            "Submit",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.isLoadingOffers.value && controller.offers.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: _gold),
              );
            }
            return RefreshIndicator(
              color: _gold,
              onRefresh: controller.fetchOffers,
              child: controller.offers.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 100),
                        Icon(
                          IconlyLight.ticket_star,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              controller.offersError.value.isNotEmpty
                                  ? controller.offersError.value
                                  : "No shipments open for bidding right now",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                        if (controller.offersError.value.isNotEmpty)
                          Center(
                            child: TextButton(
                              onPressed: () =>
                                  Get.toNamed(AppRoutes.transporterCompany),
                              child: const Text("Complete Company Profile"),
                            ),
                          ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 180),
                      itemCount: controller.offers.length,
                      itemBuilder: (context, i) =>
                          _offerCard(context, controller.offers[i]),
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
                Expanded(
                  child: Text(
                    "Contract #${offer.contractId}",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (hasBid) _statusChip(offer.myBidStatus ?? 'pending'),
              ],
            ),
            Text(
              offer.productTitle,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const Divider(height: 18),
            _row("Pickup", offer.pickupLocation),
            _row("Delivery", offer.deliveryLocation),
            _row("Loading", offer.loadingDateRange),
            _row(
              "Quantity",
              "${offer.dealQuantity} ${offer.quantityUnit}${offer.bagCount != null ? ' • ${offer.bagCount} bags' : ''}",
            ),
            _row(
              "Lowest Bid",
              offer.currentLowestBid != null
                  ? "₹${offer.currentLowestBid}"
                  : "No bids yet",
            ),
            _row("Total Bids", "${offer.activeBidCount}"),
            if (hasBid)
              _row(
                "My Bid",
                "₹${offer.myBid}${offer.myBidPosition != null ? '  (Rank #${offer.myBidPosition})' : ''}",
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showCompetingBids(context, offer),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _gold,
                      side: const BorderSide(color: _gold, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "VIEW BIDS",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showBidDialog(context, offer),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      hasBid ? "UPDATE BID" : "PLACE BID",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBidDialog(BuildContext context, ShipmentOfferModel offer) =>
      TransporterBiddingView.showBidDialog(context, offer, controller: controller);

  Future<void> _showCompetingBids(
    BuildContext context,
    ShipmentOfferModel offer,
  ) async {
    final bids = await controller.fetchContractBids(offer.id);
    if (!context.mounted) return;

    Get.bottomSheet(
      SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.75,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top drag handle indicator
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Bids on Contract #${offer.contractId}",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Transporter identities are hidden.",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20,
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: bids.isEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 36,
                          horizontal: 20,
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.gavel_outlined,
                              size: 40,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "No bids yet",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Be the first transporter to place a bid on this shipment.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        itemCount: bids.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final b = bids[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${b['transporter_unique_id'] ?? 'Transporter'}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      if (b['bid_date'] != null &&
                                          b['bid_date'].toString().isNotEmpty)
                                        Text(
                                          "${b['bid_date']}",
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "₹${b['bid_amount']}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    _statusChip('${b['status'] ?? 'pending'}'),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}

class _MyDealsTab extends StatelessWidget {
  final TransporterBiddingController controller;
  const _MyDealsTab(this.controller);

  static const _filters = {
    'all': 'All',
    'pending': 'Pending',
    'accepted': 'Accepted',
    'rejected': 'Rejected',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        SizedBox(
          height: 48,
          child: Obx(
            () => ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: _filters.entries.map((e) {
                final isSelected = controller.bidStatus.value == e.key;
                return GestureDetector(
                  onTap: () => controller.setBidStatus(e.key),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? _gold : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? _gold : theme.dividerColor,
                      ),
                    ),
                    child: Text(
                      e.value,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.isLoadingBids.value && controller.myBids.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: _gold),
              );
            }
            return RefreshIndicator(
              color: _gold,
              onRefresh: controller.fetchMyBids,
              child: controller.myBids.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 120),
                        Icon(
                          IconlyLight.document,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            "No bids yet",
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 180),
                      itemCount: controller.myBids.length,
                      itemBuilder: (context, i) =>
                          _bidCard(context, controller.myBids[i]),
                    ),
            );
          }),
        ),
      ],
    );
  }

  Widget _bidCard(BuildContext context, MyBidModel bid) {
    final a = bid.assignment;
    final hasAssignment =
        (a['truck_number'] ?? '').isNotEmpty ||
        (a['driver_name'] ?? '').isNotEmpty;
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
                Expanded(
                  child: Text(
                    "Contract #${bid.contractId}",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                _statusChip(bid.status),
              ],
            ),
            Text(
              bid.productTitle,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const Divider(height: 18),
            _row("My Bid", "₹${bid.bidAmount}"),
            _row("Route", "${bid.loadingFrom} → ${bid.loadingTo}"),
            _row("Quantity", "${bid.dealQuantity} ${bid.quantityUnit}"),
            if (bid.adminRemark != null) _row("Admin Remark", bid.adminRemark!),
            if (hasAssignment) ...[
              _row(
                "Vehicle",
                a['truck_number']?.isNotEmpty == true
                    ? a['truck_number']!
                    : '-',
              ),
              _row(
                "Driver",
                "${a['driver_name'] ?? '-'} ${a['driver_mobile']?.isNotEmpty == true ? '• ${a['driver_mobile']}' : ''}",
              ),
            ],
            if (bid.assignmentLocked)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "Dispatched — vehicle/driver can no longer be changed.",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                // Buyer/seller details only for won (accepted) bids, as on the web;
                // pending and rejected bids have no deal to show.
                if (bid.status.toLowerCase() == 'accepted')
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: bid.contractPk > 0
                        ? () {
                            final initialMap = Map<String, dynamic>.from(bid.contractData);
                            // Ensure key contract fields are populated in case contractData was partial
                            initialMap['id'] ??= bid.contractPk;
                            initialMap['contract_id'] ??= bid.contractId;
                            initialMap['product_title'] ??= bid.productTitle;
                            initialMap['loading_from'] ??= bid.loadingFrom;
                            initialMap['loading_to'] ??= bid.loadingTo;
                            initialMap['deal_quantity'] ??= bid.dealQuantity;
                            initialMap['quantity_unit'] ??= bid.quantityUnit;
                            initialMap['status'] ??= bid.contractStatus.isNotEmpty ? bid.contractStatus : bid.status;
                            Get.to(() => SellerContractDetailView(
                              contractId: bid.contractPk,
                              initialData: initialMap,
                            ));
                          }
                        : null,
                    icon: const Icon(IconlyLight.show, size: 16),
                    label: const Text("VIEW DETAILS"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _gold,
                      side: const BorderSide(color: _gold),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (bid.canAssignDriver) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showAssignDialog(context, bid),
                      icon: const Icon(
                        Icons.local_shipping,
                        color: Colors.white,
                        size: 16,
                      ),
                      label: Text(
                        hasAssignment ? "CHANGE FLEET" : "ASSIGN FLEET",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gold,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignDialog(BuildContext context, MyBidModel bid) {
    if (controller.vehicles.isEmpty || controller.drivers.isEmpty) {
      AppSnackbar.snackbar(
        "Fleet needed",
        "Add an active vehicle and driver first.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    int? vehicleId = bid.assignedVehicleId;
    int? driverId = bid.assignedDriverId;
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            "Assign Vehicle & Driver",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: controller.vehicles.any((v) => v.id == vehicleId)
                    ? vehicleId
                    : null,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: "Vehicle",
                  border: OutlineInputBorder(),
                ),
                items: controller.vehicles
                    .map(
                      (v) => DropdownMenuItem(
                        value: v.id,
                        child: Text(v.label, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => vehicleId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: controller.drivers.any((d) => d.id == driverId)
                    ? driverId
                    : null,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: "Driver",
                  border: OutlineInputBorder(),
                ),
                items: controller.drivers
                    .map(
                      (d) => DropdownMenuItem(
                        value: d.id,
                        child: Text(d.label, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (d) => setState(() {
                  driverId = d;
                  // Pre-select the driver's own vehicle, like the web form.
                  final linked = controller.drivers
                      .firstWhereOrNull((x) => x.id == d)
                      ?.linkedVehicleId;
                  if (linked != null &&
                      controller.vehicles.any((v) => v.id == linked)) {
                    vehicleId = linked;
                  }
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text("CANCEL"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _gold),
              onPressed: () {
                if (vehicleId == null || driverId == null) {
                  AppSnackbar.snackbar(
                    "Error",
                    "Please select both vehicle and driver.",
                    snackPosition: SnackPosition.BOTTOM,
                  );
                  return;
                }
                Get.back();
                controller.assignDriver(bid, vehicleId!, driverId!);
              },
              child: const Text(
                "ASSIGN",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
