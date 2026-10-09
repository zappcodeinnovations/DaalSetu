import 'package:flutter/material.dart';

class AdminChallanModel {
  final int id;
  final String? challanNumber;
  final String? challanDate;
  final String? status;
  final String? truckNumber;
  final String? driverName;
  final String? driverMobile;
  final String? driverLicenseNumber;
  final String? narration;
  final double totalAmount;
  final String? dispatchedAt;
  final String? receivedAt;
  final String? createdAt;
  final String? updatedAt;
  final int? orderId;
  final int? contractId;
  final String? contractCode;
  final String? sellerNameDisplay;
  final String? buyerNameDisplay;
  final String? transporterNameDisplay;
  final String? dispatchedByName;
  final String? receivedByName;
  final String? sellerName;
  final String? sellerAddress;
  final String? buyerName;
  final String? buyerAddress;
  // Registered-company details, same as the web challan page.
  final String? sellerCompanyName;
  final String? sellerGst;
  final String? sellerPan;
  final String? buyerCompanyName;
  final String? buyerGst;
  final String? buyerPan;
  final List<AdminChallanItem> items;

  AdminChallanModel({
    required this.id,
    this.challanNumber,
    this.challanDate,
    this.status,
    this.truckNumber,
    this.driverName,
    this.driverMobile,
    this.driverLicenseNumber,
    this.narration,
    required this.totalAmount,
    this.dispatchedAt,
    this.receivedAt,
    this.createdAt,
    this.updatedAt,
    this.orderId,
    this.contractId,
    this.contractCode,
    this.sellerNameDisplay,
    this.buyerNameDisplay,
    this.transporterNameDisplay,
    this.dispatchedByName,
    this.receivedByName,
    this.sellerName,
    this.sellerAddress,
    this.buyerName,
    this.buyerAddress,
    this.sellerCompanyName,
    this.sellerGst,
    this.sellerPan,
    this.buyerCompanyName,
    this.buyerGst,
    this.buyerPan,
    required this.items,
  });

  factory AdminChallanModel.fromJson(Map<String, dynamic> json) {
    // Parse nested items
    List<AdminChallanItem> itemsList = [];
    if (json['items'] != null && json['items'] is List) {
      itemsList = (json['items'] as List)
          .map((item) => AdminChallanItem.fromJson(item is Map<String, dynamic> ? item : {}))
          .toList();
    }

    // Extract total amount safely
    double parsedAmount = 0.0;
    if (json['total_amount'] != null) {
      parsedAmount = double.tryParse(json['total_amount'].toString()) ?? 0.0;
    } else if (itemsList.isNotEmpty) {
      parsedAmount = itemsList.fold(0.0, (sum, item) => sum + item.amount);
    }

    return AdminChallanModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      challanNumber: json['challan_number']?.toString(),
      challanDate: json['challan_date']?.toString(),
      status: json['status']?.toString().toLowerCase() ?? 'pending',
      truckNumber: json['truck_number']?.toString() ?? json['vehicle_number']?.toString(),
      driverName: json['driver_name']?.toString() ?? json['dispatched_by_name']?.toString(),
      driverMobile: json['driver_mobile']?.toString() ?? json['driver_phone']?.toString(),
      driverLicenseNumber: json['driver_license_number']?.toString(),
      narration: json['narration']?.toString() ?? json['remarks']?.toString(),
      totalAmount: parsedAmount,
      dispatchedAt: json['dispatched_at']?.toString(),
      receivedAt: json['received_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      orderId: json['order'] is int ? json['order'] : int.tryParse(json['order']?.toString() ?? ''),
      contractId: json['contract_id'] is int ? json['contract_id'] : int.tryParse(json['contract_id']?.toString() ?? ''),
      contractCode: json['contract_code']?.toString(),
      sellerNameDisplay: json['seller_name_display']?.toString(),
      buyerNameDisplay: json['buyer_name_display']?.toString(),
      transporterNameDisplay: json['transporter_name_display']?.toString(),
      dispatchedByName: json['dispatched_by_name']?.toString(),
      receivedByName: json['received_by_name']?.toString(),
      sellerName: json['seller_name']?.toString(),
      sellerAddress: json['seller_address']?.toString(),
      buyerName: json['buyer_name']?.toString(),
      buyerAddress: json['buyer_address']?.toString(),
      sellerCompanyName: json['seller_company_name']?.toString(),
      sellerGst: json['seller_gst']?.toString(),
      sellerPan: json['seller_pan']?.toString(),
      buyerCompanyName: json['buyer_company_name']?.toString(),
      buyerGst: json['buyer_gst']?.toString(),
      buyerPan: json['buyer_pan']?.toString(),
      items: itemsList,
    );
  }

