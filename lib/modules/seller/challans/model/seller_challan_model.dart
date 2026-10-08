class SellerChallanModel {
  final int? id;
  final String? challanNumber;
  final String? challanDate;
  final String? sellerName;
  final String? buyerName;
  final String? truckNumber;
  final String? driverName;
  final String? driverMobile;
  final String? totalAmount;
  final String? status;
  final String? dispatchedAt;
  final String? receivedAt;
  final String? transporterName;
  final String? driverLicenseNumber;
  final String? narration;
  final String? createdAt;
  final String? updatedAt;
  final String? companyName;
  final List<Map<String, dynamic>> items;
  final Map<String, dynamic> raw;

  SellerChallanModel({
    this.id,
    this.challanNumber,
    this.challanDate,
    this.sellerName,
    this.buyerName,
    this.truckNumber,
    this.driverName,
    this.driverMobile,
    this.totalAmount,
    this.status,
    this.dispatchedAt,
    this.receivedAt,
    this.transporterName,
    this.driverLicenseNumber,
    this.narration,
    this.createdAt,
    this.updatedAt,
    this.companyName,
    this.items = const [],
    this.raw = const {},
  });

  factory SellerChallanModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
        : const <Map<String, dynamic>>[];
    final company = json['company'];
    return SellerChallanModel(
      id: json['id'] as int?,
      challanNumber: json['challan_number'] ?? json['challan_no'] ?? json['id']?.toString(),
      challanDate: json['challan_date'] ?? json['date'] ?? json['created_at'],
      sellerName: json['seller_name'] ?? (json['seller'] is Map ? json['seller']['name'] : null),
      buyerName: json['buyer_name'] ?? (json['buyer'] is Map ? json['buyer']['name'] : null),
      truckNumber: json['truck_number'] ?? json['vehicle_number'],
      driverName: json['driver_name'],
      driverMobile: json['driver_mobile']?.toString(),
      totalAmount: json['total_amount']?.toString() ?? json['amount']?.toString(),
      status: json['status'] ?? 'pending',
      dispatchedAt: json['dispatched_at'],
      receivedAt: json['received_at'],
      transporterName: json['transporter_name_display'] ?? json['transporter_name'],
      driverLicenseNumber: json['driver_license_number'],
      narration: json['narration'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      companyName: company is Map
          ? (company['legal_name'] ?? company['company_name'] ?? company['name'])?.toString()
          : json['company_name']?.toString(),
      items: items,
      raw: Map<String, dynamic>.from(json),
    );
  }

  int get totalBags => items.fold<int>(
        0,
        (sum, item) => sum + (int.tryParse('${item['bag_count'] ?? 0}') ?? 0),
      );

  String get itemSummary {
    if (items.isEmpty) return '';
    final names = items
        .map((item) => (item['product_name'] ?? '').toString().trim())
        .where((name) => name.isNotEmpty)
        .toList();
    if (names.isEmpty) {
      return '${items.length} item${items.length == 1 ? '' : 's'}';
    }
    return names.take(2).join(', ') + (names.length > 2 ? ' +${names.length - 2}' : '');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'challan_number': challanNumber,
      'challan_date': challanDate,
      'seller_name': sellerName,
      'buyer_name': buyerName,
      'truck_number': truckNumber,
      'driver_name': driverName,
      'driver_mobile': driverMobile,
      'total_amount': totalAmount,
      'status': status,
      'dispatched_at': dispatchedAt,
      'received_at': receivedAt,
      'transporter_name_display': transporterName,
      'driver_license_number': driverLicenseNumber,
      'narration': narration,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'company_name': companyName,
      'items': items,
    };
  }
}
