import 'dart:convert';
import 'dart:io';

import 'package:daalsetu/comman/api_url.dart';
import 'package:daalsetu/modules/admin_catalog/config/admin_module_config.dart';
import 'package:daalsetu/modules/admin_catalog/config/admin_actions.dart';
import 'package:daalsetu/modules/admin_catalog/config/admin_detail_config.dart';
import 'package:daalsetu/modules/admin_catalog/model/admin_record.dart';
import 'package:daalsetu/modules/admin_catalog/repository/admin_catalog_repository.dart';
import 'package:daalsetu/widgets/authenticated_network_image.dart';
import 'package:daalsetu/widgets/authenticated_video_player.dart';
import 'package:daalsetu/utils/app_preferences.dart';
import 'package:flutter/material.dart';
import 'package:daalsetu/modules/downloads/service/downloads_service.dart';
import 'package:daalsetu/theme/app_theme.dart';
import 'package:daalsetu/widgets/hero_header.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:daalsetu/modules/buyer/offers/view/buyer_offer_details_view.dart';
import '../../../utils/app_snackbar.dart';
import 'package:daalsetu/widgets/back_navigation.dart';

class AdminRecordDetailScreen extends StatefulWidget {
  const AdminRecordDetailScreen({
    super.key,
    required this.config,
    required this.record,
  });

  final AdminModuleConfig config;
  final AdminRecord record;

  @override
  State<AdminRecordDetailScreen> createState() =>
      _AdminRecordDetailScreenState();
}

class _AdminRecordDetailScreenState extends State<AdminRecordDetailScreen> {
  late Future<AdminRecord> detail;
  AdminRecord? _currentRecord;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  void _loadDetail() {
    detail = AdminCatalogRepository(widget.config).detail(widget.record).then((rec) {
      if (mounted) {
        setState(() {
          _currentRecord = rec;
        });
      }
      return rec;
    });
  }

