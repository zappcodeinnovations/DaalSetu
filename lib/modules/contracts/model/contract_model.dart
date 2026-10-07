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

  final String? bags;
  final int? bagCount;
  final String? packingWeightKg;

  final String? truckNumber;
  final String? driverName;
  final String? driverMobile;
  final String? driverLicenseNumber;
  final String? transporterName;
  final String? transporterMobile;
  final String? bidAmount;

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
    this.bags,
    this.bagCount,
    this.packingWeightKg,
    this.truckNumber,
    this.driverName,
    this.driverMobile,
    this.driverLicenseNumber,
    this.transporterName,
    this.transporterMobile,
    this.bidAmount,
  });

  factory ContractModel.fromJson(Map<String, dynamic> json) {
    // Helper to extract string safely
    String text(String key) => json[key]?.toString() ?? "";
    int? number(String key) => json[key] is int ? json[key] as int : int.tryParse(json[key]?.toString() ?? "");

    // Transporter name might be nested or direct
    String transName = text('transporter_name_display');
    if (transName.isEmpty) transName = text('transporter_name');
    if (transName.isEmpty && json['transporter'] != null) {
      if (json['transporter'] is Map) {
        transName = json['transporter']['username']?.toString() ?? json['transporter']['name']?.toString() ?? "";
      } else {
        transName = json['transporter'].toString();
      }
    }

    return ContractModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      productTitle: text('product_title'),
      productCategory: text('product_category_name'),
      contractId: text('contract_id'),

      buyerName: text('buyer_name'),
      sellerName: text('seller_name'),

      displayBuyerId: text('display_buyer_id'),
      displaySellerId: text('display_seller_id'),

      dealAmount: text('deal_amount'),
      dealQuantity: text('deal_quantity'),

      amountUnit: text('amount_unit'),
      quantityUnit: text('quantity_unit'),

      loadingFrom: text('loading_from'),
      loadingTo: text('loading_to'),

      status: text('status'),
      createdAt: text('created_at'),

      bags: text('bags').isNotEmpty ? text('bags') : null,
      bagCount: number('bag_count') ?? (number('bags')),
      packingWeightKg: text('packing_weight_kg').isNotEmpty ? text('packing_weight_kg') : null,

      truckNumber: text('truck_number').isNotEmpty ? text('truck_number') : (text('vehicle_number').isNotEmpty ? text('vehicle_number') : null),
      driverName: text('driver_name').isNotEmpty ? text('driver_name') : null,
      driverMobile: text('driver_mobile').isNotEmpty ? text('driver_mobile') : (text('driver_phone').isNotEmpty ? text('driver_phone') : null),
      driverLicenseNumber: text('driver_license_number').isNotEmpty ? text('driver_license_number') : (text('driver_license').isNotEmpty ? text('driver_license') : null),
      transporterName: transName.isNotEmpty ? transName : null,
      transporterMobile: text('transporter_mobile').isNotEmpty ? text('transporter_mobile') : null,
      bidAmount: text('bid_amount').isNotEmpty ? text('bid_amount') : (text('accepted_bid_amount').isNotEmpty ? text('accepted_bid_amount') : null),
    );
  }
}
