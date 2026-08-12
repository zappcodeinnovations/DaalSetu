class SellerBrandModel {
  final int? id;
  final String? name;
  final String? logoUrl;
  final String? companyName;
  final String? description;

  SellerBrandModel({
    this.id,
    this.name,
    this.logoUrl,
    this.companyName,
    this.description,
  });

  factory SellerBrandModel.fromJson(Map<String, dynamic> json) {
    return SellerBrandModel(
      id: json['id'] as int?,
      name: json['name'] ?? json['brand_name'],
      logoUrl: json['logo_url'] ?? json['logo'] ?? json['image'],
      companyName: json['company_name'] ?? json['company']?['name'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logo_url': logoUrl,
      'company_name': companyName,
      'description': description,
    };
  }
}