  // ── Convenience Getters ──────────────────────────────────────────────────

  String get displayChallanNo {
    if (challanNumber != null && challanNumber!.isNotEmpty) {
      return challanNumber!;
    }
    return "#DC-$id";
  }

  String get displayContract {
    if (contractCode != null && contractCode!.isNotEmpty) {
      return contractCode!;
    }
    if (contractId != null) {
      return "Contract #$contractId";
    }
    if (orderId != null) {
      return "Contract #$orderId";
    }
    return "Contract N/A";
  }

  String get displaySeller {
    if (sellerNameDisplay != null && sellerNameDisplay!.isNotEmpty) {
      return sellerNameDisplay!;
    }
    if (sellerName != null && sellerName!.isNotEmpty) {
      return sellerName!;
    }
    return "Seller #$id";
  }

  String get displayBuyer {
    if (buyerNameDisplay != null && buyerNameDisplay!.isNotEmpty) {
      return buyerNameDisplay!;
    }
    if (buyerName != null && buyerName!.isNotEmpty) {
      return buyerName!;
    }
    return "Buyer #$id";
  }

  String get displayCommodity {
    if (items.isNotEmpty && items.first.productName.isNotEmpty) {
      return items.first.productName;
    }
    return "Grain / Daal";
  }

  String get displayQuantity {
    if (items.isNotEmpty) {
      return "${items.first.quantity} ${items.first.unit}";
    }
    return "N/A";
  }

  int get displayBagCount {
    if (items.isNotEmpty) {
      return items.first.bagCount;
    }
    return 0;
  }

  String get displayTruck {
    if (truckNumber != null && truckNumber!.isNotEmpty) {
      return truckNumber!;
    }
    return "Vehicle Pending";
  }

  String get displayDriver {
    if (driverName != null && driverName!.isNotEmpty) {
      return driverName!;
    }
    return "Driver Pending";
  }

  Color get statusColor {
    final s = (status ?? 'pending').toLowerCase();
    switch (s) {
      case 'dispatched':
      case 'in_transit':
        return const Color(0xFF2563EB); // Blue
      case 'delivered':
      case 'received':
        return const Color(0xFF059669); // Green
      case 'cancelled':
      case 'rejected':
        return const Color(0xFFDC2626); // Red
      case 'draft':
        return const Color(0xFF7C3AED); // Purple
      case 'pending':
      default:
        return const Color(0xFFD97706); // Amber / Orange
    }
  }

  Color get statusBgColor {
    final s = (status ?? 'pending').toLowerCase();
    switch (s) {
      case 'dispatched':
      case 'in_transit':
        return const Color(0xFFEFF6FF);
      case 'delivered':
      case 'received':
        return const Color(0xFFECFDF5);
      case 'cancelled':
      case 'rejected':
        return const Color(0xFFFEF2F2);
      case 'draft':
        return const Color(0xFFF5F3FF);
      case 'pending':
      default:
        return const Color(0xFFFFFBEB);
    }
  }

  String get statusTitle {
    final s = (status ?? 'pending').toLowerCase();
    switch (s) {
      case 'dispatched':
        return 'Dispatched';
      case 'in_transit':
        return 'In Transit';
      case 'delivered':
      case 'received':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      case 'draft':
        return 'Draft (Pending Dispatch)';
      case 'pending':
      default:
        return 'Pending Dispatch';
    }
  }
}

class AdminChallanItem {
  final int id;
  final String productName;
  final double quantity;
  final String unit;
  final int bagCount;
  final double packingWeight;
  final double rate;
  final double amount;

  AdminChallanItem({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.bagCount,
    required this.packingWeight,
    required this.rate,
    required this.amount,
  });

  factory AdminChallanItem.fromJson(Map<String, dynamic> json) {
    return AdminChallanItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      productName: json['product_name']?.toString() ?? json['commodity']?.toString() ?? 'Commodity Item',
      quantity: double.tryParse(json['quantity']?.toString() ?? '0') ?? 0.0,
      unit: json['unit']?.toString() ?? 'Qtl',
      bagCount: int.tryParse(json['bag_count']?.toString() ?? json['bags']?.toString() ?? '0') ?? 0,
      packingWeight: double.tryParse(json['packing_weight']?.toString() ?? '0') ?? 0.0,
      rate: double.tryParse(json['rate']?.toString() ?? '0') ?? 0.0,
      amount: double.tryParse(json['amount']?.toString() ?? json['total_amount']?.toString() ?? '0') ?? 0.0,
    );
  }
}
