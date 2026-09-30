import 'dart:convert';
import 'dart:io';

import 'package:agro_broker/comman/api_url.dart';
import 'package:agro_broker/modules/admin_catalog/config/admin_module_config.dart';
import 'package:agro_broker/modules/admin_catalog/config/admin_detail_config.dart';
import 'package:agro_broker/modules/admin_catalog/model/admin_record.dart';
import 'package:agro_broker/modules/admin_catalog/repository/admin_catalog_repository.dart';
import 'package:agro_broker/widgets/authenticated_network_image.dart';
import 'package:agro_broker/widgets/authenticated_video_player.dart';
import 'package:agro_broker/utils/app_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class AdminRecordDetailScreen extends StatefulWidget {
  const AdminRecordDetailScreen({
    super.key,
    required this.config,
    required this.record,
  });

  final AdminModuleConfig config;
  final AdminRecord record;

  @override
  State<AdminRecordDetailScreen> createState() => _AdminRecordDetailScreenState();
}

class _AdminRecordDetailScreenState extends State<AdminRecordDetailScreen> {
  late final Future<AdminRecord> detail;

  @override
  void initState() {
    super.initState();
    detail = AdminCatalogRepository(widget.config).detail(widget.record);
  }

  dynamic _resolveValue(Map<String, dynamic> data, String keyPath) {
    final parts = keyPath.split('.');
    dynamic current = data;
    for (final part in parts) {
      if (current is Map) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('${widget.config.title} Details')),
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
      );

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
              Container(height: 20, width: 120, color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
              const SizedBox(height: 16),
              Container(height: 16, width: double.infinity, color: Theme.of(context).dividerColor.withValues(alpha: 0.05)),
              const SizedBox(height: 8),
              Container(height: 16, width: 200, color: Theme.of(context).dividerColor.withValues(alpha: 0.05)),
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
          Text("Failed to load details", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(error, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              setState(() {
                detail = AdminCatalogRepository(widget.config).detail(widget.record);
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              section.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: section.fields.map((field) {
                final value = _resolveValue(data, field.key);
                return _buildField(field, value);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(AdminDetailField field, dynamic value) {
    final bool isNullOrEmpty = value == null || value.toString().trim().isEmpty;
    
    Widget content;
    
    if (isNullOrEmpty && field.type != AdminDetailFieldType.boolean) {
      content = Text(
        "Not Available",
        style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6), fontStyle: FontStyle.italic),
      );
    } else {
      switch (field.type) {
        case AdminDetailFieldType.date:
          content = Text(_formatDate(value.toString()), style: const TextStyle(fontWeight: FontWeight.w600));
          break;
        case AdminDetailFieldType.status:
          content = _buildStatusBadge(value.toString());
          break;
        case AdminDetailFieldType.boolean:
          final boolVal = value == true || value.toString().toLowerCase() == 'true';
          content = Text(boolVal ? "Yes" : "No", style: const TextStyle(fontWeight: FontWeight.w600));
          break;
        case AdminDetailFieldType.phone:
          content = GestureDetector(
            onTap: () => _launchUrl('tel:${value.toString()}'),
            child: Text(
              value.toString(),
              style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary, decoration: TextDecoration.underline),
            ),
          );
          break;
        case AdminDetailFieldType.email:
          content = GestureDetector(
            onTap: () => _launchUrl('mailto:${value.toString()}'),
            child: Text(
              value.toString(),
              style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary, decoration: TextDecoration.underline),
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
        default:
          content = SelectableText(
            value.toString(),
            style: const TextStyle(fontWeight: FontWeight.w600),
          );
          break;
      }
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
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: content,
                  ),
                ),
                if (field.copyable && !isNullOrEmpty)
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: value.toString()));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 1)));
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Icon(Icons.copy_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
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
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final month = months[date.month - 1];
      final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
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

    if (lower.contains('active') || lower.contains('approved') || lower.contains('success') || lower.contains('completed')) {
      color = Colors.green;
      prefix = '🟢';
    } else if (lower.contains('pending') || lower.contains('unassigned') || lower.contains('maintenance')) {
      color = Colors.orange;
      prefix = '🟠';
    } else if (lower.contains('inactive') || lower.contains('rejected') || lower.contains('failed') || lower.contains('cancelled')) {
      color = Colors.red;
      prefix = '🔴';
    } else if (lower.contains('assigned') || lower.contains('available')) {
      color = Colors.blue;
      prefix = '🔵';
    }

    final displayStatus = status.replaceAll('_', ' ').split(' ').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        "$prefix $displayStatus",
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildImagePreview(String path) {
    final url = _absoluteUrl(path);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => _FullScreenImage(url: url)),
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
    );
  }

  Widget _buildVideoPreview(String path) {
    final url = _absoluteUrl(path);
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not launch $urlString')));
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
              Text(_label(key), style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _FullScreenImage(url: url))),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AuthenticatedNetworkImage(
                    url: url, height: 220, width: double.infinity,
                    fallback: const SizedBox(height: 100, child: Center(child: Icon(Icons.broken_image_outlined))),
                  ),
                ),
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
              Text(_label(key), style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              AuthenticatedVideoPlayer(url: url),
            ],
          ),
        ),
      );
    }
    return _fallbackTextCard(_label(key), text);
  }

  Widget _fallbackTextCard(String label, String value) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 5),
              SelectableText(value.isEmpty ? '—' : value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );

  String _label(String key) => key.split('_').map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}').join(' ');

  String _absoluteUrl(String url) => url.startsWith('http') ? url : '${ApiUrls.baseUrl}$url';

  bool _isImage(String key, String value) {
    final text = '$key $value'.toLowerCase();
    return text.contains('image') || text.endsWith('.jpg') || text.endsWith('.jpeg') || text.endsWith('.png') || text.endsWith('.webp');
  }

  bool _isVideo(String key, String value) {
    final text = '$key $value'.toLowerCase();
    return text.contains('video') || text.endsWith('.mp4') || text.endsWith('.mov') || text.endsWith('.webm');
  }

  Future<void> _download(String url) async {
    try {
      final token = await AppPreferences.getAccessToken();
      final response = await http.get(
        Uri.parse(url),
        headers: token == null || token.isEmpty ? const {} : {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Download failed (${response.statusCode})');
      }
      final uri = Uri.parse(url);
      var fileName = uri.pathSegments.isEmpty ? 'download' : uri.pathSegments.last;
      if (fileName.isEmpty || fileName == 'download') {
        fileName = 'download_${DateTime.now().millisecondsSinceEpoch}';
      }
      final file = File('${Directory.systemTemp.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloaded to ${file.path}')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', '')), backgroundColor: Theme.of(context).colorScheme.error));
    }
  }
}

class _FullScreenImage extends StatelessWidget {
  const _FullScreenImage({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
        body: InteractiveViewer(
          minScale: .5, maxScale: 5,
          child: Center(
            child: AuthenticatedNetworkImage(
              url: url, fit: BoxFit.contain,
              fallback: const Icon(Icons.broken_image_outlined, color: Colors.white, size: 60),
            ),
          ),
        ),
      );
}
