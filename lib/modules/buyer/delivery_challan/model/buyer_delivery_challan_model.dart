class BuyerDeliveryChallanModel {
  int? id;
  List<DeliveryChallanItem>? items;
  Company? company;
  CreatedByDisplay? createdByDisplay;
  String? createdByName;
  String? sellerNameDisplay;
  String? buyerNameDisplay;
  String? transporterNameDisplay;
  String? dispatchedByName;
  String? receivedByName;
  String? challanNumber;
  String? challanDate;
  String? sellerName;
  String? sellerGst;
  String? sellerAddress;
  String? buyerName;
  String? buyerGst;
  String? buyerAddress;
  String? truckNumber;
  String? driverName;
  String? driverLicenseNumber;
  String? driverMobile;
  String? narration;
  String? totalAmount;
  String? lorryFreightPerBag;
  String? loadingCharges;
  String? otherExp;
  String? lessAdvance;
  String? status;
  String? dispatchedAt;
  String? receivedAt;
  String? createdAt;
  String? updatedAt;
  int? order;
  int? seller;
  int? buyer;
  int? transporter;
  int? dispatchedBy;
  int? receivedBy;
  int? createdBy;

  BuyerDeliveryChallanModel({
    this.id,
    this.items,
    this.company,
    this.createdByDisplay,
    this.createdByName,
    this.sellerNameDisplay,
    this.buyerNameDisplay,
    this.transporterNameDisplay,
    this.dispatchedByName,
    this.receivedByName,
    this.challanNumber,
    this.challanDate,
    this.sellerName,
    this.sellerGst,
    this.sellerAddress,
    this.buyerName,
    this.buyerGst,
    this.buyerAddress,
    this.truckNumber,
    this.driverName,
    this.driverLicenseNumber,
    this.driverMobile,
    this.narration,
    this.totalAmount,
    this.lorryFreightPerBag,
    this.loadingCharges,
    this.otherExp,
    this.lessAdvance,
    this.status,
    this.dispatchedAt,
    this.receivedAt,
    this.createdAt,
    this.updatedAt,
    this.order,
    this.seller,
    this.buyer,
    this.transporter,
    this.dispatchedBy,
    this.receivedBy,
    this.createdBy,
  });

  factory BuyerDeliveryChallanModel.fromJson(Map<String, dynamic> json) {
    return BuyerDeliveryChallanModel(
      id: json['id'],
      items: json['items'] != null
          ? (json['items'] as List).map((i) => DeliveryChallanItem.fromJson(i)).toList()
          : null,
      company: json['company'] != null ? Company.fromJson(json['company']) : null,
      createdByDisplay: json['created_by_display'] != null
          ? CreatedByDisplay.fromJson(json['created_by_display'])
          : null,
      createdByName: json['created_by_name'],
      sellerNameDisplay: json['seller_name_display'],
      buyerNameDisplay: json['buyer_name_display'],
      transporterNameDisplay: json['transporter_name_display'],
      dispatchedByName: json['dispatched_by_name'],
      receivedByName: json['received_by_name'],
      challanNumber: json['challan_number'],
      challanDate: json['challan_date'],
      sellerName: json['seller_name'],
      sellerGst: json['seller_gst'],
      sellerAddress: json['seller_address'],
      buyerName: json['buyer_name'],
      buyerGst: json['buyer_gst'],
      buyerAddress: json['buyer_address'],
      truckNumber: json['truck_number'],
      driverName: json['driver_name'],
      driverLicenseNumber: json['driver_license_number'],
      driverMobile: json['driver_mobile'],
      narration: json['narration'],
      totalAmount: json['total_amount']?.toString(),
      lorryFreightPerBag: json['lorry_freight_per_bag']?.toString(),
      loadingCharges: json['loading_charges']?.toString(),
      otherExp: json['other_exp']?.toString(),
      lessAdvance: json['less_advance']?.toString(),
      status: json['status'],
      dispatchedAt: json['dispatched_at'],
      receivedAt: json['received_at'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      order: json['order'],
      seller: json['seller'],
      buyer: json['buyer'],
      transporter: json['transporter'],
      dispatchedBy: json['dispatched_by'],
      receivedBy: json['received_by'],
      createdBy: json['created_by'],
    );
  }
}

class DeliveryChallanItem {
  int? id;
  String? productName;
  String? quantity;
  String? unit;
  int? bagCount;
  String? packingWeightKg;
  String? rate;
  String? amount;
  String? brokerageRate;
  String? commissionType;
  String? createdAt;
  int? challan;
  int? product;

  DeliveryChallanItem({
    this.id,
    this.productName,
    this.quantity,
    this.unit,
    this.bagCount,
    this.packingWeightKg,
    this.rate,
    this.amount,
    this.brokerageRate,
    this.commissionType,
    this.createdAt,
    this.challan,
    this.product,
  });

  factory DeliveryChallanItem.fromJson(Map<String, dynamic> json) {
    return DeliveryChallanItem(
      id: json['id'],
      productName: json['product_name'],
      quantity: json['quantity']?.toString(),
      unit: json['unit'],
      bagCount: json['bag_count'],
      packingWeightKg: json['packing_weight_kg']?.toString(),
      rate: json['rate']?.toString(),
      amount: json['amount']?.toString(),
      brokerageRate: json['brokerage_rate']?.toString(),
      commissionType: json['commission_type'],
      createdAt: json['created_at'],
      challan: json['challan'],
      product: json['product'],
    );
  }
}

class Company {
  String? city;
  String? email;
  String? phone;
  String? state;
  String? country;
  String? pincode;
  String? gstNumber;
  String? legalName;
  String? panNumber;
  String? addressLine1;
  String? addressLine2;
  String? addressDisplay;
  int? registeredCompanyId;

  Company({
    this.city,
    this.email,
    this.phone,
    this.state,
    this.country,
    this.pincode,
    this.gstNumber,
    this.legalName,
    this.panNumber,
    this.addressLine1,
    this.addressLine2,
    this.addressDisplay,
    this.registeredCompanyId,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      city: json['city'],
      email: json['email'],
      phone: json['phone'],
      state: json['state'],
      country: json['country'],
      pincode: json['pincode'],
      gstNumber: json['gst_number'],
      legalName: json['legal_name'],
      panNumber: json['pan_number'],
      addressLine1: json['address_line_1'],
      addressLine2: json['address_line_2'],
      addressDisplay: json['address_display'],
      registeredCompanyId: json['registered_company_id'],
    );
  }
}

class CreatedByDisplay {
  String? name;
  String? role;
  int? userId;

  CreatedByDisplay({
    this.name,
    this.role,
    this.userId,
  });

  factory CreatedByDisplay.fromJson(Map<String, dynamic> json) {
    return CreatedByDisplay(
      name: json['name'],
      role: json['role'],
      userId: json['user_id'],
    );
  }
}
