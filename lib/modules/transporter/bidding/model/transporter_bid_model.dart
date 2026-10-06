class TransporterBidModel {
  final int? id;
  final int? productId;
  final String title;
  final String categoryName;
  final String loadingFrom;
  final String loadingTo;
  final String availableQuantity;
  final String quantityUnit;
  final String basePrice;
  final String? myBidPrice;
  final String status;
  final String? dealStatus;
  final String? createdAt;
  final int? bagCount;
  final String? packingWeight;

  TransporterBidModel({
    this.id,
    this.productId,
    required this.title,
    required this.categoryName,
    required this.loadingFrom,
    required this.loadingTo,
    required this.availableQuantity,
    required this.quantityUnit,
    required this.basePrice,
    this.myBidPrice,
    required this.status,
    this.dealStatus,
    this.createdAt,
    this.bagCount,
    this.packingWeight,
  });

  factory TransporterBidModel.fromJson(Map<String, dynamic> json) {
    return TransporterBidModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      productId: json['product_id'] ?? json['id'],
      title: json['title'] ?? json['product_title'] ?? json['commodity'] ?? 'Consignment Load',
      categoryName: json['category'] is Map ? (json['category']['name'] ?? '') : (json['category_name'] ?? json['category']?.toString() ?? 'General'),
      loadingFrom: json['loading_from'] ?? json['source'] ?? json['pickup_location'] ?? 'Origin',
      loadingTo: json['loading_to'] ?? json['destination'] ?? json['delivery_location'] ?? 'Destination',
      availableQuantity: json['available_quantity']?.toString() ?? json['remaining_quantity']?.toString() ?? json['quantity']?.toString() ?? '0',
      quantityUnit: json['quantity_unit'] ?? json['unit'] ?? 'Qtl',
      basePrice: json['amount']?.toString() ?? json['price']?.toString() ?? json['target_price']?.toString() ?? '0',
      myBidPrice: json['offered_amount']?.toString() ?? json['bid_amount']?.toString() ?? json['target_price']?.toString(),
      status: (json['status'] ?? json['bid_status'] ?? 'ACTIVE').toString().toUpperCase(),
      dealStatus: json['deal_status']?.toString(),
      createdAt: json['created_at']?.toString() ?? json['date']?.toString(),
      bagCount: json['original_bag_count'] ?? json['bag_count'],
      packingWeight: json['packing_weight_kg']?.toString(),
    );
  }
}
