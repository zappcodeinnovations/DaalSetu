import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:daalsetu/theme/glass_widgets.dart';
import 'package:daalsetu/modules/buyer/offers/controller/buyer_offers_controller.dart';
import 'package:daalsetu/modules/buyer/offers/model/buyer_offer_model.dart';

class BuyerOffersView extends StatelessWidget {
  const BuyerOffersView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            "Offers",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.textTheme.bodyMedium?.color,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: "All"),
              Tab(text: "Today"),
              Tab(text: "Pending"),
              Tab(text: "Previous"),
              Tab(text: "My Interests"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _OfferList(offerType: 'all'),
            _OfferList(offerType: 'today'),
            _OfferList(offerType: 'pending'),
            _OfferList(offerType: 'previous'),
            _OfferList(offerType: 'interests'),
          ],
        ),
      ),
    );
  }
}

class _OfferList extends StatelessWidget {
  final String offerType;

  const _OfferList({required this.offerType});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use tag so each tab has its own controller instance
    final controller = Get.put(BuyerOffersController(offerType: offerType), tag: offerType);

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.isError.value) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Error: ${controller.errorMessage.value}",
                style: TextStyle(color: theme.colorScheme.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => controller.fetchOffers(),
                child: const Text("Retry"),
              ),
            ],
          ),
        );
      }

      final offers = controller.offersList;

      if (offers.isEmpty) {
        return const Center(child: Text("No offers found."));
      }

      return RefreshIndicator(
        onRefresh: () => controller.fetchOffers(),
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: offers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final offer = offers[index];
            return GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          offer.displayTitle ?? 'Offer',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          offer.displayStatus ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Quantity: ${offer.displayQuantity}",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      Text(
                        offer.displayPrice ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildActionButtons(context, controller, offer),
                ],
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildActionButtons(BuildContext context, BuyerOffersController controller, BuyerOfferModel offer) {
    if (offer.productId == null || offer.interestId == null) {
      return const SizedBox.shrink();
    }
    
    // Only show specific actions based on the tab (e.g. pending/interests)
    // Or we can just show action buttons generally and assume backend handles logic
    // Let's show Approve, Confirm, Reject Interest, Reject Offer as an example.
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ActionBtn(
          label: "Approve",
          color: Colors.green,
          onTap: () => _showRemarkDialog(context, controller, "approve", offer),
        ),
        _ActionBtn(
          label: "Confirm",
          color: Colors.blue,
          onTap: () => _showRemarkDialog(context, controller, "confirm", offer),
        ),
        _ActionBtn(
          label: "Reject Interest",
          color: Colors.orange,
          onTap: () => _showRemarkDialog(context, controller, "reject_interest", offer),
        ),
        _ActionBtn(
          label: "Reject Offer",
          color: Colors.red,
          onTap: () => _showRemarkDialog(context, controller, "reject_offer", offer),
        ),
      ],
    );
  }

  void _showRemarkDialog(BuildContext context, BuyerOffersController controller, String action, BuyerOfferModel offer) {
    final remarkCtrl = TextEditingController();
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Confirm Action: ${action.replaceAll('_', ' ').toUpperCase()}",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              GlassTextField(
                controller: remarkCtrl,
                hintText: "Enter remark...",
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Get.back();
                      controller.performAction(action, offer.productId!, offer.interestId!, remarkCtrl.text);
                    },
                    child: const Text("Submit"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
