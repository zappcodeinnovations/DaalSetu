import 'package:flutter/material.dart';

/// One choice in [AssignPickerSheet] (a driver or a vehicle).
class AssignPickerItem {
  const AssignPickerItem({required this.id, required this.title, this.subtitle = ''});

  final Object id;
  final String title;
  final String subtitle;

  /// Text shown in the closed drop-down and in the list.
  String get label => subtitle.isEmpty ? title : '$title  -  $subtitle';
}

/// Equal-width action buttons for a confirm dialog: the primary action on the left, Cancel on the right,
/// both exactly the same size.
class PairedDialogActions extends StatelessWidget {
  const PairedDialogActions({
    super.key,
    required this.confirmText,
    required this.onConfirm,
    required this.onCancel,
    this.cancelText = 'Cancel',
    this.confirmColor = const Color(0xFFF05A28),
  });

  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final Color confirmColor;

  @override
  Widget build(BuildContext context) {
    const shapeRadius = 12.0;
    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: onConfirm,
            style: FilledButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(shapeRadius)),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            child: Text(confirmText),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(shapeRadius)),
            ),
            child: Text(cancelText),
          ),
        ),
      ],
    );
  }
}

/// Shows a themed confirm dialog with equal-size buttons. True when the user confirms.
Future<bool> confirmAssignment(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmText,
  Color confirmColor = const Color(0xFFF05A28),
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actions: [
        PairedDialogActions(
          confirmText: confirmText,
          confirmColor: confirmColor,
          onConfirm: () => Navigator.pop(dialogContext, true),
          onCancel: () => Navigator.pop(dialogContext, false),
        ),
      ],
    ),
  );
  return result == true;
}

/// The Assign Driver / Assign Vehicle bottom sheet: who is assigned now, a compact drop-down of what can be
/// assigned (works for 100+ entries), an explicit Assign button and, when something is assigned, Unassign.
class AssignPickerSheet extends StatefulWidget {
  const AssignPickerSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.noun,
    required this.items,
    required this.loading,
    required this.saving,
    required this.onAssign,
    this.error,
    this.onRetry,
    this.currentLabel,
    this.onUnassign,
    this.emptyText,
    required this.onClose,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  /// "driver" or "vehicle" (used in labels).
  final String noun;
  final List<AssignPickerItem> items;
  final bool loading;
  final bool saving;
  final String? error;
  final VoidCallback? onRetry;
  final String? currentLabel;
  final void Function(AssignPickerItem item) onAssign;
  final VoidCallback? onUnassign;
  final String? emptyText;
  final VoidCallback onClose;

  @override
  State<AssignPickerSheet> createState() => _AssignPickerSheetState();
}

class _AssignPickerSheetState extends State<AssignPickerSheet> {
  Object? _selectedId;

  AssignPickerItem? get _selected {
    for (final item in widget.items) {
      if (item.id == _selectedId) return item;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFDF8);
    final card = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFFFE0B2);
    final primaryText = isDark ? Colors.white : const Color(0xFF111827);
    final mutedText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final hasCurrent = (widget.currentLabel ?? '').trim().isNotEmpty;

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .78),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEA580C), Color(0xFFF57C00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Icon(widget.icon, color: const Color(0xFFEA580C), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: widget.saving ? null : widget.onClose,
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _content(
                  isDark: isDark,
                  card: card,
                  border: border,
                  primaryText: primaryText,
                  mutedText: mutedText,
                  hasCurrent: hasCurrent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content({
    required bool isDark,
    required Color card,
    required Color border,
    required Color primaryText,
    required Color mutedText,
    required bool hasCurrent,
  }) {
    if (widget.loading) {
      return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()));
    }
    if (widget.error != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Could not load ${widget.noun}s', style: TextStyle(color: primaryText, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(widget.error!, textAlign: TextAlign.center, style: TextStyle(color: mutedText)),
          const SizedBox(height: 12),
          if (widget.onRetry != null)
            OutlinedButton.icon(onPressed: widget.onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
        ],
      );
    }

    final selected = _selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: const Color(0xFFF57C00)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Currently assigned ${widget.noun}', style: TextStyle(color: mutedText, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      hasCurrent ? widget.currentLabel! : 'No ${widget.noun} assigned',
                      style: TextStyle(
                        color: primaryText,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (widget.items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              widget.emptyText ?? 'No ${widget.noun} is available to assign.',
              textAlign: TextAlign.center,
              style: TextStyle(color: mutedText),
            ),
          )
        else
          DropdownButtonFormField<Object>(
            key: ValueKey('${widget.noun}-$_selectedId'),
            initialValue: selected?.id,
            isExpanded: true,
            menuMaxHeight: 320,
            dropdownColor: card,
            style: TextStyle(color: primaryText),
            decoration: InputDecoration(
              labelText: 'Select ${widget.noun}',
              filled: true,
              fillColor: card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: [
              for (final item in widget.items)
                DropdownMenuItem<Object>(
                  value: item.id,
                  child: Text(item.label, overflow: TextOverflow.ellipsis, style: TextStyle(color: primaryText)),
                ),
            ],
            onChanged: widget.saving ? null : (value) => setState(() => _selectedId = value),
          ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: widget.saving || selected == null ? null : () => widget.onAssign(selected),
          icon: widget.saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check_circle_outline),
          label: Text('Assign ${widget.noun[0].toUpperCase()}${widget.noun.substring(1)}'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFF05A28),
            foregroundColor: Colors.white,
            disabledBackgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        if (hasCurrent && widget.onUnassign != null) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: widget.saving ? null : widget.onUnassign,
            icon: const Icon(Icons.link_off),
            label: Text('Unassign ${widget.noun[0].toUpperCase()}${widget.noun.substring(1)}'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ],
    );
  }
}
