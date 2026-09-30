import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:agro_broker/widgets/authenticated_network_image.dart';
import '../controller/admin_category_master_controller.dart';
import 'package:image_picker/image_picker.dart';
import 'package:agro_broker/theme/app_theme.dart';

class AdminCategoryMasterScreen extends StatefulWidget {
  const AdminCategoryMasterScreen({super.key});

  @override
  State<AdminCategoryMasterScreen> createState() => _AdminCategoryMasterScreenState();
}

class _AdminCategoryMasterScreenState extends State<AdminCategoryMasterScreen> {
  final AdminCategoryMasterController controller = Get.put(AdminCategoryMasterController());
  
  Color get colorBg => Theme.of(context).scaffoldBackgroundColor;
  Color get colorSurface => Theme.of(context).cardColor;
  Color get colorPrimary => Theme.of(context).colorScheme.primary;
  Color get colorTextDark => Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
  Color get colorTextLight => Theme.of(context).textTheme.bodyMedium?.color ?? AppTheme.textMuted;
  Color get colorBorder => AppTheme.borderColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBg,
      appBar: AppBar(
        backgroundColor: colorSurface,
        elevation: 0,
        iconTheme: IconThemeData(color: colorTextDark),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category Master', style: TextStyle(color: colorTextDark, fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Manage Categories', style: TextStyle(color: colorTextLight, fontSize: 13, fontWeight: FontWeight.w400)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.fetchData(),
          )
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          _buildSummaryCards(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final list = controller.filteredTree;
              if (list.isEmpty) {
                return const Center(child: Text("No categories found."));
              }
              return ListView.builder(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80, top: 8),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  return _buildCategoryCard(list[index], 0);
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: colorPrimary,
        onPressed: () => _showFormSheet(context),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Category', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: colorSurface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: colorBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                onChanged: (v) => controller.searchQuery.value = v,
                decoration: InputDecoration(
                  hintText: 'Search categories or brands...',
                  hintStyle: TextStyle(color: colorTextLight, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: colorTextLight, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: () => _showFilterSheet(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: colorBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorBorder),
              ),
              child: Icon(Icons.tune, color: colorTextDark, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      height: 90,
      color: colorSurface,
      padding: const EdgeInsets.only(bottom: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Obx(() => _summaryCard('Total', controller.totalCount.value.toString(), Icons.category, AppTheme.primaryGold)),
          Obx(() => _summaryCard('Root', controller.rootCount.value.toString(), Icons.account_tree, AppTheme.secondaryOrange)),
          Obx(() => _summaryCard('Sub', controller.subCount.value.toString(), Icons.subdirectory_arrow_right, AppTheme.primaryGold)),
          Obx(() => _summaryCard('Active', controller.activeCount.value.toString(), Icons.check_circle, AppTheme.successGreen)),
          Obx(() => _summaryCard('Inactive', controller.inactiveCount.value.toString(), Icons.cancel, AppTheme.errorRed)),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 110,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(color: colorTextDark, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(CategoryTreeModel node, int depth) {
    bool hasChildren = node.children.isNotEmpty;
    bool isActive = node.status.toLowerCase() == 'active';

    Widget cardContent = Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: colorBorder.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: ListTile(
              contentPadding: const EdgeInsets.only(left: 12, right: 4, top: 4, bottom: 4),
            leading: node.image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AuthenticatedNetworkImage(
                      url: node.image!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      fallback: Icon(Icons.image, color: colorTextLight),
                    ),
                  )
                : Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.image_outlined, color: colorTextLight),
                  ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    node.name,
                    style: TextStyle(color: colorTextDark, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _badge('L${node.level}', AppTheme.textMuted),
                  _badge(isActive ? 'Active' : node.status.capitalizeFirst!, isActive ? AppTheme.successGreen : AppTheme.secondaryOrange),
                  if (node.brands.isNotEmpty) _badge('${node.brands.length} Brands', AppTheme.primaryGold),
                  if (hasChildren) _badge('${node.children.length} Sub', colorPrimary),
                ],
              ),
            ),
            trailing: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: colorTextLight),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                if (value == 'edit') {
                  _showFormSheet(context, category: node);
                } else if (value == 'delete') {
                  _showDeleteDialog(context, node);
                } else if (value == 'add_child') {
                  _showFormSheet(context, defaultParentId: node.id);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 12), Text('Edit')])),
                const PopupMenuItem(value: 'add_child', child: Row(children: [Icon(Icons.add, size: 20), SizedBox(width: 12), Text('Add Sub Category')])),
                PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 20, color: AppTheme.errorRed), SizedBox(width: 12), Text('Delete', style: TextStyle(color: AppTheme.errorRed))])),
              ],
            ),
          ),
          ),
          if (hasChildren)
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Text('View ${node.children.length} Sub Categories', style: TextStyle(color: colorPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                iconColor: colorPrimary,
                collapsedIconColor: colorPrimary,
                childrenPadding: const EdgeInsets.only(left: 24, right: 8, bottom: 8),
                children: node.children.map((c) => _buildCategoryCard(c, depth + 1)).toList(),
              ),
            ),
        ],
      ),
    );

    return cardContent;
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _showDeleteDialog(BuildContext context, CategoryTreeModel node) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Category?'),
        content: Text('Are you sure you want to delete "${node.name}"?\nDeleting this category may affect child categories.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              Navigator.pop(context);
              controller.deleteCategory(node.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Filter Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorTextDark)),
            const SizedBox(height: 24),
            
            Text('Level', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorTextDark)),
            const SizedBox(height: 8),
            Obx(() => Wrap(
              spacing: 8,
              children: [
                _filterChip('All', controller.filterLevel.value == null, () => controller.filterLevel.value = null),
                _filterChip('L0 (Root)', controller.filterLevel.value == 0, () => controller.filterLevel.value = 0),
                _filterChip('L1', controller.filterLevel.value == 1, () => controller.filterLevel.value = 1),
                _filterChip('L2', controller.filterLevel.value == 2, () => controller.filterLevel.value = 2),
              ],
            )),
            
            const SizedBox(height: 20),
            Text('Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorTextDark)),
            const SizedBox(height: 8),
            Obx(() => Wrap(
              spacing: 8,
              children: [
                _filterChip('All', controller.filterStatus.value == null, () => controller.filterStatus.value = null),
                _filterChip('Active', controller.filterStatus.value == 'active', () => controller.filterStatus.value = 'active'),
                _filterChip('Inactive', controller.filterStatus.value == 'inactive', () => controller.filterStatus.value = 'inactive'),
                _filterChip('Pending', controller.filterStatus.value == 'pending', () => controller.filterStatus.value = 'pending'),
              ],
            )),
            
            const SizedBox(height: 20),
            Text('Image', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorTextDark)),
            const SizedBox(height: 8),
            Obx(() => Wrap(
              spacing: 8,
              children: [
                _filterChip('All', controller.filterHasImage.value == null, () => controller.filterHasImage.value = null),
                _filterChip('Has Image', controller.filterHasImage.value == true, () => controller.filterHasImage.value = true),
                _filterChip('No Image', controller.filterHasImage.value == false, () => controller.filterHasImage.value = false),
              ],
            )),
            
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      controller.clearFilters();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Clear All'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, bool isSelected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: colorPrimary.withOpacity(0.1),
      labelStyle: TextStyle(color: isSelected ? colorPrimary : colorTextDark, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide(color: isSelected ? colorPrimary : colorBorder),
    );
  }

  void _showFormSheet(BuildContext context, {CategoryTreeModel? category, int? defaultParentId}) {
    controller.openForm(category: category, defaultParentId: defaultParentId);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: colorSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppTheme.borderColor, borderRadius: BorderRadius.circular(2)),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(category != null ? 'Update Category' : 'Add Category', 
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorTextDark)),
                  IconButton(
                    icon: Icon(Icons.close, color: colorTextLight),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
            ),
            const Divider(height: 1),
            // Form Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormLabel('Category Name'),
                    TextField(
                      controller: controller.nameCtrl,
                      decoration: _inputDecoration('Enter category name'),
                    ),
                    const SizedBox(height: 20),
                    
                    _buildFormLabel('Parent Category'),
                    Obx(() => Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: colorBorder),
                        borderRadius: BorderRadius.circular(12),
                        color: colorBg,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int?>(
                          isExpanded: true,
                          value: controller.selectedParentId.value,
                          hint: const Text('None (Root Category)'),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('None (Root Category)')),
                            ...controller.rootCategories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                          ],
                          onChanged: (v) => controller.selectedParentId.value = v,
                        ),
                      ),
                    )),
                    
                    const SizedBox(height: 20),
                    _buildFormLabel('Status'),
                    Obx(() => Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: colorBorder),
                        borderRadius: BorderRadius.circular(12),
                        color: colorBg,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: controller.selectedStatus.value,
                          items: const [
                            DropdownMenuItem(value: 'active', child: Text('Active')),
                            DropdownMenuItem(value: 'pending', child: Text('Pending')),
                            DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                          ],
                          onChanged: (v) => controller.selectedStatus.value = v!,
                        ),
                      ),
                    )),

                    const SizedBox(height: 24),
                    _buildFormLabel('Mapped Brands'),
                    Obx(() {
                      final selectedBrands = controller.allBrands.where((b) => controller.selectedBrandIds.contains(b['id'])).toList();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (selectedBrands.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: selectedBrands.map((b) => InputChip(
                                label: Text(b['brand_name'] ?? '', style: TextStyle(fontSize: 12, color: colorPrimary)),
                                backgroundColor: colorPrimary.withOpacity(0.1),
                                deleteIconColor: colorPrimary,
                                onDeleted: () => controller.toggleBrandSelection(b['id']),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: colorPrimary.withOpacity(0.3))),
                              )).toList(),
                            )
                          else
                            Text('No brands selected.', style: TextStyle(color: colorTextLight, fontSize: 13)),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => _showBrandPicker(context),
                            icon: const Icon(Icons.add_circle_outline, size: 18),
                            label: const Text('Add Brands'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorTextDark,
                              side: BorderSide(color: colorBorder),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          )
                        ],
                      );
                    }),
                    
                    const SizedBox(height: 24),
                    _buildFormLabel('Category Image'),
                    InkWell(
                      onTap: () async {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(source: ImageSource.gallery);
                        if (picked != null) {
                          controller.selectedImagePath.value = picked.path;
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: colorBorder, style: BorderStyle.solid),
                          borderRadius: BorderRadius.circular(12),
                          color: colorBg,
                        ),
                        child: Row(
                          children: [
                            Obx(() {
                              if (controller.selectedImagePath.value != null) {
                                return Container(
                                  width: 56, height: 56,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: AssetImage(controller.selectedImagePath.value!), // For web this might be different, but assuming mobile path
                                      fit: BoxFit.cover,
                                    )
                                  ),
                                );
                              }
                              if (category != null && category.image != null) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: AuthenticatedNetworkImage(
                                    url: category.image!,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    fallback: Icon(Icons.image_outlined, color: colorTextLight),
                                  ),
                                );
                              }
                              return Container(
                                width: 56, height: 56,
                                decoration: BoxDecoration(color: colorSurface, borderRadius: BorderRadius.circular(8), border: Border.all(color: colorBorder)),
                                child: Icon(Icons.add_photo_alternate, color: colorTextLight),
                              );
                            }),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Upload Image', style: TextStyle(fontWeight: FontWeight.bold, color: colorTextDark)),
                                  const SizedBox(height: 4),
                                  Text('JPG, PNG or WEBP, max 2MB.', style: TextStyle(color: colorTextLight, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            // Bottom Buttons
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorSurface,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: colorBorder),
                      ),
                      child: Text('Cancel', style: TextStyle(color: colorTextDark)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Obx(() => FilledButton(
                      onPressed: controller.isSubmitting.value ? null : () => controller.submitCategory(),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: controller.isSubmitting.value 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(category != null ? 'Update Category' : 'Save Category', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    )),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBrandPicker(BuildContext context) {
    controller.brandSearchQuery.value = ''; // Reset search on open
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Select Brands', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorTextDark)),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => controller.selectAllBrands(),
                        child: Text('All', style: TextStyle(color: colorPrimary)),
                      ),
                      TextButton(
                        onPressed: () => controller.deselectAllBrands(),
                        child: Text('None', style: TextStyle(color: colorPrimary)),
                      ),
                    ],
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                onChanged: (val) => controller.brandSearchQuery.value = val,
                decoration: _inputDecoration('Search brands...').copyWith(
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Obx(() {
                final brands = controller.filteredBrands;
                if (brands.isEmpty) {
                  return const Center(child: Text("No brands found."));
                }
                return ListView.builder(
                  controller: scrollController,
                  itemCount: brands.length,
                  itemBuilder: (context, index) {
                    final brand = brands[index];
                    return Obx(() {
                      final isSelected = controller.selectedBrandIds.contains(brand['id']);
                      return CheckboxListTile(
                        title: Text(brand['brand_name'] ?? ''),
                        value: isSelected,
                        activeColor: colorPrimary,
                        onChanged: (_) => controller.toggleBrandSelection(brand['id']),
                      );
                    });
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: TextStyle(color: colorTextDark, fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colorTextLight.withOpacity(0.5)),
      filled: true,
      fillColor: colorBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorPrimary, width: 2)),
    );
  }
}
