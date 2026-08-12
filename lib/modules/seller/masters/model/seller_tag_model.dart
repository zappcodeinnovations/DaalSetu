class SellerTagModel {
  final int? id;
  final String? name;
  final String? slug;

  SellerTagModel({
    this.id,
    this.name,
    this.slug,
  });

  factory SellerTagModel.fromJson(Map<String, dynamic> json) {
    return SellerTagModel(
      id: json['id'] as int?,
      name: json['name'] ?? json['tag_name'],
      slug: json['slug'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
    };
  }
}
