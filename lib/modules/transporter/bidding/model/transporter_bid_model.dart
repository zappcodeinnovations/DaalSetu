import 'package:daalsetu/services/dispatch_bill_services.dart';

/// Contract open for freight bidding (GET /api/transport-bids/?view=open, web "Active Shipment Offer's").
class ShipmentOfferModel {
  final int id;
  final String contractId;
  final String productTitle;
  final String pickupLocation;
  final String deliveryLocation;
  final String loadingDateRange;
  final String? expectedDeliveryDate;
  final String dealQuantity;
  final String quantityUnit;
  final int? bagCount;
  final String? packingWeightKg;
  final String? currentLowestBid;
  final String? myBid;
  final String? myBidStatus;
  final int? myBidPosition;
  final int activeBidCount;
  /// Admin's freight price (MoM 16): accept it or negotiate. Null = open bidding.
  final String? maxBid;
  final int? myBidId;
  final String? counterAmount;
  final String counterNote;
  final String myBidTypeLabel;

  bool get hasAdminPrice => maxBid != null;
  bool get hasCounterOffer => counterAmount != null;

  ShipmentOfferModel({
    required this.id,
    required this.contractId,
    required this.productTitle,
    required this.pickupLocation,
    required this.deliveryLocation,
    required this.loadingDateRange,
    this.expectedDeliveryDate,
    required this.dealQuantity,
    required this.quantityUnit,
    this.bagCount,
    this.packingWeightKg,
    this.currentLowestBid,
    this.myBid,
    this.myBidStatus,
    this.myBidPosition,
    required this.activeBidCount,
    this.maxBid,
    this.myBidId,
    this.counterAmount,
    this.counterNote = '',
    this.myBidTypeLabel = '',
  });

  factory ShipmentOfferModel.fromJson(Map<String, dynamic> json) {
    String? text(String key) {
      final value = json[key];
      return value == null || '$value'.isEmpty ? null : '$value';
    }
    final negotiation = json['my_bid_negotiation'] is Map ? json['my_bid_negotiation'] as Map : const {};

    return ShipmentOfferModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      contractId: text('contract_id') ?? '${json['id']}',
      productTitle: text('product_title') ?? 'Consignment',
      pickupLocation: text('pickup_location') ?? '-',
      deliveryLocation: text('delivery_location') ?? '-',
      loadingDateRange: text('loading_date_range') ?? '-',
      expectedDeliveryDate: text('expected_delivery_date'),
      dealQuantity: text('deal_quantity') ?? '-',
      quantityUnit: text('quantity_unit') ?? '',
      bagCount: json['bag_count'] is int ? json['bag_count'] : null,
      packingWeightKg: text('packing_weight_kg'),
      currentLowestBid: text('current_lowest_bid'),
      myBid: text('my_bid'),
      myBidStatus: text('my_bid_status'),
      myBidPosition: json['my_bid_position'] is int ? json['my_bid_position'] : null,
      activeBidCount: json['active_bid_count'] is int ? json['active_bid_count'] : 0,
      maxBid: text('max_bid'),
      myBidId: json['my_bid_id'] is int ? json['my_bid_id'] : null,
      counterAmount: negotiation['admin_counter_amount'] == null ? null : '${negotiation['admin_counter_amount']}',
      counterNote: '${negotiation['admin_counter_note'] ?? ''}',
      myBidTypeLabel: '${negotiation['bid_type_label'] ?? ''}',
    );
  }
}

/// One of my bids (GET /api/transport-bids/?view=mine, web "My Deals").
class MyBidModel {
  final int bidId;
  final String status;
  final String bidAmount;
  final String? adminRemark;
  final String? createdAt;
  final int contractPk;
  final String contractId;
  final String contractStatus;
  final String productTitle;
  final String loadingFrom;
  final String loadingTo;
  final String dealQuantity;
  final String quantityUnit;
  final int? assignedVehicleId;
  final int? assignedDriverId;
  final Map<String, String> assignment;
  final bool assignmentLocked;
  final bool canAssignDriver;
  final Map<String, dynamic> contractData;

  /// Bills the seller attached at dispatch (accepted bids only, MoM point 23).
  final List<DispatchBill> dispatchBills;

  bool get isPending {
    final s = status.toLowerCase().trim();
    return s == 'pending' || s == 'active' || s == 'reserved';
  }

  MyBidModel({
    required this.bidId,
    required this.status,
    required this.bidAmount,
    this.adminRemark,
    this.createdAt,
    required this.contractPk,
    required this.contractId,
    required this.contractStatus,
    required this.productTitle,
    required this.loadingFrom,
    required this.loadingTo,
    required this.dealQuantity,
    required this.quantityUnit,
    this.assignedVehicleId,
    this.assignedDriverId,
    required this.assignment,
    required this.assignmentLocked,
    required this.canAssignDriver,
    this.contractData = const {},
    this.dispatchBills = const [],
  });

  factory MyBidModel.fromJson(Map<String, dynamic> json) {
    final contract = json['contract'] is Map ? Map<String, dynamic>.from(json['contract'] as Map) : <String, dynamic>{};
    final assignment = json['assignment'] is Map ? json['assignment'] as Map : const {};
    return MyBidModel(
      bidId: json['bid_id'] is int ? json['bid_id'] : int.tryParse('${json['bid_id']}') ?? 0,
      status: '${json['status'] ?? 'pending'}',
      bidAmount: '${json['bid_amount'] ?? '-'}',
      adminRemark: '${json['admin_remark'] ?? ''}'.isEmpty ? null : '${json['admin_remark']}',
      createdAt: json['created_at']?.toString(),
      contractPk: contract['id'] is int ? contract['id'] : 0,
      contractId: '${contract['contract_id'] ?? '-'}',
      contractStatus: '${contract['status'] ?? ''}',
      productTitle: '${contract['product_title'] ?? 'Consignment'}',
      loadingFrom: '${contract['loading_from'] ?? '-'}',
      loadingTo: '${contract['loading_to'] ?? '-'}',
      dealQuantity: '${contract['deal_quantity'] ?? '-'}',
      quantityUnit: '${contract['quantity_unit'] ?? ''}',
      assignedVehicleId: json['assigned_vehicle_id'] is int ? json['assigned_vehicle_id'] : null,
      assignedDriverId: json['assigned_driver_id'] is int ? json['assigned_driver_id'] : null,
      assignment: {for (final e in assignment.entries) '${e.key}': '${e.value ?? ''}'},
      assignmentLocked: json['assignment_locked'] == true,
      canAssignDriver: json['can_assign_driver'] == true ||
          ('${json['status']}'.toLowerCase() == 'accepted' && json['assignment_locked'] != true),
      contractData: contract,
      dispatchBills: DispatchBill.listFrom(json['dispatch_bills']),
    );
  }
}

class FleetOption {
  final int id;
  final String label;
  final int? linkedVehicleId;
  /// Driver phone + details, used by the phone search (MoM 22).
  final String phone;
  final Map<String, String> details;
  const FleetOption(this.id, this.label, {this.linkedVehicleId, this.phone = '', this.details = const {}});

  /// Drivers whose phone number contains the typed digits (MoM 22). Spaces,
  /// "+91" and dashes are ignored; fewer than 4 digits match nothing.
  static List<FleetOption> matchByPhone(Iterable<FleetOption> drivers, String query) {
    String digits(String value) => value.replaceAll(RegExp(r'\D'), '');
    final wanted = digits(query);
    if (wanted.length < 4) return const [];
    return drivers.where((driver) => digits(driver.phone).contains(wanted)).toList();
  }
}
