class ContractModel {
  final int id;
  final String productTitle;
  final String productCategory;
  final String contractId;

  final String buyerName;
  final String sellerName;

  final String displayBuyerId;
  final String displaySellerId;

  final String dealAmount;
  final String dealQuantity;

  final String amountUnit;
  final String quantityUnit;

  final String loadingFrom;
  final String loadingTo;

  final String status;

  final String createdAt;

  ContractModel({
    required this.id,
    required this.productTitle,
    required this.productCategory,
    required this.contractId,
    required this.buyerName,
    required this.sellerName,
    required this.displayBuyerId,
    required this.displaySellerId,
    required this.dealAmount,
    required this.dealQuantity,
    required this.amountUnit,
    required this.quantityUnit,
    required this.loadingFrom,
    required this.loadingTo,
    required this.status,
    required this.createdAt,
  });

  factory ContractModel.fromJson(Map<String, dynamic> json) {
    return ContractModel(
      id: json['id'],
      productTitle: json['product_title'] ?? "",
      productCategory: json['product_category_name'] ?? "",
      contractId: json['contract_id'] ?? "",

      buyerName: json['buyer_name'] ?? "",
      sellerName: json['seller_name'] ?? "",

      displayBuyerId: json['display_buyer_id'] ?? "",
      displaySellerId: json['display_seller_id'] ?? "",

      dealAmount: json['deal_amount'] ?? "",
      dealQuantity: json['deal_quantity'] ?? "",

      amountUnit: json['amount_unit'] ?? "",
      quantityUnit: json['quantity_unit'] ?? "",

      loadingFrom: json['loading_from'] ?? "",
      loadingTo: json['loading_to'] ?? "",

      status: json['status'] ?? "",
      createdAt: json['created_at'] ?? "",
    );
  }
}