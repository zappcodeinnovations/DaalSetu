class BuyerOfferModel {
  final int? id;
  final int? productId;
  final int? interestId;
  final String? transactionId;
  final String? title;
  final String? requestedQuantity;
  final String? quantityUnit;
  final String? requestedAmount;
  final String? amountUnit;
  final String? status;
  final String? createdAt;
  
  // Custom fields for UI mapping based on different API formats
  final String? displayTitle;
  final String? displayStatus;
  final String? displayQuantity;
  final String? displayPrice;

  BuyerOfferModel({
    this.id,
    this.productId,
    this.interestId,
    this.transactionId,
    this.title,
    this.requestedQuantity,
    this.quantityUnit,
    this.requestedAmount,
    this.amountUnit,
    this.status,
    this.createdAt,
    this.displayTitle,
    this.displayStatus,
    this.displayQuantity,
    this.displayPrice,
  });

  factory BuyerOfferModel.fromJson(Map<String, dynamic> json) {
    // There are two formats. Main Buyer Offer, and "My Interests/Today's Offers" formats.
    // The "Today's Offers" usually comes in a different minimal shape or similar to Dashboard recent_rfqs.
    return BuyerOfferModel(
      id: json['id'] ?? json['interest_id'] ?? json['product_id'],
      productId: json['product_id'] ?? json['id'],
      interestId: json['interest_id'] ?? json['id'],
      transactionId: json['transaction_id'] ?? '',
      title: json['title'] ?? json['product_title'] ?? '',
      requestedQuantity: json['requested_quantity'] ?? json['required_quantity'] ?? json['quantity']?.toString() ?? '',
      quantityUnit: json['quantity_unit'] ?? json['unit'] ?? '',
      requestedAmount: json['requested_amount'] ?? json['offered_amount'] ?? json['price']?.toString() ?? '',
      amountUnit: json['amount_unit'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['created_at'] ?? json['updated_at'] ?? '',
      
      // Compute safe display strings
      displayTitle: json['title'] ?? json['product_title'] ?? 'Unknown Offer',
      displayStatus: (json['status'] ?? 'Unknown').toString().toUpperCase(),
      displayQuantity: '${json['requested_quantity'] ?? json['required_quantity'] ?? json['quantity'] ?? ''} ${json['quantity_unit'] ?? json['unit'] ?? ''}'.trim(),
      displayPrice: '₹${json['requested_amount'] ?? json['offered_amount'] ?? json['price'] ?? '0'}',
    );
  }
}