  dynamic _resolveValue(Map<String, dynamic> data, String keyPath) {
    for (final altKey in keyPath.split('|')) {
      final parts = altKey.trim().split('.');
      dynamic current = data;
      bool found = true;
      for (final part in parts) {
        if (current is Map && current.containsKey(part)) {
          current = current[part];
        } else {
          found = false;
          break;
        }
      }
      if (found && current != null && current.toString().trim().isNotEmpty) {
        if (altKey == 'is_active' && current is bool) {
          return current ? 'active' : 'inactive';
        }
        // If this is a name field, but the value is pure digits (e.g. phone number like "1234567892")
        // and first_name / last_name exist, prioritize full name over phone digits!
        final strVal = current.toString().trim();
        final isDigits = RegExp(r'^\d+$').hasMatch(strVal);
        final isNameField = (altKey == 'name' || altKey == 'username' || altKey == 'full_name') &&
            (keyPath.startsWith('name') || keyPath == 'username' || keyPath == 'full_name');
        if (isNameField && isDigits) {
          final first = (data['first_name'] ?? (data['user'] is Map ? data['user']['first_name'] : null) ?? '').toString().trim();
          final last = (data['last_name'] ?? (data['user'] is Map ? data['user']['last_name'] : null) ?? '').toString().trim();
          final combined = '$first $last'.trim();
          if (combined.isNotEmpty) {
            return combined;
          }
        }
        return current;
      }
    }

    // Smart fallback derivation for user names
    if (keyPath.contains('first_name')) {
      final nestedFirst = data['user'] is Map ? data['user']['first_name'] : null;
      if (nestedFirst != null && nestedFirst.toString().trim().isNotEmpty) {
        return nestedFirst.toString().trim();
      }
      final fullName = (data['name'] ?? data['username'] ?? '')
          .toString()
          .trim();
      if (fullName.isNotEmpty && !RegExp(r'^\d+$').hasMatch(fullName)) {
        return fullName.split(' ').first;
      }
    }
    if (keyPath.contains('last_name')) {
      final nestedLast = data['user'] is Map ? data['user']['last_name'] : null;
      if (nestedLast != null && nestedLast.toString().trim().isNotEmpty) {
        return nestedLast.toString().trim();
      }
      final fullName = (data['name'] ?? data['username'] ?? '')
          .toString()
          .trim();
      if (fullName.isNotEmpty && !RegExp(r'^\d+$').hasMatch(fullName)) {
        final words = fullName.split(' ');
        if (words.length > 1) {
          return words.sublist(1).join(' ');
        }
      }
    }
    if (keyPath == 'name' || keyPath == 'full_name' || keyPath.startsWith('name|')) {
      final first = (data['first_name'] ?? (data['user'] is Map ? data['user']['first_name'] : null) ?? '').toString().trim();
      final last = (data['last_name'] ?? (data['user'] is Map ? data['user']['last_name'] : null) ?? '').toString().trim();
      final combined = '$first $last'.trim();
      if (combined.isNotEmpty) {
        return combined;
      }
    }

    // Smart fallback derivation for image and media fields
    if (keyPath.contains('image') ||
        keyPath.contains('photo') ||
        keyPath.contains('thumbnail') ||
        keyPath.contains('logo')) {
      for (final candidate in const [
        'brand_image',
        'logo',
        'brand_logo',
        'image_url',
        'image',
        'category_image',
        'image_path',
        'thumbnail',
        'file',
        'media',
        'photo',
        'url',
      ]) {
        if (data.containsKey(candidate) &&
            data[candidate] != null &&
            data[candidate].toString().trim().isNotEmpty &&
            data[candidate].toString().trim().toLowerCase() != 'null') {
          return data[candidate];
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: HeroHeader(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => goBackOrHome(context),
        ),
        title: '${widget.config.title} Details',
        subtitle: 'Inspect catalog record fields & metadata',
      ),
      body: FutureBuilder<AdminRecord>(
        future: detail,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return _buildSkeleton();
          }
          if (snapshot.hasError) {
            return _buildError(snapshot.error.toString());
          }
          final data = snapshot.data!.data;

          // If detailSections are provided, use the new layout engine
          if (widget.config.detailSections.isNotEmpty) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.config.detailSections.length,
              itemBuilder: (context, index) {
                return _buildSection(widget.config.detailSections[index], data);
              },
            );
          }

          // Fallback to generic view if no detailSections are provided
          return ListView(
            padding: const EdgeInsets.all(16),
            children: data.entries
                .where((entry) => entry.value != null)
                .map((entry) => _fallbackValueCard(entry.key, entry.value))
                .toList(),
          );
        },
      ),
      bottomNavigationBar: _buildBottomActionBar(theme, isDark),
    );
  }

  Widget? _buildBottomActionBar(ThemeData theme, bool isDark) {
    if (widget.config.customActions.isEmpty) return null;
    final currentData = _currentRecord?.data ?? widget.record.data;
    final visibleActions = widget.config.customActions
        .where((action) => action.isVisible?.call(currentData) ?? true)
        .toList();
    if (visibleActions.isEmpty) return null;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2C394F) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          for (int i = 0; i < visibleActions.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(
              child: _buildDetailActionButton(visibleActions[i], currentData),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailActionButton(
    AdminCustomAction action,
    Map<String, dynamic> currentData,
  ) {
    final titleLower = action.title.toLowerCase();
    final isReject = titleLower.contains('reject');
    final isApprove = titleLower.contains('approve');

    if (isReject) {
      return OutlinedButton.icon(
        onPressed: () async {
          final success = await action.onPressed(context, currentData);
          if (success && mounted) {
            setState(() {
              _loadDetail();
            });
          }
        },
        icon: Icon(action.icon, size: 18, color: const Color(0xFFDC2626)),
        label: Text(
          action.title,
          style: const TextStyle(
            color: Color(0xFFDC2626),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFDC2626),
          side: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    if (isApprove) {
      return ElevatedButton.icon(
        onPressed: () async {
          final success = await action.onPressed(context, currentData);
          if (success && mounted) {
            setState(() {
              _loadDetail();
            });
          }
        },
        icon: Icon(action.icon, size: 18, color: Colors.white),
        label: Text(
          action.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF16A34A),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: () async {
        final success = await action.onPressed(context, currentData);
        if (success && mounted) {
          setState(() {
            _loadDetail();
          });
        }
      },
      icon: Icon(action.icon, size: 18),
      label: Text(
        action.title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 20,
                width: 120,
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
              const SizedBox(height: 16),
              Container(
                height: 16,
                width: double.infinity,
                color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
              ),
              const SizedBox(height: 8),
              Container(
                height: 16,
                width: 200,
                color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            "Failed to load details",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              setState(() {
                detail = AdminCatalogRepository(
                  widget.config,
                ).detail(widget.record);
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(AdminDetailSection section, Map<String, dynamic> data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark ? AppTheme.borderColor : const Color(0xFFFFE0B2),
          width: 1.2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: isDark
                ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                : const Color(0xFFFFF8E1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              section.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.primaryGold : const Color(0xFFE65100),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...section.fields.map((field) {
                  final value = _resolveValue(data, field.key);
                  return _buildField(field, value);
                }),
                if (section.title.toLowerCase().contains('quotation') &&
                    widget.config.key == 'buyer_requirements')
                  _buildBuyerRequirementQuotations(data),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuyerRequirementQuotations(Map<String, dynamic> data) {
    final rawQuotes = data['quotations'] ?? data['submitted_quotations'] ?? data['quotes'];
    final List<dynamic> quotations = (rawQuotes is List) ? rawQuotes : [];
    if (quotations.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final numericId = int.tryParse((data['id'] ?? '').toString()) ??
        int.tryParse(RegExp(r'\d+$').firstMatch((data['rfq_id'] ?? '').toString())?.group(0) ?? '') ??
        0;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Submitted Quotations (${quotations.length})',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              if (numericId > 0)
                TextButton.icon(
                  onPressed: () => Get.to(
                    () => BuyerOfferDetailsView(
                      offerId: numericId,
                      preferBuyerRequirement: true,
                    ),
                  ),
                  icon: const Icon(Icons.forum_outlined, size: 16),
                  label: const Text('All Chats', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          for (final q in quotations)
            if (q is Map) _buildQuotationItemCard(q, numericId, isDark),
        ],
      ),
    );
  }

  Widget _buildQuotationItemCard(Map q, int numericId, bool isDark) {
    final sellerName = q['seller_name'] ??
        (q['seller'] is Map ? q['seller']['name'] : null) ??
        'Seller';
    final branch = q['branch_name'] ?? q['branch'] ?? q['seller_branch'] ?? '';
    final sellerTitle = branch.toString().trim().isNotEmpty
        ? '$sellerName / $branch'
        : sellerName.toString();

    final price = q['offered_price'] ?? q['price'] ?? q['rate'] ?? '-';
    final priceUnit = q['price_unit'] ?? q['unit'] ?? 'QTL';
    final qty = q['offered_quantity'] ?? q['quantity'] ?? '-';
    final qtyUnit = q['quantity_unit'] ?? q['unit'] ?? 'QTL';
    final status = (q['status'] ?? 'pending').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  sellerTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Price',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹$price / $priceUnit',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFF05A28),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quantity',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$qty $qtyUnit',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  if (numericId > 0) {
                    Get.to(
                      () => BuyerOfferDetailsView(
                        offerId: numericId,
                        preferBuyerRequirement: true,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.chat_bubble_outline, size: 14),
                label: const Text(
                  'Chat / Details',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF05A28),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField(AdminDetailField field, dynamic value) {
    final bool isNullOrEmpty =
        value == null ||
        value.toString().trim().isEmpty ||
        value.toString().trim().toLowerCase() == 'null';

    Widget content;

    if (isNullOrEmpty && field.type != AdminDetailFieldType.boolean) {
      content = Text(
        "Not Available",
        style: TextStyle(
          color: Theme.of(
            context,
          ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
          fontStyle: FontStyle.italic,
        ),
      );
    } else {
      switch (field.type) {
        case AdminDetailFieldType.date:
          content = Text(
            _formatDate(value.toString()),
            style: const TextStyle(fontWeight: FontWeight.w600),
          );
          break;
        case AdminDetailFieldType.status:
          content = _buildStatusBadge(value.toString());
          break;
        case AdminDetailFieldType.boolean:
          final boolVal =
              value == true || value.toString().toLowerCase() == 'true';
          final isStatusField =
              field.label.toLowerCase().contains('status') ||
              field.label.toLowerCase().contains('active');
          final labelText = isStatusField
              ? (boolVal ? 'Active' : 'Inactive')
              : (boolVal ? 'Yes' : 'No');
          final color = boolVal ? Colors.green : Colors.red;
          content = isStatusField
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    labelText,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                )
              : Text(
                  labelText,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                );
          break;
        case AdminDetailFieldType.phone:
          content = GestureDetector(
            onTap: () => _launchUrl('tel:${value.toString()}'),
            child: Text(
              value.toString(),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          );
          break;
        case AdminDetailFieldType.email:
          content = GestureDetector(
            onTap: () => _launchUrl('mailto:${value.toString()}'),
            child: Text(
              value.toString(),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          );
          break;
        case AdminDetailFieldType.image:
          content = _buildImagePreview(value.toString());
          break;
        case AdminDetailFieldType.video:
          content = _buildVideoPreview(value.toString());
          break;
        case AdminDetailFieldType.download:
          content = FilledButton.tonalIcon(
            onPressed: () => _download(_absoluteUrl(value.toString())),
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Download Document'),
          );
          break;
        case AdminDetailFieldType.text:
          content = SelectableText(
            adminDisplayValue(value),
            style: const TextStyle(fontWeight: FontWeight.w600),
          );
          break;
      }
    }

    final isLongText =
        !isNullOrEmpty &&
        field.type == AdminDetailFieldType.text &&
        (value.toString().trim().length > 60 ||
            value.toString().contains('\n'));

    if (isLongText) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    field.label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (field.copyable && !isNullOrEmpty)
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: value.toString()));
                      AppSnackbar.showSnackBar(context, 
                        const SnackBar(
                          content: Text('Copied to clipboard'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Icon(
                        Icons.copy_rounded,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).scaffoldBackgroundColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: content,
            ),
          ],
        ),
      );
    }

    if (field.type == AdminDetailFieldType.video) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            content,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              field.label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Align(alignment: Alignment.centerLeft, child: content),
                ),
                if (field.copyable && !isNullOrEmpty)
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: value.toString()));
                      AppSnackbar.showSnackBar(context, 
                        const SnackBar(
                          content: Text('Copied to clipboard'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Icon(
                        Icons.copy_rounded,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString).toLocal();
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final month = months[date.month - 1];
      final hour = date.hour == 0
          ? 12
          : (date.hour > 12 ? date.hour - 12 : date.hour);
      final amPm = date.hour >= 12 ? 'PM' : 'AM';
      final min = date.minute.toString().padLeft(2, '0');
      return "${date.day} $month ${date.year} \n$hour:$min $amPm";
    } catch (e) {
      return isoString;
    }
  }

  Widget _buildStatusBadge(String status) {
    final lower = status.toLowerCase();
    Color color = Colors.grey;
    String prefix = '⚫';

    if (lower.contains('active') ||
        lower.contains('approved') ||
        lower.contains('success') ||
        lower.contains('completed')) {
      color = Colors.green;
      prefix = '🟢';
    } else if (lower.contains('pending') ||
        lower.contains('unassigned') ||
        lower.contains('maintenance')) {
      color = Colors.orange;
      prefix = '🟠';
    } else if (lower.contains('inactive') ||
        lower.contains('rejected') ||
        lower.contains('failed') ||
        lower.contains('cancelled')) {
      color = Colors.red;
      prefix = '🔴';
    } else if (lower.contains('assigned') || lower.contains('available')) {
      color = Colors.blue;
      prefix = '🔵';
    }

    final displayStatus = status
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        "$prefix $displayStatus",
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildImagePreview(String path) {
    final url = _absoluteUrl(path);
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  _FullScreenImage(url: url, onDownload: () => _download(url)),
            ),
          ),
          child: Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: AuthenticatedNetworkImage(
              url: url,
              fit: BoxFit.cover,
              fallback: const Center(child: Icon(Icons.broken_image_outlined)),
            ),
          ),
        ),
        FilledButton.tonalIcon(
          onPressed: () => _download(url),
          icon: const Icon(Icons.download_rounded, size: 18),
          label: const Text('Download Image'),
        ),
      ],
    );
  }

  Widget _buildVideoPreview(String path) {
    final url = _absoluteUrl(path);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
        color: Colors.black,
      ),
      clipBehavior: Clip.antiAlias,
      child: AuthenticatedVideoPlayer(url: url),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else if (mounted) {
        AppSnackbar.showSnackBar(context, SnackBar(content: Text('Could not launch $urlString')));
      }
    } catch (e) {
      debugPrint("Error launching $urlString: $e");
    }
  }

  // --- Fallback renderer for undefined modules ---
  Widget _fallbackValueCard(String key, dynamic value) {
    if (value is List || value is Map) {
      return _fallbackTextCard(
        _label(key),
        const JsonEncoder.withIndent('  ').convert(value),
      );
    }
    final text = value.toString();
    final url = _absoluteUrl(text);
    if (_isImage(key, text)) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _label(key),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _FullScreenImage(
                      url: url,
                      onDownload: () => _download(url),
                    ),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AuthenticatedNetworkImage(
                    url: url,
                    height: 220,
                    width: double.infinity,
                    fallback: const SizedBox(
                      height: 100,
                      child: Center(child: Icon(Icons.broken_image_outlined)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.tonalIcon(
                onPressed: () => _download(url),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Download Image'),
              ),
            ],
          ),
        ),
      );
    }
    if (_isVideo(key, text)) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _label(key),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              AuthenticatedVideoPlayer(url: url),
            ],
          ),
        ),
      );
    }
    return _fallbackTextCard(_label(key), text);
  }

  Widget _fallbackTextCard(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppTheme.borderColor : const Color(0xFFFFE0B2),
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 5),
            SelectableText(
              value.isEmpty ? '—' : value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  String _label(String key) => key
      .split('_')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');

  String _absoluteUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return '${ApiUrls.baseUrl}${trimmed.startsWith('/') ? '' : '/'}$trimmed';
  }

  bool _isImage(String key, String value) {
    final text = '$key $value'.toLowerCase();
    return text.contains('image') ||
        text.endsWith('.jpg') ||
        text.endsWith('.jpeg') ||
        text.endsWith('.png') ||
        text.endsWith('.webp');
  }

  bool _isVideo(String key, String value) {
    final text = '$key $value'.toLowerCase();
    return text.contains('video') ||
        text.endsWith('.mp4') ||
        text.endsWith('.mov') ||
        text.endsWith('.webm');
  }

  Future<void> _download(String url) async {
    try {
      final token = await AppPreferences.getAccessToken();
      final response = await http.get(
        Uri.parse(url),
        headers: token == null || token.isEmpty
            ? const {}
            : {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Download failed (${response.statusCode})');
      }
      final uri = Uri.parse(url);
      var fileName = uri.pathSegments.isEmpty
          ? 'download'
          : uri.pathSegments.last;
      if (fileName.isEmpty || fileName == 'download') {
        fileName = 'download_${DateTime.now().millisecondsSinceEpoch}';
      }
      final file = File('${Directory.systemTemp.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);
      await DownloadsService.saveBytes(
        fileName: fileName,
        bytes: response.bodyBytes,
        mimeType: response.headers['content-type'],
      );
      if (!mounted) return;
      AppSnackbar.showSnackBar(context, 
        const SnackBar(content: Text('Saved to Downloads.')),
      );
    } catch (error) {
      if (!mounted) return;
      AppSnackbar.showSnackBar(context, 
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

class _FullScreenImage extends StatelessWidget {
  const _FullScreenImage({required this.url, this.onDownload});
  final String url;
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      actions: [
        if (onDownload != null)
          IconButton(
            tooltip: 'Download',
            icon: const Icon(Icons.download_rounded),
            onPressed: onDownload,
          ),
      ],
    ),
    body: InteractiveViewer(
      minScale: .5,
      maxScale: 5,
      child: Center(
        child: AuthenticatedNetworkImage(
          url: url,
          fit: BoxFit.contain,
          fallback: const Icon(
            Icons.broken_image_outlined,
            color: Colors.white,
            size: 60,
          ),
        ),
      ),
    ),
  );
}
