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
  String? buyerMobile;
  String? deliveryAddress;
  // Registered-company details, same as the web challan page.
  String? sellerCompanyName;
  String? sellerPan;
  String? buyerCompanyName;
  String? buyerPan;
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

  String? get companyNameDisplay {
    final comp = company?.legalName ?? company?.addressDisplay;
    if (comp != null && comp.trim().isNotEmpty) return comp.trim();
    if (sellerCompanyName != null && sellerCompanyName!.trim().isNotEmpty) {
      return sellerCompanyName!.trim();
    }
    if (buyerCompanyName != null && buyerCompanyName!.trim().isNotEmpty) {
      return buyerCompanyName!.trim();
    }
    return null;
  }

  String? get totalQuantityDisplay {
    if (items != null && items!.isNotEmpty) {
      double total = 0;
      bool hasNumeric = false;
      String unit = items!.first.unit ?? 'QTL';
      for (final item in items!) {
        final q = double.tryParse(item.quantity?.replaceAll(',', '') ?? '');
        if (q != null) {
          total += q;
          hasNumeric = true;
        }
        if (item.unit != null && item.unit!.isNotEmpty) {
          unit = item.unit!;
        }
      }
      if (hasNumeric && total > 0) {
        return "${total.toStringAsFixed(3)} $unit";
      }
      final firstQty = items!.first.quantity;
      if (firstQty != null && firstQty.trim().isNotEmpty) {
        return "$firstQty ${items!.first.unit ?? 'QTL'}";
      }
    }
    return null;
  }

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
    this.buyerMobile,
    this.deliveryAddress,
    this.sellerCompanyName,
    this.sellerPan,
    this.buyerCompanyName,
    this.buyerPan,
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
    String? cleanStr(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      if (s.isEmpty || s.toLowerCase() == 'null') return null;
      return s;
    }

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
      transporterNameDisplay: cleanStr(
        json['transporter_name_display'] ??
            json['transporter_name'] ??
            (json['transporter'] is Map
                ? (json['transporter']['name'] ?? json['transporter']['company_name'])
                : null),
      ),
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
      buyerMobile: cleanStr(
        json['buyer_mobile'] ??
            json['buyer_phone'] ??
            json['buyer_contact'] ??
            json['buyer_telephone'] ??
            json['buyer_tel'] ??
            json['consignee_mobile'] ??
            json['consignee_phone'] ??
            (json['buyer'] is Map
                ? (json['buyer']['mobile'] ??
                    json['buyer']['phone'] ??
                    json['buyer']['phone_number'] ??
                    json['buyer']['contact'])
                : null) ??
            (json['buyer_display'] is Map
                ? (json['buyer_display']['mobile'] ??
                    json['buyer_display']['phone'] ??
                    json['buyer_display']['phone_number'])
                : null) ??
            (json['buyer_details'] is Map
                ? (json['buyer_details']['mobile'] ??
                    json['buyer_details']['phone'])
                : null) ??
            (json['buyer_user'] is Map
                ? (json['buyer_user']['mobile'] ??
                    json['buyer_user']['phone'])
                : null) ??
            (json['contract'] is Map
                ? (json['contract']['buyer_mobile'] ??
                    json['contract']['buyer_phone'])
                : null) ??
            (json['buyer_company'] is Map
                ? (json['buyer_company']['phone'] ??
                    json['buyer_company']['mobile'])
                : null),
      ),
      deliveryAddress: cleanStr(
        json['delivery_address'] ??
            json['del_at'] ??
            json['delivery_at'] ??
            json['delivery_location'] ??
            json['destination_address'] ??
            json['destination'],
      ),
      sellerCompanyName: json['seller_company_name'],
      sellerPan: json['seller_pan'],
      buyerCompanyName: json['buyer_company_name'],
      buyerPan: json['buyer_pan'],
      truckNumber: cleanStr(json['truck_number']),
      driverName: cleanStr(json['driver_name']),
      driverLicenseNumber: cleanStr(
        json['driver_license_number'] ??
            json['license_number'] ??
            json['driver_license'] ??
            json['driver_licence'] ??
            (json['driver'] is Map
                ? (json['driver']['license_number'] ??
                    json['driver']['license'] ??
                    json['driver']['driver_license_number'])
                : null),
      ),
      driverMobile: cleanStr(
        json['driver_mobile'] ??
            json['driver_phone'] ??
            (json['driver'] is Map ? json['driver']['mobile'] : null),
      ),
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
