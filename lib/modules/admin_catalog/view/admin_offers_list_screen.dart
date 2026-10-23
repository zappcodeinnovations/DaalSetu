import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:daalsetu/modules/products/model/product_model.dart';
import 'package:daalsetu/modules/admin_catalog/controller/admin_offers_controller.dart';
import 'package:daalsetu/modules/admin_catalog/view/offer_interests_dialog.dart';
import 'package:daalsetu/modules/admin_catalog/view/stock_history_dialog.dart';
import 'package:daalsetu/widgets/authenticated_network_image.dart';
import 'package:daalsetu/theme/app_theme.dart';
import 'package:daalsetu/modules/products/view/edit_product.dart';
import 'package:daalsetu/widgets/app_shell.dart';

class AdminOffersListScreen extends StatefulWidget {
  const AdminOffersListScreen({super.key});

  @override
  State<AdminOffersListScreen> createState() => _AdminOffersListScreenState();
}

class _AdminOffersListScreenState extends State<AdminOffersListScreen> {
  final AdminOffersController controller = Get.put(AdminOffersController());

  // Dynamic theme-adaptive colors
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get bgColor => isDark ? AppTheme.bgDarkNavy : AppTheme.bgLight;
  Color get cardColor => isDark ? AppTheme.cardColor : AppTheme.cardLight;
  Color get borderColor => isDark ? AppTheme.borderColor : AppTheme.borderLight;
  Color get textPrimary => isDark ? AppTheme.textPrimary : AppTheme.textPrimaryLight;
  Color get textSecondary => isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLight;
  Color get textMuted => isDark ? AppTheme.textMuted : AppTheme.textMutedLight;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(leading: const AppBarLeading(), leadingWidth: AppBarLeading.widthFor(context), 
        title: Text(
          'Admin Offers',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: bgColor,
        iconTheme: IconThemeData(color: textPrimary),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: textPrimary),
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
          return Center(
            child: Text(
              "No offers found",
              style: TextStyle(color: textSecondary),
            ),
          );
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
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${offer.category?.name ?? ''} • ${offer.brand?.name ?? ''}',
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondary,
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
                      color: isDark ? Colors.black26 : Colors.grey.shade200,
                      child: Icon(Icons.broken_image, color: textMuted),
                    ),
                  ),
                )
              else
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.image_outlined, color: textMuted),
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
                  bgColor: AppTheme.successGreen.withValues(alpha: 0.15),
                  fgColor: AppTheme.successGreen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPastelBox(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Bags',
                  value: offer.originalBagCount?.toString() ?? '-',
                  unit: '',
                  bgColor: AppTheme.secondaryOrange.withValues(alpha: 0.15),
                  fgColor: AppTheme.secondaryOrange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPastelBox(
                  icon: Icons.hourglass_empty,
                  label: 'Quantity',
                  value: offer.availableQuantity.toString(),
                  unit: 'QTL',
                  bgColor: AppTheme.primaryGold.withValues(alpha: 0.15),
                  fgColor: AppTheme.primaryGold,
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
              Text('Visible', style: TextStyle(color: textSecondary, fontSize: 13)),
              const SizedBox(width: 4),
              SizedBox(
                height: 24,
                width: 40,
                child: FittedBox(
                  fit: BoxFit.fill,
                  child: Switch(
                    value: offer.isActive,
                    onChanged: (val) => controller.toggleVisibility(offer.id, offer.isActive),
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppTheme.successGreen,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: isDark ? AppTheme.borderColor : Colors.grey.shade400,
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
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite, color: Colors.redAccent, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${offer.interestCount}',
                        style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
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
            initialPackingKg: (double.tryParse(offer.packingWeightKg) ?? 0) > 0
                ? (double.tryParse(offer.packingWeightKg) ?? 0)
                : ((offer.originalBagCount != null &&
                        offer.originalBagCount! > 0 &&
                        (double.tryParse(offer.availableQuantity) ?? 0) > 0)
                    ? ((double.tryParse(offer.availableQuantity) ?? 0) * 100) /
                        offer.originalBagCount!
                    : 50.0),
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

          // Bottom Action Buttons (Responsive 2-Tier Layout)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _showInterestsDialog(offer.id, offer.title),
              icon: const Icon(Icons.handshake, size: 18),
              label: Text(
                'Manage Bids (${offer.interestCount})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildOutlinedButton(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  color: AppTheme.primaryGold,
                  onPressed: () async {
                    final saved = await Get.to(() => EditProductScreen(product: offer));
                    if (saved == true) controller.fetchOffers();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildOutlinedButton(
                  icon: Icons.history,
                  label: 'History',
                  color: AppTheme.secondaryOrange,
                  onPressed: () => _showStockHistoryDialog(offer),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
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
        Icon(icon, size: 16, color: textSecondary),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(color: textSecondary, fontSize: 13),
          ),
        ),
        Text(': ', style: TextStyle(color: textSecondary)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDateRow(ProductModel offer) {
    String dateStr = '-';
    if (offer.loadingFrom.isNotEmpty && offer.loadingTo.isNotEmpty) {
      dateStr = '${offer.loadingFrom} → ${offer.loadingTo}';
    } else if (offer.createdAt.toString().isNotEmpty) {
      dateStr = offer.createdAt.toString().split(' ').first;
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
            decoration: BoxDecoration(
              color: isDark ? cardColor : Colors.white,
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
                  style: TextStyle(color: fgColor.withValues(alpha: 0.8), fontSize: 11),
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
                    style: TextStyle(color: fgColor.withValues(alpha: 0.8), fontSize: 10),
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
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
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
        title: Text("Delete Offer", style: TextStyle(color: textPrimary)),
        content: Text("Are you sure you want to delete '$title'?", style: TextStyle(color: textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: textSecondary)),
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
  bool _isExpanded = false;

  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get bgSubCard => isDark ? AppTheme.bgSecondary : const Color(0xFFF1F5F9);
  Color get fieldBg => isDark ? AppTheme.cardColor : Colors.white;
  Color get borderColor => isDark ? AppTheme.borderColor : AppTheme.borderLight;
  Color get textPrimary => isDark ? AppTheme.textPrimary : AppTheme.textPrimaryLight;
  Color get textSecondary => isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLight;

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
    var pKg = double.tryParse(_packingKgCtrl.text) ?? 0;
    if (pKg <= 0) {
      final defaultKg = widget.initialPackingKg > 0 ? widget.initialPackingKg : 50.0;
      _packingKgCtrl.text = defaultKg == defaultKg.toInt() ? defaultKg.toInt().toString() : defaultKg.toString();
      pKg = defaultKg;
    }
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
    var pKg = double.tryParse(_packingKgCtrl.text) ?? 0;
    if (pKg <= 0) {
      final defaultKg = widget.initialPackingKg > 0 ? widget.initialPackingKg : 50.0;
      _packingKgCtrl.text = defaultKg == defaultKg.toInt() ? defaultKg.toInt().toString() : defaultKg.toString();
      pKg = defaultKg;
    }
    if (bags > 0 && pKg > 0) {
      final totalKg = bags * pKg;
      final qty = totalKg / 100;
      _quantityCtrl.text = qty.toStringAsFixed(3);
    } else {
      _quantityCtrl.clear();
    }
  }

  void _onRefreshOrRecalculate() {
    var pKg = double.tryParse(_packingKgCtrl.text.trim()) ?? 0;
    if (pKg <= 0) {
      final defaultKg = widget.initialPackingKg > 0 ? widget.initialPackingKg : 50.0;
      _packingKgCtrl.text = defaultKg == defaultKg.toInt()
          ? defaultKg.toInt().toString()
          : defaultKg.toString();
      pKg = defaultKg;
    }

    if (_quantityCtrl.text.trim().isNotEmpty) {
      _syncBagsFromQuantity(_quantityCtrl.text.trim());
    } else if (_bagsCtrl.text.trim().isNotEmpty) {
      _syncQuantityFromBags(_bagsCtrl.text.trim());
    } else {
      final defaultKg = widget.initialPackingKg > 0 ? widget.initialPackingKg : 50.0;
      _packingKgCtrl.text = defaultKg == defaultKg.toInt()
          ? defaultKg.toInt().toString()
          : defaultKg.toString();
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
        color: bgSubCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
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
                  Icon(Icons.inventory_2_outlined, color: textPrimary, size: 20),
                  const SizedBox(width: 8),
                  Text('Manage Stock', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                  const Spacer(),
                  Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: textPrimary, size: 20),
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
                              color: fieldBg,
                              border: Border.all(color: borderColor),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _action,
                                dropdownColor: fieldBg,
                                icon: Icon(Icons.keyboard_arrow_down, color: textPrimary),
                                isExpanded: true,
                                style: TextStyle(color: textPrimary, fontSize: 13),
                                items: [
                                  DropdownMenuItem(value: 'Add', child: Text('Add', style: TextStyle(color: textPrimary))),
                                  DropdownMenuItem(value: 'Remove', child: Text('Remove', style: TextStyle(color: textPrimary))),
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
                          color: fieldBg,
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: IconButton(
                          tooltip: 'Recalculate Bags & Qty',
                          icon: const Icon(Icons.sync_rounded, color: AppTheme.primaryGold, size: 18),
                          onPressed: _onRefreshOrRecalculate,
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
                        backgroundColor: AppTheme.primaryGold,
                        foregroundColor: Colors.white,
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
        Text(label, style: TextStyle(color: textSecondary, fontSize: 11)),
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
        maxLength: 10,
        onChanged: onChanged,
        style: TextStyle(color: textPrimary, fontSize: 13),
        decoration: InputDecoration(
          counterText: '',
          hintText: hint,
          hintStyle: TextStyle(color: textSecondary, fontSize: 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          filled: true,
          fillColor: fieldBg,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: isHighlight ? AppTheme.primaryGold.withValues(alpha: 0.5) : borderColor),
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
