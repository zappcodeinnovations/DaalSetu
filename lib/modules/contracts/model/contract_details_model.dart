class ContractDetailModel {
  final int id;
  final String contractId;

  final String productTitle;
  final String productCategory;

  final String displaySellerId;
  final String displayBuyerId;

  final String dealAmount;
  final String dealQuantity;

  final String amountUnit;
  final String quantityUnit;

  final String loadingFrom;
  final String loadingTo;

  final String buyerRemark;
  final String sellerRemark;
  final String adminRemark;

  final String status;
  final String createdAt;
  final String confirmedAt;

  ContractDetailModel({
    required this.id,
    required this.contractId,
    required this.productTitle,
    required this.productCategory,
    required this.displaySellerId,
    required this.displayBuyerId,
    required this.dealAmount,
    required this.dealQuantity,
    required this.amountUnit,
    required this.quantityUnit,
    required this.loadingFrom,
    required this.loadingTo,
    required this.buyerRemark,
    required this.sellerRemark,
    required this.adminRemark,
    required this.status,
    required this.createdAt,
    required this.confirmedAt,
  });

  factory ContractDetailModel.fromJson(Map<String, dynamic> json) {
    return ContractDetailModel(
      id: json["id"],
      contractId: json["contract_id"] ?? "",
      productTitle: json["product_title"] ?? "",
      productCategory: json["product_category_name"] ?? "",
      displaySellerId: json["display_seller_id"] ?? "",
      displayBuyerId: json["display_buyer_id"] ?? "",
      dealAmount: json["deal_amount"] ?? "",
      dealQuantity: json["deal_quantity"] ?? "",
      amountUnit: json["amount_unit"] ?? "",
      quantityUnit: json["quantity_unit"] ?? "",
      loadingFrom: json["loading_from"] ?? "",
      loadingTo: json["loading_to"] ?? "",
      buyerRemark: json["buyer_remark"] ?? "",
      sellerRemark: json["seller_remark"] ?? "",
      adminRemark: json["admin_remark"] ?? "",
      status: json["status"] ?? "",
      createdAt: json["created_at"] ?? "",
      confirmedAt: json["confirmed_at"] ?? "",

    );
  }
}
