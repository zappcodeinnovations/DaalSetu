import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:daalsetu/modules/products/model/product_model.dart';
import 'package:daalsetu/modules/admin_catalog/controller/admin_offers_controller.dart';
import 'package:daalsetu/modules/admin_catalog/view/offer_interests_dialog.dart';
import 'package:daalsetu/modules/admin_catalog/view/stock_history_dialog.dart';
import 'package:daalsetu/widgets/authenticated_network_image.dart';
import 'package:daalsetu/theme/app_theme.dart';

class AdminOffersListScreen extends StatefulWidget {
  const AdminOffersListScreen({super.key});

  @override
  State<AdminOffersListScreen> createState() => _AdminOffersListScreenState();
}

class _AdminOffersListScreenState extends State<AdminOffersListScreen> {
  final AdminOffersController controller = Get.put(AdminOffersController());

  // Colors based on the provided UI
  final bgColor = AppTheme.bgDarkNavy;
  final cardColor = AppTheme.cardColor;
  final borderColor = AppTheme.borderColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Admin Offers', style: TextStyle(color: Colors.white)),
        backgroundColor: bgColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: controller.fetchOffers,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold));
        }
        if (controller.hasError.value) {
          return Center(
            child: Text(
              "Error: ${controller.errorMessage.value}",
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }
        if (controller.offers.isEmpty) {
          return const Center(child: Text("No offers found", style: TextStyle(color: Colors.white)));
        }

        return RefreshIndicator(
          onRefresh: controller.fetchOffers,
          color: Colors.white,
          backgroundColor: cardColor,
          child: ListView.separated(
            padding: const EdgeInsets.all(12.0),
            itemCount: controller.offers.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final offer = controller.offers[index];
              return _buildOfferCard(offer);
            },
          ),
        );
      }),
    );
  }

  Widget _buildOfferCard(ProductModel offer) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title, Subtitle, Image
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${offer.category?.name ?? ''} • ${offer.brand?.name ?? ''}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (offer.images.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AuthenticatedNetworkImage(
                    url: offer.images.first.imageUrl,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    fallback: Container(
                      width: 70,
                      height: 70,
                      color: Colors.black26,
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                )
              else
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.image_outlined, color: Colors.grey),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Attributes
          _buildAttributeRow(Icons.person, 'Seller', offer.seller?.username ?? '-'),
          const SizedBox(height: 8),
          _buildAttributeRow(Icons.location_on, 'Loading', offer.loadingLocation.isNotEmpty ? offer.loadingLocation : '-'),
          const SizedBox(height: 8),
          _buildDateRow(offer),
          const SizedBox(height: 16),

          // 3 Info Boxes
          Row(
            children: [
              Expanded(
                child: _buildPastelBox(
                  icon: Icons.currency_rupee,
                  label: 'Rate',
                  value: '₹${offer.amount}',
                  unit: '/${offer.amountUnit.toUpperCase()}',
                  bgColor: AppTheme.successGreen.withValues(alpha: 0.15), // Light Green
                  fgColor: AppTheme.successGreen, // Dark Green
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPastelBox(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Bags',
                  value: offer.originalBagCount?.toString() ?? '-',
                  unit: '',
                  bgColor: AppTheme.secondaryOrange.withValues(alpha: 0.15), // Light Orange
                  fgColor: AppTheme.secondaryOrange, // Dark Orange
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPastelBox(
                  icon: Icons.hourglass_empty,
                  label: 'Quantity',
                  value: offer.availableQuantity.toString(),
                  unit: 'QTL',
                  bgColor: AppTheme.primaryGold.withValues(alpha: 0.15), // Light Blue
                  fgColor: AppTheme.primaryGold, // Dark Blue
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Status & Visibility
          Row(
            children: [
              _buildStatusBadge(offer.stockStatus),
              const Spacer(),
              const Text('Visible', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(width: 4),
              SizedBox(
                height: 24,
                width: 40,
                child: FittedBox(
                  fit: BoxFit.fill,
                  child: Switch(
                    value: offer.isActive,
                    onChanged: (val) => controller.toggleVisibility(offer.id, offer.isActive),
                    activeColor: Colors.white,
                    activeTrackColor: AppTheme.successGreen,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: AppTheme.borderColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () => _showInterestsDialog(offer.id, offer.title),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155), // Dark badge
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite, color: Colors.redAccent, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${offer.interestCount}',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Manage Stock Section
          _ManageStockRow(
            offerId: offer.id,
            initialPackingKg: double.tryParse(offer.packingWeightKg) ?? 0,
            onSave: (action, qty, bags, packingKg) {
              controller.manageStock(
                offer.id,
                action: action,
                quantity: qty,
                bags: bags,
                packingKg: packingKg,
              );
            },
          ),

          const SizedBox(height: 16),

          // Bottom Action Buttons
          Row(
            children: [
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () => _showInterestsDialog(offer.id, offer.title),
                  icon: const Icon(Icons.handshake, size: 16),
                  label: Text('Manage Bids (${offer.interestCount})', style: const TextStyle(fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryGold,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: _buildOutlinedButton(
                  icon: Icons.history,
                  label: 'History',
                  color: AppTheme.secondaryOrange,
                  onPressed: () => _showStockHistoryDialog(offer),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: _buildOutlinedButton(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  color: AppTheme.errorRed,
                  onPressed: () => _confirmDelete(offer.id, offer.title),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
        const Text(': ', style: TextStyle(color: Colors.grey)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDateRow(ProductModel offer) {
    String dateStr = '-';
    if (offer.loadingFrom != null && offer.loadingTo != null) {
      dateStr = '${offer.loadingFrom} → ${offer.loadingTo}';
    } else if (offer.createdAt != null) {
      dateStr = offer.createdAt.toString().split(' ').first; // Just fallback
    }

    return _buildAttributeRow(Icons.calendar_today_outlined, 'Date', dateStr);
  }

  Widget _buildPastelBox({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color bgColor,
    required Color fgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: fgColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: fgColor.withOpacity(0.8), fontSize: 11),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: fgColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (unit.isNotEmpty)
                  Text(
                    unit,
                    style: TextStyle(color: fgColor.withOpacity(0.8), fontSize: 10),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = AppTheme.successGreen;
    if (status.toLowerCase().contains('out_of_stock')) {
      color = Colors.grey;
    } else if (status.toLowerCase().contains('active') || status.toLowerCase().contains('available')) {
      color = AppTheme.successGreen; // Bright green
    } else {
      color = AppTheme.secondaryOrange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildOutlinedButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showInterestsDialog(int offerId, String title) {
    showDialog(context: context, builder: (_) => OfferInterestsDialog(offerId: offerId.toString(), offerTitle: title));
  }

  void _showStockHistoryDialog(ProductModel offer) {
    showDialog(
      context: context,
      builder: (_) => StockHistoryDialog(
        productId: offer.id.toString(),
        productTitle: offer.title,
        sellerName: offer.seller?.username ?? '-',
        currentStock: '${offer.availableQuantity} QTL',
      ),
    );
  }

  void _confirmDelete(int offerId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text("Delete Offer", style: TextStyle(color: Colors.white)),
        content: Text("Are you sure you want to delete '$title'?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              controller.deleteOffer(offerId);
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}

class _ManageStockRow extends StatefulWidget {
  const _ManageStockRow({
    required this.offerId,
    required this.initialPackingKg,
    required this.onSave,
  });

  final int offerId;
  final double initialPackingKg;
  final void Function(String action, String quantity, String bags, String packingKg) onSave;

  @override
  State<_ManageStockRow> createState() => _ManageStockRowState();
}

class _ManageStockRowState extends State<_ManageStockRow> {
  String _action = 'Remove';
  final _quantityCtrl = TextEditingController();
  final _bagsCtrl = TextEditingController();
  final _packingKgCtrl = TextEditingController();
  bool _isExpanded = false; // Initially expanded in image? Let's make it expandable but true by default for now.

  @override
  void initState() {
    super.initState();
    _isExpanded = true; 
    if (widget.initialPackingKg > 0) {
      final val = widget.initialPackingKg;
      _packingKgCtrl.text = val == val.toInt() ? val.toInt().toString() : val.toString();
    }
  }

  void _syncBagsFromQuantity(String val) {
    final qty = double.tryParse(val) ?? 0;
    final pKg = double.tryParse(_packingKgCtrl.text) ?? 0;
    if (qty > 0 && pKg > 0) {
      final totalKg = qty * 100;
      final bags = (totalKg / pKg).round();
      _bagsCtrl.text = bags.toString();
    } else {
      _bagsCtrl.clear();
    }
  }

  void _syncQuantityFromBags(String val) {
    final bags = double.tryParse(val) ?? 0;
    final pKg = double.tryParse(_packingKgCtrl.text) ?? 0;
    if (bags > 0 && pKg > 0) {
      final totalKg = bags * pKg;
      final qty = totalKg / 100;
      _quantityCtrl.text = qty.toStringAsFixed(3);
    } else {
      _quantityCtrl.clear();
    }
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _bagsCtrl.dispose();
    _packingKgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary, // Slightly darker than card
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text('Manage Stock', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const Spacer(),
                  Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
          
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Column(
                children: [
                  // Form Fields
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Action Dropdown
                      Expanded(
                        flex: 3,
                        child: _buildLabeledWidget('Action', 
                          Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.cardColor,
                              border: Border.all(color: AppTheme.borderColor),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _action,
                                dropdownColor: AppTheme.cardColor,
                                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                                isExpanded: true,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                items: const [
                                  DropdownMenuItem(value: 'Add', child: Text('Add')),
                                  DropdownMenuItem(value: 'Remove', child: Text('Remove')),
                                ],
                                onChanged: (v) {
                                  if (v != null) setState(() => _action = v);
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Qty Field
                      Expanded(
                        flex: 3,
                        child: _buildLabeledWidget('Qty (QTL)', 
                          _buildTextField('Enter qty', _quantityCtrl, _syncBagsFromQuantity),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Bags Field
                      Expanded(
                        flex: 3,
                        child: _buildLabeledWidget('Bags', 
                          _buildTextField('Enter bags', _bagsCtrl, _syncQuantityFromBags, isHighlight: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Pkg KG & Submit
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 70,
                        child: _buildLabeledWidget('Pkg KG', 
                          _buildTextField('KG', _packingKgCtrl, (v) {
                            if (_quantityCtrl.text.isNotEmpty) _syncBagsFromQuantity(_quantityCtrl.text);
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor,
                          border: Border.all(color: AppTheme.borderColor),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.file_download_outlined, color: AppTheme.primaryGold, size: 18),
                          onPressed: () {}, // Sync or download action
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Full width submit button
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: FilledButton.icon(
                      onPressed: () {
                        widget.onSave(_action, _quantityCtrl.text, _bagsCtrl.text, _packingKgCtrl.text);
                        _quantityCtrl.clear();
                        _bagsCtrl.clear();
                        _packingKgCtrl.clear();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryGold, // Blue 500
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.send_outlined, size: 16),
                      label: const Text('Submit', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLabeledWidget(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, void Function(String) onChanged, {bool isHighlight = false}) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          filled: true,
          fillColor: AppTheme.cardColor,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: isHighlight ? AppTheme.primaryGold.withValues(alpha: 0.5) : AppTheme.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: isHighlight ? AppTheme.primaryGold : AppTheme.secondaryOrange),
          ),
        ),
      ),
    );
  }
}
