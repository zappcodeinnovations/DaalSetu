class ContractDetailModel {
  ContractDetailModel({
    required this.id,
    required this.contractId,
    required this.productTitle,
    required this.productCategory,
    required this.buyerName,
    required this.buyerUniqueId,
    required this.sellerName,
    required this.sellerMappedId,
    required this.displaySellerId,
    required this.displayBuyerId,
    required this.quantityQtl,
    required this.bags,
    required this.dealAmount,
    required this.dealQuantity,
    required this.amountUnit,
    required this.quantityUnit,
    required this.bagCount,
    required this.packingWeightKg,
    required this.loadingFrom,
    required this.loadingTo,
    required this.buyerRemark,
    required this.sellerRemark,
    required this.adminRemark,
    required this.status,
    required this.confirmedAt,
    required this.transporterVisibleAt,
    required this.transporterVisibilityReason,
    required this.readyForLoadingAt,
    required this.createdAt,
    required this.updatedAt,
    required this.interestId,
    required this.productId,
    required this.buyerId,
    required this.sellerId,
    required this.confirmedByAdminId,
    required this.confirmedBranchId,
    required this.createdByUserId,
    required this.assignedSubAdminId,
    required this.readyForLoadingById,
  });

  final int id;
  final String contractId;
  final String productTitle;
  final String productCategory;
  final String buyerName;
  final String buyerUniqueId;
  final String sellerName;
  final String sellerMappedId;
  final String displaySellerId;
  final String displayBuyerId;
  final String quantityQtl;
  final String bags;
  final String dealAmount;
  final String dealQuantity;
  final String amountUnit;
  final String quantityUnit;
  final int? bagCount;
  final String packingWeightKg;
  final String loadingFrom;
  final String loadingTo;
  final String buyerRemark;
  final String sellerRemark;
  final String adminRemark;
  final String status;
  final String confirmedAt;
  final String transporterVisibleAt;
  final String transporterVisibilityReason;
  final String readyForLoadingAt;
  final String createdAt;
  final String updatedAt;
  final int? interestId;
  final int? productId;
  final int? buyerId;
  final int? sellerId;
  final int? confirmedByAdminId;
  final int? confirmedBranchId;
  final int? createdByUserId;
  final int? assignedSubAdminId;
  final int? readyForLoadingById;

  factory ContractDetailModel.fromJson(Map<String, dynamic> json) {
    String text(String key) => json[key]?.toString() ?? '';
    int? number(String key) => json[key] is int
        ? json[key] as int
        : int.tryParse(json[key]?.toString() ?? '');

    return ContractDetailModel(
      id: number('id') ?? 0,
      contractId: text('contract_id'),
      productTitle: text('product_title'),
      productCategory: text('product_category_name'),
      buyerName: text('buyer_name'),
      buyerUniqueId: text('buyer_unique_id'),
      sellerName: text('seller_name'),
      sellerMappedId: text('seller_mapped_id'),
      displaySellerId: text('display_seller_id'),
      displayBuyerId: text('display_buyer_id'),
      quantityQtl: text('quantity_qtl'),
      bags: text('bags'),
      dealAmount: text('deal_amount'),
      dealQuantity: text('deal_quantity'),
      amountUnit: text('amount_unit'),
      quantityUnit: text('quantity_unit'),
      bagCount: number('bag_count'),
      packingWeightKg: text('packing_weight_kg'),
      loadingFrom: text('loading_from'),
      loadingTo: text('loading_to'),
      buyerRemark: text('buyer_remark'),
      sellerRemark: text('seller_remark'),
      adminRemark: text('admin_remark'),
      status: text('status'),
      confirmedAt: text('confirmed_at'),
      transporterVisibleAt: text('transporter_visible_at'),
      transporterVisibilityReason: text('transporter_visibility_reason'),
      readyForLoadingAt: text('ready_for_loading_at'),
      createdAt: text('created_at'),
      updatedAt: text('updated_at'),
      interestId: number('interest'),
      productId: number('product'),
      buyerId: number('buyer'),
      sellerId: number('seller'),
      confirmedByAdminId: number('confirmed_by_admin'),
      confirmedBranchId: number('confirmed_branch'),
      createdByUserId: number('created_by_user'),
      assignedSubAdminId: number('assigned_sub_admin'),
      readyForLoadingById: number('ready_for_loading_by'),
    );
  }
}
