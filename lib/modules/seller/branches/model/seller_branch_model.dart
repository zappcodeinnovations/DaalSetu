class SellerBranchesResponse {
  final SellerBranch? primaryBranch;
  final List<SellerBranch> otherBranches;
  final List<BranchRequest> pendingRequests;

  SellerBranchesResponse({
    this.primaryBranch,
    required this.otherBranches,
    required this.pendingRequests,
  });

  factory SellerBranchesResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return SellerBranchesResponse(
      primaryBranch: data['primary_branch'] != null ? SellerBranch.fromJson(data['primary_branch']) : null,
      otherBranches: (data['my_branches'] as List?)
              ?.map((e) => SellerBranch.fromJson(e))
              .where((b) => data['primary_branch'] == null || b.id != data['primary_branch']['id'])
              .toList() ??
          [],
      pendingRequests: (data['pending_requests'] as List?)?.map((e) => BranchRequest.fromJson(e)).toList() ?? [],
    );
  }
}

class SellerBranch {
  final int id;
  final String branchCode;
  final String branchName;
  final String city;
  final String state;
  final String? area;
  final bool isActive;

  SellerBranch({
    required this.id,
    required this.branchCode,
    required this.branchName,
    required this.city,
    required this.state,
    this.area,
    required this.isActive,
  });

  factory SellerBranch.fromJson(Map<String, dynamic> json) {
    return SellerBranch(
      id: json['id'],
      branchCode: json['branch_code'] ?? "",
      branchName: json['branch_name'] ?? json['location_name'] ?? "",
      city: json['city'] ?? "",
      state: json['state'] ?? "",
      area: json['area'],
      isActive: json['is_active'] ?? false,
    );
  }
}

class BranchRequest {
  final int id;
  final String branchName;
  final String branchCode;
  final String status;
  final DateTime createdAt;

  BranchRequest({
    required this.id,
    required this.branchName,
    required this.branchCode,
    required this.status,
    required this.createdAt,
  });

  factory BranchRequest.fromJson(Map<String, dynamic> json) {
    return BranchRequest(
      id: json['id'],
      branchName: json['branch_name'] ?? "",
      branchCode: json['branch_code'] ?? "",
      status: json['status'] ?? "",
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
