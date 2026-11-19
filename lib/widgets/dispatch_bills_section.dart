import 'package:daalsetu/services/dispatch_bill_services.dart';
import 'package:daalsetu/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

/// Asks, before a dispatch, whether to attach bills. Returns the chosen file paths
/// (empty = dispatch without a bill) or null when the user cancels the dispatch.
///
/// Picking files never dispatches by itself: the chosen files are listed and the seller must press
/// "Confirm Dispatch" (or choose other files / remove them / cancel).
Future<List<String>?> askDispatchBills({Future<List<String>> Function()? picker}) async {
  return Get.dialog<List<String>>(DispatchBillsDialog(picker: picker));
}

class DispatchBillsDialog extends StatefulWidget {
  const DispatchBillsDialog({super.key, this.picker});

  /// How files are chosen (the system file picker by default; replaced in tests).
  final Future<List<String>> Function()? picker;

  @override
  State<DispatchBillsDialog> createState() => _DispatchBillsDialogState();
}

class _DispatchBillsDialogState extends State<DispatchBillsDialog> {
  List<String> _paths = [];

  String _name(String path) => path.split(RegExp(r'[\\/]')).last;

  Future<void> _choose() async {
    final picked = await (widget.picker ?? DispatchBillServices.pickBillFiles)();
    if (picked.isEmpty || !mounted) return;
    // Only remembers the choice; nothing is dispatched until the seller confirms.
    setState(() => _paths = picked);
  }

  ButtonStyle _outlined() => OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );

  @override
  Widget build(BuildContext context) {
    final hasFiles = _paths.isNotEmpty;
    return AlertDialog(
      title: const Text('Dispatch Shipment'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Attach the bill (PDF or image)? It is shared with the buyer, transporter and admin.'),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _choose,
              icon: const Icon(Icons.attach_file),
              label: Text(hasFiles ? 'Change Files' : 'Choose Files'),
              style: _outlined(),
            ),
            if (hasFiles) ...[
              const SizedBox(height: 12),
              for (final path in _paths)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        path.toLowerCase().endsWith('.pdf') ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
                        size: 18,
                        color: const Color(0xFFF58220),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_name(path), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      IconButton(
                        tooltip: 'Remove',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() => _paths = _paths.where((p) => p != path).toList()),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      actionsOverflowDirection: VerticalDirection.down,
      actions: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasFiles)
              FilledButton(
                onPressed: () => Get.back(result: _paths),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF05A28),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Confirm Dispatch (${_paths.length} file${_paths.length == 1 ? '' : 's'})'),
              )
            else
              OutlinedButton(
                onPressed: () => Get.back(result: const <String>[]),
                style: _outlined().copyWith(
                  foregroundColor: const WidgetStatePropertyAll(Color(0xFFF05A28)),
                  side: const WidgetStatePropertyAll(BorderSide(color: Color(0xFFF05A28))),
                ),
                child: const Text('Dispatch without bill'),
              ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Get.back(),
              style: _outlined(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Uploads bills chosen for a dispatch; the dispatch itself already succeeded.
Future<void> uploadDispatchBills(int challanId, List<String> paths) async {
  if (paths.isEmpty) return;
  try {
    await DispatchBillServices.upload(challanId, paths);
    AppSnackbar.showSuccess(message: 'Bill uploaded successfully.');
  } catch (error) {
    AppSnackbar.showError(
      message: 'Dispatched, but the bill could not be uploaded: ${error.toString().replaceFirst('Exception: ', '')}',
    );
  }
}

/// "Dispatch Bills" card (MoM point 23): lists the bills of a delivery challan with
/// download buttons, plus "Upload Bill" for the seller / admin once it is dispatched.
/// Pass [challanId] to load them, or [bills] when the list is already known
/// (e.g. a transporter's accepted bid).
class DispatchBillsSection extends StatefulWidget {
  const DispatchBillsSection({super.key, this.challanId, this.bills});

  final int? challanId;
  final List<DispatchBill>? bills;

  @override
  State<DispatchBillsSection> createState() => _DispatchBillsSectionState();
}

class _DispatchBillsSectionState extends State<DispatchBillsSection> {
  List<DispatchBill> _bills = const [];
  bool _canUpload = false;
  bool _loading = false;
  bool _uploading = false;
  int? _downloadingId;

  @override
  void initState() {
    super.initState();
    _bills = widget.bills ?? const [];
    if (widget.challanId != null) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await DispatchBillServices.list(widget.challanId!);
      if (!mounted) return;
      setState(() {
        _bills = result.bills;
        _canUpload = result.canUpload;
      });
    } catch (_) {
      // No access or no bills: the card simply stays empty.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _upload() async {
    final paths = await DispatchBillServices.pickBillFiles();
    if (paths.isEmpty) return;
    setState(() => _uploading = true);
    try {
      await DispatchBillServices.upload(widget.challanId!, paths);
      AppSnackbar.showSuccess(message: 'Bill uploaded successfully.');
      await _load();
    } catch (error) {
      AppSnackbar.showError(message: error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _download(DispatchBill bill) async {
    setState(() => _downloadingId = bill.id);
    try {
      await DispatchBillServices.download(bill);
      AppSnackbar.showSuccess(message: '${bill.fileName} saved to Downloads.');
    } catch (error) {
      AppSnackbar.showError(message: error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _downloadingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Nothing to show while loading, or for a party with no bills and no upload right
    // (no spinner, so the screen settles).
    if (_bills.isEmpty && !_canUpload) return const SizedBox.shrink();
    final theme = Theme.of(context);
    const accent = Color(0xFFF58220);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined, size: 18, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dispatch Bills',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!_loading && _bills.isEmpty)
            Text('No bill uploaded yet.', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
          for (final bill in _bills)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                bill.isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
                color: accent,
              ),
              title: Text(bill.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: bill.uploadedBy.isEmpty ? null : Text('By ${bill.uploadedBy}'),
              trailing: _downloadingId == bill.id
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : IconButton(
                      tooltip: 'Download',
                      icon: const Icon(Icons.download_rounded),
                      onPressed: () => _download(bill),
                    ),
            ),
          if (_canUpload) ...[
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _uploading ? null : _upload,
                icon: _uploading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.upload_file_outlined),
                label: Text(_uploading ? 'Uploading...' : 'Upload Bill (PDF / Image)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: accent,
                  side: const BorderSide(color: accent),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
