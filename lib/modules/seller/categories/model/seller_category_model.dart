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
      brands:
          (json['brands'] as List?)
              ?.map((e) => BrandModel.fromJson(e))
              .toList() ??
          [],
      children:
          (json['children'] as List?)
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
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      brandName: (json['brand_name'] ?? json['name'] ?? "").toString(),
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
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      name: (json['category_name'] ?? json['name'] ?? "").toString(),
      parent: json['parent'] is int
          ? json['parent'] as int
          : int.tryParse('${json['parent'] ?? json['parent_id']}'),
      parentName: json['parent_name']?.toString(),
      level: json['level'] is int
          ? json['level'] as int
          : int.tryParse('${json['level']}') ?? 0,
      path: (json['path'] ?? json['full_path'] ?? "").toString(),
      isActive: json['is_active'] is bool
          ? json['is_active'] as bool
          : (json['is_active']?.toString().toLowerCase() == 'true' ||
              (json['status'] ?? 'active').toString().toLowerCase() == 'active'),
      status: (json['status'] ?? "active").toString(),
      childrenCount: json['children_count'] is int
          ? json['children_count'] as int
          : int.tryParse('${json['children_count']}') ?? 0,
      fullPath: (json['full_path'] ?? json['path'] ?? "").toString(),
      isRoot: json['is_root'] is bool
          ? json['is_root'] as bool
          : (json['level'] == 0 || json['parent'] == null),
      isLeaf: json['is_leaf'] is bool
          ? json['is_leaf'] as bool
          : false,
      imageUrl: (json['image_url'] ?? json['image'])?.toString(),
      hasChildren: json['has_children'] is bool
          ? json['has_children'] as bool
          : false,
      brands:
          (json['brands'] as List?)
              ?.map((e) => BrandModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
