import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/admin_common_widgets.dart';
import '../../../widgets/app_shell.dart';
import '../../admin_catalog/view/admin_drawer.dart';
import '../model/downloaded_file.dart';
import '../service/downloads_service.dart';

class DownloadsView extends StatefulWidget {
  const DownloadsView({super.key});

  @override
  State<DownloadsView> createState() => _DownloadsViewState();
}

class _DownloadsViewState extends State<DownloadsView> {
  final _searchController = TextEditingController();
  List<DownloadedFile> _files = const [];
  bool _loading = true;
  String? _error;
  String _query = '';

  List<DownloadedFile> get _visibleFiles {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _files;
    return _files
        .where((file) => file.name.toLowerCase().contains(query))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final files = await DownloadsService.listFiles();
      if (!mounted) return;
      setState(() => _files = files);
    } catch (error) {
      debugPrint('📂 Downloads list failed: $error');
      if (!mounted) return;
      setState(() => _error = 'Downloads could not be loaded.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(DownloadedFile file) async {
    try {
      final opened = await DownloadsService.open(file);
      if (!opened && mounted) {
        _showMessage('No app is available to open this file.', error: true);
      }
    } catch (_) {
      if (mounted) _showMessage('This file could not be opened.', error: true);
    }
  }

  Future<void> _delete(DownloadedFile file) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            icon: Icon(
              Icons.delete_outline_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            title: const Text('Delete download?'),
            content: Text(
              '“${file.name}” will be permanently removed from Downloads.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    try {
      final deleted = await DownloadsService.delete(file);
      if (!mounted) return;
      if (!deleted) {
        _showMessage('File could not be deleted.', error: true);
        return;
      }
      setState(
        () => _files = _files
            .where((item) => item.target != file.target)
            .toList(),
      );
      _showMessage('Download deleted.');
    } catch (_) {
      if (mounted) _showMessage('File could not be deleted.', error: true);
    }
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminDrawer(activeKey: 'downloads'),
      appBar: AppBar(
        leading: const AppBarLeading(),
        leadingWidth: AppBarLeading.widthFor(context),
        title: const Text('Downloads'),
        actions: [
          IconButton(
            tooltip: 'Refresh downloads',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: AdminSearchBar(
                controller: _searchController,
                hint: 'Search downloaded files',
                onChanged: (value) => setState(() => _query = value),
                onClear: () => setState(() => _query = ''),
              ),
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const AdminLoadingWidget();
    // A failed lookup reads the same as an empty folder (the reason is logged).
    if (_error != null || _visibleFiles.isEmpty) return _emptyState();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        itemCount: _visibleFiles.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _fileCard(_visibleFiles[index]),
      ),
    );
  }

  Widget _emptyState() {
    final theme = Theme.of(context);
    final searching = _query.isNotEmpty && _files.isNotEmpty;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(32, 96, 32, 24),
        children: [
          Icon(Icons.folder_open_outlined, size: 56, color: theme.colorScheme.primary),
          const SizedBox(height: 14),
          Text(
            searching ? 'No matching files' : 'No downloaded files right now',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            searching
                ? 'Try a different name.'
                : 'PDFs and Excel files you download in the app will appear here.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _fileCard(DownloadedFile file) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _open(file),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 8, 13),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGold.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(
                  _iconFor(file),
                  color: AppTheme.primaryGold,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_formatSize(file.size)} • ${DateFormat('dd MMM yyyy, hh:mm a').format(file.modifiedAt.toLocal())}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Open file',
                onPressed: () => _open(file),
                icon: const Icon(Icons.visibility_outlined),
              ),
              IconButton(
                tooltip: 'Delete file',
                onPressed: () => _delete(file),
                color: theme.colorScheme.error,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(DownloadedFile file) {
    if (file.mimeType.contains('pdf')) {
      return Icons.picture_as_pdf_outlined;
    }
    if (file.mimeType.contains('sheet') ||
        file.mimeType.contains('excel') ||
        file.mimeType.contains('csv')) {
      return Icons.table_chart_outlined;
    }
    if (file.mimeType.startsWith('image/')) {
      return Icons.image_outlined;
    }
    if (file.mimeType.startsWith('video/')) {
      return Icons.play_circle_outline_rounded;
    }
    return Icons.insert_drive_file_outlined;
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
