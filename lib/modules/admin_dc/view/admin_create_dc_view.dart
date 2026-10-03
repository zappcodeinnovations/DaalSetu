import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../../../theme/app_theme.dart';
import '../../contracts/model/contract_model.dart';
import '../controller/admin_create_dc_controller.dart';

class AdminCreateChallanView extends StatelessWidget {
  const AdminCreateChallanView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminCreateDCController());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Create Delivery Challan",
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      bottomNavigationBar: _buildBottomSubmitBar(context, controller, isDark),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 650;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: RefreshIndicator(
                color: AppTheme.primaryGold,
                onRefresh: () => controller.fetchContracts(isRefresh: true),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Section 1: Contract Selection ────────────────────
                      _buildSectionTitle(context, "1. Select Confirmed Deal", IconlyLight.document),
                      const SizedBox(height: 10),
                      _buildContractSelector(context, controller, isDark),

                      const SizedBox(height: 24),

                      // ── Section 2: Commodity & Quantity ──────────────────
                      _buildSectionTitle(context, "2. Goods & Quantity", Icons.inventory_2_outlined),
                      const SizedBox(height: 10),
                      _buildGoodsSection(context, controller, isDark, isTablet),

                      const SizedBox(height: 24),

                      // ── Section 3: Logistics & Vehicle ───────────────────
                      _buildSectionTitle(context, "3. Logistics & Vehicle Details", Icons.local_shipping_outlined),
                      const SizedBox(height: 10),
                      _buildLogisticsSection(context, controller, isDark, isTablet),

                      const SizedBox(height: 24),

                      // ── Section 4: Schedule & Route ──────────────────────
                      _buildSectionTitle(context, "4. Schedule & Route", IconlyLight.calendar),
                      const SizedBox(height: 10),
                      _buildRouteSection(context, controller, isDark, isTablet),

                      const SizedBox(height: 24),

                      // ── Section 5: Remarks / Instructions ────────────────
                      _buildSectionTitle(context, "5. Remarks & Instructions", IconlyLight.chat),
                      const SizedBox(height: 10),
                      _buildRemarksSection(context, controller, isDark),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Section Header ───────────────────────────────────────────────────────
  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryGold),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
        ),
      ],
    );
  }

  // ── Contract Selector Card ───────────────────────────────────────────────
  Widget _buildContractSelector(
    BuildContext context,
    AdminCreateDCController controller,
    bool isDark,
  ) {
    final cardBg = isDark ? const Color(0xFF1E2638) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2C394F) : const Color(0xFFE2E8F0);

    return Obx(() {
      final contract = controller.selectedContract.value;

      if (contract == null) {
        return InkWell(
          onTap: () => _openContractPickerSheet(context, controller, isDark),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1.3),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(IconlyLight.paper, color: AppTheme.primaryGold, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Tap to Select Contract / Deal",
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        controller.isLoadingContracts.value
                            ? "Loading confirmed contracts..."
                            : "Auto-fills seller, buyer, commodity & route",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              ],
            ),
          ),
        );
      }

      // Selected Contract Summary Card
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryGold, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF059669), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      "Contract #${contract.contractId}",
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => _openContractPickerSheet(context, controller, isDark),
                  child: const Text("Change", style: TextStyle(color: AppTheme.primaryGold)),
                ),
              ],
            ),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _infoRow("Commodity", contract.productTitle, isDark),
            _infoRow("Seller", contract.displaySellerId.isNotEmpty ? contract.displaySellerId : contract.sellerName, isDark),
            _infoRow("Buyer", contract.displayBuyerId.isNotEmpty ? contract.displayBuyerId : contract.buyerName, isDark),
            _infoRow("Deal Quantity", "${contract.dealQuantity} ${contract.quantityUnit}", isDark),
            _infoRow("Rate / Amount", "₹${contract.dealAmount} / ${contract.amountUnit}", isDark),
          ],
        ),
      );
    });
  }

  // ── Goods Section ────────────────────────────────────────────────────────
  Widget _buildGoodsSection(
    BuildContext context,
    AdminCreateDCController controller,
    bool isDark,
    bool isTablet,
  ) {
    return _cardContainer(
      isDark,
      child: Column(
        children: [
          if (isTablet)
            Row(
              children: [
                Expanded(
                  child: _textField(
                    controller: controller.quantityController,
                    label: "Quantity to Dispatch",
                    hint: "e.g. 250",
                    icon: Icons.scale_outlined,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _textField(
                    controller: controller.bagCountController,
                    label: "Total Bags (Bori)",
                    hint: "e.g. 500",
                    icon: Icons.inventory_2_outlined,
                    keyboardType: TextInputType.number,
                    isDark: isDark,
                  ),
                ),
              ],
            )
          else ...[
            _textField(
              controller: controller.quantityController,
              label: "Quantity to Dispatch",
              hint: "e.g. 250",
              icon: Icons.scale_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              isDark: isDark,
            ),
            const SizedBox(height: 14),
            _textField(
              controller: controller.bagCountController,
              label: "Total Bags (Bori)",
              hint: "e.g. 500",
              icon: Icons.inventory_2_outlined,
              keyboardType: TextInputType.number,
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  // ── Logistics & Vehicle Section ──────────────────────────────────────────
  Widget _buildLogisticsSection(
    BuildContext context,
    AdminCreateDCController controller,
    bool isDark,
    bool isTablet,
  ) {
    return _cardContainer(
      isDark,
      child: Column(
        children: [
          _textField(
            controller: controller.truckNumberController,
            label: "Truck / Vehicle Number *",
            hint: "e.g. MP 04 GA 1234",
            icon: Icons.local_shipping_outlined,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          if (isTablet)
            Row(
              children: [
                Expanded(
                  child: _textField(
                    controller: controller.driverNameController,
                    label: "Driver Name *",
                    hint: "e.g. Ramesh Kumar",
                    icon: IconlyLight.user,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _textField(
                    controller: controller.driverPhoneController,
                    label: "Driver Mobile Number",
                    hint: "e.g. 9876543210",
                    icon: IconlyLight.call,
                    keyboardType: TextInputType.phone,
                    isDark: isDark,
                  ),
                ),
              ],
            )
          else ...[
            _textField(
              controller: controller.driverNameController,
              label: "Driver Name *",
              hint: "e.g. Ramesh Kumar",
              icon: IconlyLight.user,
              isDark: isDark,
            ),
            const SizedBox(height: 14),
            _textField(
              controller: controller.driverPhoneController,
              label: "Driver Mobile Number",
              hint: "e.g. 9876543210",
              icon: IconlyLight.call,
              keyboardType: TextInputType.phone,
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  // ── Schedule & Route Section ─────────────────────────────────────────────
  Widget _buildRouteSection(
    BuildContext context,
    AdminCreateDCController controller,
    bool isDark,
    bool isTablet,
  ) {
    return _cardContainer(
      isDark,
      child: Column(
        children: [
          // Date Picker Field
          InkWell(
            onTap: () => controller.pickDispatchDate(context),
            child: IgnorePointer(
              child: _textField(
                controller: controller.dispatchDateController,
                label: "Dispatch Date",
                hint: "YYYY-MM-DD",
                icon: IconlyLight.calendar,
                isDark: isDark,
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (isTablet)
            Row(
              children: [
                Expanded(
                  child: _textField(
                    controller: controller.loadingFromController,
                    label: "Loading From (Origin)",
                    hint: "e.g. Bhopal Mandi",
                    icon: Icons.location_on_outlined,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _textField(
                    controller: controller.loadingToController,
                    label: "Loading To (Destination)",
                    hint: "e.g. Nagpur Warehouse",
                    icon: Icons.flag_outlined,
                    isDark: isDark,
                  ),
                ),
              ],
            )
          else ...[
            _textField(
              controller: controller.loadingFromController,
              label: "Loading From (Origin)",
              hint: "e.g. Bhopal Mandi",
              icon: Icons.location_on_outlined,
              isDark: isDark,
            ),
            const SizedBox(height: 14),
            _textField(
              controller: controller.loadingToController,
              label: "Loading To (Destination)",
              hint: "e.g. Nagpur Warehouse",
              icon: Icons.flag_outlined,
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  // ── Remarks Section ──────────────────────────────────────────────────────
  Widget _buildRemarksSection(
    BuildContext context,
    AdminCreateDCController controller,
    bool isDark,
  ) {
    return _cardContainer(
      isDark,
      child: _textField(
        controller: controller.remarksController,
        label: "Special Instructions / Remarks",
        hint: "e.g. Handle with care, check moisture certificate before unloading...",
        icon: IconlyLight.chat,
        maxLines: 3,
        isDark: isDark,
      ),
    );
  }

  // ── Bottom Submit Bar ────────────────────────────────────────────────────
  Widget _buildBottomSubmitBar(
    BuildContext context,
    AdminCreateDCController controller,
    bool isDark,
  ) {
    final barBg = isDark ? const Color(0xFF1E2638) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2C394F) : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: BoxDecoration(
        color: barBg,
        border: Border(top: BorderSide(color: borderColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Obx(() {
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: controller.isSubmitting.value
                ? null
                : controller.submitDeliveryChallan,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGold,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: controller.isSubmitting.value
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.black, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "Generate Delivery Challan",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      }),
    );
  }

  // ── Contract Picker BottomSheet ──────────────────────────────────────────
  void _openContractPickerSheet(
    BuildContext context,
    AdminCreateDCController controller,
    bool isDark,
  ) {
    // Automatically fetch latest contracts from backend when opening
    controller.fetchContracts();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E2638) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Select Confirmed Contract",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  IconButton(
                    tooltip: "Refresh Contracts",
                    icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryGold),
                    onPressed: () => controller.fetchContracts(isRefresh: true),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Search in contracts
              TextField(
                onChanged: controller.filterContracts,
                decoration: InputDecoration(
                  hintText: "Search by Contract ID, Daal, Buyer, Seller...",
                  prefixIcon: const Icon(IconlyLight.search, size: 18),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF161D2B) : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Obx(() {
                  if (controller.isLoadingContracts.value) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryGold),
                    );
                  }

                  if (controller.filteredContracts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(IconlyLight.document, size: 48, color: isDark ? Colors.white30 : Colors.grey[400]),
                          const SizedBox(height: 12),
                          const Text("No confirmed contracts found"),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: AppTheme.primaryGold,
                    onRefresh: () => controller.fetchContracts(isRefresh: true),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: controller.filteredContracts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final c = controller.filteredContracts[index];
                        return _contractListTile(context, controller, c, isDark);
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _contractListTile(
    BuildContext context,
    AdminCreateDCController controller,
    ContractModel c,
    bool isDark,
  ) {
    return InkWell(
      onTap: () {
        controller.selectContract(c);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161D2B) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF2C394F) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "#${c.contractId}",
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppTheme.primaryGold,
                  ),
                ),
                Text(
                  "${c.dealQuantity} ${c.quantityUnit}",
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              c.productTitle,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              "${c.sellerName}  ➔  ${c.buyerName}",
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helper UI Components ─────────────────────────────────────────────────
  Widget _cardContainer(bool isDark, {required Widget child}) {
    return Container(
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

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFC7CEDB) : const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161D2B) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF2C394F) : const Color(0xFFE2E8F0),
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
              prefixIcon: Icon(icon, size: 20, color: AppTheme.primaryGold),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value, bool isDark) {
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
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
