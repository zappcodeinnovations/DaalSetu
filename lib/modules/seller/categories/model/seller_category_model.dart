class CategoryTreeModel {
  final int id;
  final String name;
  final int level;
  final int? parentId;
  final String? image;
  final String status;
  final int childrenCount;
  final bool hasChildren;
  final List<BrandModel> brands;
  final List<CategoryTreeModel> children;

  CategoryTreeModel({
    required this.id,
    required this.name,
    required this.level,
    this.parentId,
    this.image,
    required this.status,
    required this.childrenCount,
    required this.hasChildren,
    required this.brands,
    required this.children,
  });

  factory CategoryTreeModel.fromJson(Map<String, dynamic> json) {
    return CategoryTreeModel(
      id: json['id'],
      name: json['name'] ?? "",
      level: json['level'] ?? 0,
      parentId: json['parent_id'],
      image: json['image'],
      status: json['status'] ?? "active",
      childrenCount: json['children_count'] ?? 0,
      hasChildren: json['has_children'] ?? false,
      brands: (json['brands'] as List?)
              ?.map((e) => BrandModel.fromJson(e))
              .toList() ??
          [],
      children: (json['children'] as List?)
              ?.map((e) => CategoryTreeModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class BrandModel {
  final int id;
  final String brandName;

  BrandModel({required this.id, required this.brandName});

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: json['id'],
      brandName: json['brand_name'] ?? "",
    );
  }
}

class CategoryDetailModel {
  final int id;
  final String name;
  final int? parent;
  final String? parentName;
  final int level;
  final String path;
  final bool isActive;
  final String status;
  final int childrenCount;
  final String fullPath;
  final bool isRoot;
  final bool isLeaf;
  final String? imageUrl;
  final bool hasChildren;
  final List<BrandModel> brands;

  CategoryDetailModel({
    required this.id,
    required this.name,
    this.parent,
    this.parentName,
    required this.level,
    required this.path,
    required this.isActive,
    required this.status,
    required this.childrenCount,
    required this.fullPath,
    required this.isRoot,
    required this.isLeaf,
    this.imageUrl,
    required this.hasChildren,
    required this.brands,
  });

  factory CategoryDetailModel.fromJson(Map<String, dynamic> json) {
    return CategoryDetailModel(
      id: json['id'],
      name: json['category_name'] ?? "",
      parent: json['parent'],
      parentName: json['parent_name'],
      level: json['level'] ?? 0,
      path: json['path'] ?? "",
      isActive: json['is_active'] ?? false,
      status: json['status'] ?? "active",
      childrenCount: json['children_count'] ?? 0,
      fullPath: json['full_path'] ?? "",
      isRoot: json['is_root'] ?? false,
      isLeaf: json['is_leaf'] ?? false,
      imageUrl: json['image_url'],
      hasChildren: json['has_children'] ?? false,
      brands: (json['brands'] as List?)
              ?.map((e) => BrandModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}
