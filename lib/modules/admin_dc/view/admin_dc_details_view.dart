import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../theme/app_theme.dart';
import '../controller/admin_dc_details_controller.dart';
import '../model/admin_challan_model.dart';

class AdminChallanDetailsView extends StatelessWidget {
  const AdminChallanDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminDCDetailsController());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Delivery Challan Slip",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            tooltip: "Refresh Details",
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              if (controller.challanId.value > 0) {
                controller.fetchDetails(controller.challanId.value, isRefresh: true);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: _buildBottomActionBar(context, controller, isDark),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: RefreshIndicator(
                color: AppTheme.primaryGold,
                onRefresh: () async {
                  if (controller.challanId.value > 0) {
                    await controller.fetchDetails(controller.challanId.value, isRefresh: true);
                  }
                },
                child: Obx(() {
                  if (controller.isLoading.value && controller.challan.value == null) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryGold),
                    );
                  }

                  final challan = controller.challan.value;
                  if (challan == null) {
                    return _buildErrorState(context, controller, isDark);
                  }

                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Status Banner ──────────────────────────────────
                        _buildStatusBanner(challan, isDark),
                        const SizedBox(height: 16),

                        // ── Challan Meta Card ──────────────────────────────
                        _buildChallanMetaCard(context, challan, isDark),
                        const SizedBox(height: 16),

                        // ── Parties Route Card ─────────────────────────────
                        _buildPartiesRouteCard(context, challan, isDark),
                        const SizedBox(height: 16),

                        // ── Commodity & Product Items ──────────────────────
                        _buildItemsSection(context, challan, isDark),
                        const SizedBox(height: 16),

                        // ── Transport & Driver Info ────────────────────────
                        _buildTransportCard(context, challan, isDark),
                        const SizedBox(height: 16),

                        // ── Remarks / Instructions ────────────────────────
                        if (challan.narration != null && challan.narration!.isNotEmpty)
                          _buildRemarksCard(context, challan, isDark),
                      ],
                    ),
                  );
                }),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Status Banner ────────────────────────────────────────────────────────
  Widget _buildStatusBanner(AdminChallanModel challan, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? challan.statusColor.withOpacity(0.18) : challan.statusBgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: challan.statusColor.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: challan.statusColor.withOpacity(0.2),
            ),
            child: Icon(Icons.local_shipping_rounded, color: challan.statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "STATUS: ${challan.statusTitle.toUpperCase()}",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: challan.statusColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getStatusSubtitle(challan.status),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusSubtitle(String? status) {
    final s = (status ?? 'pending').toLowerCase();
    switch (s) {
      case 'dispatched':
      case 'in_transit':
        return "Goods are dispatched and currently in transit to destination.";
      case 'delivered':
      case 'received':
        return "Goods have reached destination and delivery is completed.";
      case 'cancelled':
        return "This delivery challan has been cancelled.";
      case 'pending':
      default:
        return "Challan generated. Awaiting vehicle loading and dispatch.";
    }
  }

  // ── Challan Meta Info ────────────────────────────────────────────────────
  Widget _buildChallanMetaCard(
    BuildContext context,
    AdminChallanModel challan,
    bool isDark,
  ) {
    return _card(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                challan.displayChallanNo,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppTheme.primaryGold,
                ),
              ),
              if (challan.challanDate != null || challan.createdAt != null)
                Text(
                  _formatDate(challan.challanDate ?? challan.createdAt),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
            ],
          ),
          const Divider(height: 18),
          if (challan.orderId != null)
            _metaRow("Associated Contract / Order ID", "#${challan.orderId}", isDark),
          if (challan.dispatchedAt != null)
            _metaRow("Dispatched At", _formatDate(challan.dispatchedAt), isDark),
          if (challan.receivedAt != null)
            _metaRow("Delivered / Received At", _formatDate(challan.receivedAt), isDark),
        ],
      ),
    );
  }

  // ── Parties Route Card ───────────────────────────────────────────────────
  Widget _buildPartiesRouteCard(
    BuildContext context,
    AdminChallanModel challan,
    bool isDark,
  ) {
    return _card(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Consignor & Consignee Details",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const Divider(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "DISPATCHED FROM (SELLER)",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryGold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      challan.displaySeller,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    if (challan.sellerAddress != null && challan.sellerAddress!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        challan.sellerAddress!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Icon(Icons.arrow_forward_rounded, color: AppTheme.primaryGold, size: 20),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "DELIVER TO (BUYER)",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      challan.displayBuyer,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    if (challan.buyerAddress != null && challan.buyerAddress!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        challan.buyerAddress!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Items & Commodity Breakdown ──────────────────────────────────────────
  Widget _buildItemsSection(
    BuildContext context,
    AdminChallanModel challan,
    bool isDark,
  ) {
    return _card(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Commodity & Quantity",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  challan.displayQuantity,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: AppTheme.primaryGold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 18),
          if (challan.items.isNotEmpty) ...[
            ...challan.items.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161D2B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        if (item.bagCount > 0)
                          Text(
                            "${item.bagCount} Bags",
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      "${item.quantity} ${item.unit}",
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ],
                ),
              );
            }),
          ] else ...[
            _metaRow("Commodity", challan.displayCommodity, isDark),
            _metaRow("Total Weight", challan.displayQuantity, isDark),
            if (challan.displayBagCount > 0)
              _metaRow("Total Bags", "${challan.displayBagCount} Bags", isDark),
          ],
        ],
      ),
    );
  }

  // ── Transport & Driver Info ──────────────────────────────────────────────
  Widget _buildTransportCard(
    BuildContext context,
    AdminChallanModel challan,
    bool isDark,
  ) {
    return _card(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Transport & Driver Information",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const Divider(height: 18),
          _metaRow("Vehicle / Truck No.", challan.displayTruck, isDark),
          _metaRow("Driver Name", challan.displayDriver, isDark),
          if (challan.driverMobile != null && challan.driverMobile!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Driver Phone",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                InkWell(
                  onTap: () => _callNumber(challan.driverMobile!),
                  child: Row(
                    children: [
                      const Icon(IconlyLight.call, color: AppTheme.primaryGold, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        challan.driverMobile!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppTheme.primaryGold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          if (challan.transporterNameDisplay != null && challan.transporterNameDisplay!.isNotEmpty)
            _metaRow("Transporter", challan.transporterNameDisplay!, isDark),
        ],
      ),
    );
  }

  // ── Remarks Card ─────────────────────────────────────────────────────────
  Widget _buildRemarksCard(
    BuildContext context,
    AdminChallanModel challan,
    bool isDark,
  ) {
    return _card(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Special Instructions / Remarks",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const Divider(height: 18),
          Text(
            challan.narration!,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFFC7CEDB) : const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Action Bar (Dispatch Button) ───────────────────────────────────
  Widget _buildBottomActionBar(
    BuildContext context,
    AdminDCDetailsController controller,
    bool isDark,
  ) {
    return Obx(() {
      final challan = controller.challan.value;
      if (challan == null) return const SizedBox.shrink();

      // Backend statuses: draft, dispatched, delivered, cancelled.
      final status = (challan.status ?? 'draft').toLowerCase();
      final isDraft = status == 'draft' || status == 'pending';
      final isDispatched = status == 'dispatched' || status == 'in_transit';
      final busy = controller.isDispatching.value || controller.isWorking.value;

      final barBg = isDark ? const Color(0xFF1E2638) : Colors.white;
      final borderColor = isDark ? const Color(0xFF2C394F) : const Color(0xFFE2E8F0);

      Widget primary(String label, IconData icon, Color color, VoidCallback onPressed) => SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: busy ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: busy
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                      ],
                    ),
            ),
          );

      Widget secondary(String label, IconData icon, Color color, VoidCallback onPressed) => Expanded(
            child: OutlinedButton.icon(
              onPressed: busy ? null : onPressed,
              icon: Icon(icon, size: 18, color: color),
              label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          );

      final Widget content;
      if (isDraft) {
        content = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              secondary('Edit', Icons.edit_outlined, const Color(0xFF2563EB), () => _showEditSheet(context, controller)),
              const SizedBox(width: 8),
              secondary('Cancel', Icons.block, const Color(0xFFD97706), () => _confirm(
                    context,
                    title: 'Cancel Challan',
                    message: 'Cancel this draft challan? Its truck and driver become free again.',
                    confirmText: 'Cancel Challan',
                    onConfirm: () => controller.runAction('cancel'),
                  )),
              const SizedBox(width: 8),
              secondary('Delete', Icons.delete_outline, const Color(0xFFDC2626), () => _confirm(
                    context,
                    title: 'Delete Challan',
                    message: 'Delete this draft challan permanently?',
                    confirmText: 'Delete',
                    onConfirm: controller.deleteChallan,
                  )),
            ]),
            const SizedBox(height: 10),
            primary('MARK AS DISPATCHED', Icons.send_rounded, const Color(0xFF2563EB), () => _confirmDispatch(context, controller)),
          ],
        );
      } else if (isDispatched) {
        content = primary('MARK AS DELIVERED', Icons.task_alt_rounded, const Color(0xFF059669), () => _confirm(
              context,
              title: 'Mark Delivered',
              message: 'Confirm the goods reached the buyer?',
              confirmText: 'Mark Delivered',
              onConfirm: () => controller.runAction('deliver'),
            ));
      } else {
        final cancelled = status == 'cancelled';
        content = Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(cancelled ? Icons.block : Icons.check_circle, color: challan.statusColor, size: 20),
              const SizedBox(width: 8),
              Text(
                cancelled ? 'This challan was cancelled' : 'Shipment Completed & Delivered',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: challan.statusColor),
              ),
            ],
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        decoration: BoxDecoration(color: barBg, border: Border(top: BorderSide(color: borderColor))),
        child: content,
      );
    });
  }

  void _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmText,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Back')),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onConfirm();
            },
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  /// Draft edit: the same fields the web edit form sends to PATCH .../manage/.
  void _showEditSheet(BuildContext context, AdminDCDetailsController controller) {
    final data = controller.rawData.value ?? const <String, dynamic>{};
    final items = data['items'] is List ? data['items'] as List : const [];
    final firstItem = items.isNotEmpty && items.first is Map ? items.first as Map : const {};
    String text(Object? value) => value == null ? '' : value.toString();
    final fields = <String, TextEditingController>{
      'truck_number': TextEditingController(text: text(data['truck_number'])),
      'driver_name': TextEditingController(text: text(data['driver_name'])),
      'driver_phone': TextEditingController(text: text(data['driver_mobile'])),
      'driver_license': TextEditingController(text: text(data['driver_license_number'])),
      'bag_count': TextEditingController(text: text(firstItem['bag_count'])),
      'lorry_freight_per_bag': TextEditingController(text: text(data['lorry_freight_per_bag'])),
      'loading_charges': TextEditingController(text: text(data['loading_charges'])),
      'other_exp': TextEditingController(text: text(data['other_exp'])),
      'less_advance': TextEditingController(text: text(data['less_advance'])),
      'remarks': TextEditingController(text: text(data['narration'])),
    };
    const labels = {
      'truck_number': 'Truck number',
      'driver_name': 'Driver name',
      'driver_phone': 'Driver mobile',
      'driver_license': 'Driver license',
      'bag_count': 'Bags',
      'lorry_freight_per_bag': 'Lorry freight per bag',
      'loading_charges': 'Loading charges',
      'other_exp': 'Other expenses',
      'less_advance': 'Less advance',
      'remarks': 'Remarks / narration',
    };
    const numeric = {'driver_phone', 'bag_count', 'lorry_freight_per_bag', 'loading_charges', 'other_exp', 'less_advance'};
    final original = {for (final e in fields.entries) e.key: e.value.text};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(sheetContext).bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Edit Draft Challan', style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              for (final entry in fields.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: entry.value,
                    maxLines: entry.key == 'remarks' ? 2 : 1,
                    keyboardType: numeric.contains(entry.key)
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.text,
                    maxLength: numeric.contains(entry.key) ? 10 : null,
                    decoration: InputDecoration(labelText: labels[entry.key], border: const OutlineInputBorder()),
                  ),
                ),
              Obx(() => FilledButton(
                    onPressed: controller.isWorking.value
                        ? null
                        : () async {
                            // Only changed fields are sent.
                            final body = <String, dynamic>{
                              for (final e in fields.entries)
                                if (e.value.text.trim() != original[e.key]!.trim()) e.key: e.value.text.trim(),
                            };
                            if (body.isEmpty) {
                              Navigator.pop(sheetContext);
                              return;
                            }
                            final saved = await controller.saveEdit(body);
                            if (saved && sheetContext.mounted) Navigator.pop(sheetContext);
                          },
                    child: const Text('Save changes'),
                  )),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      for (final c in fields.values) {
        c.dispose();
      }
    });
  }

  void _confirmDispatch(BuildContext context, AdminDCDetailsController controller) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Dispatch"),
          content: const Text(
            "Are you sure you want to mark this shipment as Dispatched? The status will update to In-Transit.",
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(context);
                controller.dispatchShipment();
              },
              child: const Text("Yes, Dispatch", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _callNumber(String phone) async {
    final uri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // ── Helper UI Methods ────────────────────────────────────────────────────
  Widget _card(bool isDark, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2638) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2C394F) : const Color(0xFFE2E8F0),
        ),
      ),
      child: child,
    );
  }

  Widget _metaRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    AdminDCDetailsController controller,
    bool isDark,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 54, color: Color(0xFFDC2626)),
            const SizedBox(height: 16),
            const Text(
              "Challan Details Not Found",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              "Could not retrieve details for this Delivery Challan.",
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => Get.back(),
              child: const Text("Go Back"),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return "";
    try {
      final parsed = DateTime.parse(raw);
      return "${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}";
    } catch (_) {
      return raw.split('T').first;
    }
  }
}
