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

                      // ── Section 2: Commodity & Items Table ───────────────
                      _buildSectionTitle(context, "2. Items & Quantity (Auto-filled)", Icons.inventory_2_outlined),
                      const SizedBox(height: 10),
                      _buildGoodsSection(context, controller, isDark, isTablet),

                      const SizedBox(height: 24),

                      // ── Section 3: Logistics & Transport Details ─────────
                      _buildSectionTitle(context, "3. Transport & Driver Details (Auto-filled)", Icons.local_shipping_outlined),
                      const SizedBox(height: 10),
                      _buildLogisticsSection(context, controller, isDark, isTablet),

                      const SizedBox(height: 24),

                      // ── Section 4: Schedule & Route ──────────────────────
                      _buildSectionTitle(context, "4. Schedule & Route", IconlyLight.calendar),
                      const SizedBox(height: 10),
                      _buildRouteSection(context, controller, isDark, isTablet),

                      const SizedBox(height: 24),

                      // ── Section 5: Remarks / Instructions ────────────────
                      _buildSectionTitle(context, "5. Remarks & Narration", IconlyLight.chat),
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
                        "Tap to Select Contract / Accepted Bid",
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        controller.isLoadingContracts.value
                            ? "Loading confirmed contracts..."
                            : "Auto-fills bags, packing, driver, vehicle & route",
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
                    if (controller.isLoadingDetail.value) ...[
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGold),
                      ),
                    ],
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
            _infoRow("Deal Rate", "₹${contract.dealAmount} / ${contract.amountUnit}", isDark),
            if (controller.bagCountController.text.isNotEmpty)
              _infoRow("Total Bags", "${controller.bagCountController.text} Bags", isDark),
            if (controller.transporterNameController.text.isNotEmpty)
              _infoRow("Transporter", controller.transporterNameController.text, isDark),
            if (controller.truckNumberController.text.isNotEmpty)
              _infoRow("Truck No.", controller.truckNumberController.text, isDark),
          ],
        ),
      );
    });
  }

  // ── Items & Goods Section (Matching Website Items Table) ─────────────────
  Widget _buildGoodsSection(
    BuildContext context,
    AdminCreateDCController controller,
    bool isDark,
    bool isTablet,
  ) {
    return _cardContainer(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isTablet)
            Row(
              children: [
                Expanded(
                  child: _textField(
                    controller: controller.quantityController,
                    label: "Quantity to Dispatch *",
                    hint: "e.g. 500.100",
                    icon: Icons.scale_outlined,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _textField(
                    controller: controller.bagCountController,
                    label: "Total Bags (Bori) *",
                    hint: "e.g. 1667",
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
              label: "Quantity to Dispatch *",
              hint: "e.g. 500.100",
              icon: Icons.scale_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              isDark: isDark,
            ),
            const SizedBox(height: 14),
            _textField(
              controller: controller.bagCountController,
              label: "Total Bags (Bori) *",
              hint: "e.g. 1667",
              icon: Icons.inventory_2_outlined,
              keyboardType: TextInputType.number,
              isDark: isDark,
            ),
          ],
          const SizedBox(height: 14),
          if (isTablet)
            Row(
              children: [
                Expanded(
                  child: _textField(
                    controller: controller.packingWeightController,
                    label: "Packing Weight (KG)",
                    hint: "e.g. 30.000",
                    icon: Icons.fitness_center_outlined,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _textField(
                    controller: controller.rateController,
                    label: "Rate (₹)",
                    hint: "e.g. 50.00",
                    icon: Icons.currency_rupee_outlined,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _textField(
                    controller: controller.amountController,
                    label: "Total Amount (₹)",
                    hint: "e.g. 25005.00",
                    icon: Icons.calculate_outlined,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    isDark: isDark,
                  ),
                ),
              ],
            )
          else ...[
            _textField(
              controller: controller.packingWeightController,
              label: "Packing Weight (KG)",
              hint: "e.g. 30.000",
              icon: Icons.fitness_center_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              isDark: isDark,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _textField(
                    controller: controller.rateController,
                    label: "Rate (₹)",
                    hint: "e.g. 50.00",
                    icon: Icons.currency_rupee_outlined,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _textField(
                    controller: controller.amountController,
                    label: "Total Amount (₹)",
                    hint: "e.g. 25005.00",
                    icon: Icons.calculate_outlined,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Logistics & Vehicle Section (Matching Website Transport Details) ────
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
          if (isTablet)
            Row(
              children: [
                Expanded(
                  child: _textField(
                    controller: controller.transporterNameController,
                    label: "Transporter Name",
                    hint: "e.g. Transporter First",
                    icon: Icons.business_outlined,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _textField(
                    controller: controller.truckNumberController,
                    label: "Truck / Vehicle Number *",
                    hint: "e.g. MH31AB1236",
                    icon: Icons.local_shipping_outlined,
                    isDark: isDark,
                  ),
                ),
              ],
            )
          else ...[
            _textField(
              controller: controller.transporterNameController,
              label: "Transporter Name",
              hint: "e.g. Transporter First",
              icon: Icons.business_outlined,
              isDark: isDark,
            ),
            const SizedBox(height: 14),
            _textField(
              controller: controller.truckNumberController,
              label: "Truck / Vehicle Number *",
              hint: "e.g. MH31AB1236",
              icon: Icons.local_shipping_outlined,
              isDark: isDark,
            ),
          ],
          const SizedBox(height: 14),
          if (isTablet)
            Row(
              children: [
                Expanded(
                  child: _textField(
                    controller: controller.driverNameController,
                    label: "Driver Name *",
                    hint: "e.g. Jay Deep",
                    icon: IconlyLight.user,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _textField(
                    controller: controller.driverPhoneController,
                    label: "Driver Mobile Number",
                    hint: "e.g. 3234568909",
                    icon: IconlyLight.call,
                    keyboardType: TextInputType.phone,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _textField(
                    controller: controller.driverLicenseController,
                    label: "Driver License Number",
                    hint: "e.g. Q833874HD92",
                    icon: Icons.badge_outlined,
                    isDark: isDark,
                  ),
                ),
              ],
            )
          else ...[
            _textField(
              controller: controller.driverNameController,
              label: "Driver Name *",
              hint: "e.g. Jay Deep",
              icon: IconlyLight.user,
              isDark: isDark,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _textField(
                    controller: controller.driverPhoneController,
                    label: "Driver Mobile Number",
                    hint: "e.g. 3234568909",
                    icon: IconlyLight.call,
                    keyboardType: TextInputType.phone,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _textField(
                    controller: controller.driverLicenseController,
                    label: "Driver License",
                    hint: "e.g. Q833874HD92",
                    icon: Icons.badge_outlined,
                    isDark: isDark,
                  ),
                ),
              ],
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
        label: "Selected Contract Details & Narration",
        hint: "Selected Contract Details:\nContract: JBC...\nSeller: ...\nBuyer: ...",
        icon: IconlyLight.chat,
        maxLines: 5,
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
                    "Select Confirmed Contract / Bid",
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
                          const Text("No contracts ready for a challan"),
                          const SizedBox(height: 6),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              "A challan can be created once a transporter's bid on the contract is accepted.",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
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
            if (c.bagCount != null && c.bagCount! > 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 12, color: isDark ? Colors.white60 : Colors.black54),
                  const SizedBox(width: 4),
                  Text(
                    "${c.bagCount} Bags",
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                  ),
                  if (c.truckNumber != null && c.truckNumber!.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.local_shipping_outlined, size: 12, color: isDark ? Colors.white60 : Colors.black54),
                    const SizedBox(width: 4),
                    Text(
                      c.truckNumber!,
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                    ),
                  ],
                ],
              ),
            ],
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
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
