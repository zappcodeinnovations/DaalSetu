class SellerTagModel {
  final int? id;
  final String? name;
  final String? slug;

  /// "Own" (the seller's tag: they can change it) or "Admin" (shared with the branch: use only).
  final String ownerLabel;
  final bool canEdit;

  SellerTagModel({
    this.id,
    this.name,
    this.slug,
    this.ownerLabel = 'Admin',
    this.canEdit = false,
  });

  factory SellerTagModel.fromJson(Map<String, dynamic> json) {
    return SellerTagModel(
      id: json['id'] as int?,
      name: json['name'] ?? json['tag_name'],
      slug: json['slug'],
      ownerLabel: (json['owner_label'] ?? 'Admin').toString(),
      canEdit: json['can_edit'] == true,
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
