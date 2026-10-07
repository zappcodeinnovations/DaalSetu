import 'package:daalsetu/modules/admin_catalog/config/admin_module_config.dart';
import 'package:daalsetu/modules/admin_catalog/model/admin_record.dart';
import 'package:daalsetu/modules/admin_catalog/repository/admin_catalog_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AdminRecordFormScreen extends StatefulWidget {
  const AdminRecordFormScreen({super.key, required this.config, this.record});

  final AdminModuleConfig config;
  final AdminRecord? record;

  @override
  State<AdminRecordFormScreen> createState() => _AdminRecordFormScreenState();
}

class _AdminRecordFormScreenState extends State<AdminRecordFormScreen> {
  final formKey = GlobalKey<FormState>();
  final controllers = <String, TextEditingController>{};
  bool saving = false;

  bool get editing => widget.record != null;

  @override
  void initState() {
    super.initState();
    for (final field in widget.config.fields) {
      if (field.hiddenValue == null) {
        var currentValue = widget.record?[field.key];
        if (currentValue == null && field.key.endsWith('_id')) {
          final relationKey = field.key.substring(0, field.key.length - 3);
          final relation = widget.record?[relationKey];
          if (relation is Map) currentValue = relation['id'];
        }
        controllers[field.key] = TextEditingController(
          text: (currentValue ?? field.defaultValue ?? '').toString(),
        );
      }
    }
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);
    final body = <String, dynamic>{};
    for (final field in widget.config.fields) {
      final raw =
          field.hiddenValue ?? controllers[field.key]?.text.trim() ?? '';
      
      if (raw.toString().isEmpty && field.isDate) {
        body[field.key] = null;
      } else {
        body[field.key] = field.numeric && raw.toString().isNotEmpty
            ? int.tryParse('$raw')
            : raw;
      }
    }
    try {
      final repository = AdminCatalogRepository(widget.config);
      if (editing) {
        await repository.update(widget.record!.id, body);
      } else {
        await repository.create(body);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            editing ? 'Updated successfully' : 'Created successfully',
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('${editing ? 'Edit' : 'Create'} ${widget.config.title}'),
    ),
    body: Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: widget.config.fields
                    .where((field) => field.hiddenValue == null)
                    .map(_field)
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: saving ? null : save,
              icon: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(editing ? 'Save changes' : 'Create'),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _field(AdminFieldConfig field) {
    if (field.options.isNotEmpty) {
      final current = controllers[field.key]!.text;
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: DropdownButtonFormField<String>(
          initialValue: field.options.contains(current) ? current : null,
          decoration: InputDecoration(labelText: field.label),
          items: field.options
              .map(
                (value) => DropdownMenuItem(value: value, child: Text(value)),
              )
              .toList(),
          onChanged: (value) => controllers[field.key]!.text = value ?? '',
          validator: (value) => field.required && value == null
              ? '${field.label} is required'
              : null,
        ),
      );
    }
    if (field.isDate) return _dateField(field);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controllers[field.key],
        maxLines: field.multiline ? 4 : 1,
        keyboardType: field.numeric ? TextInputType.number : TextInputType.text,
        inputFormatters: field.numeric
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        decoration: InputDecoration(
          labelText: '${field.label}${field.required ? ' *' : ''}',
          alignLabelWithHint: field.multiline,
        ),
        validator: (value) {
          if (field.required && (value == null || value.trim().isEmpty)) {
            return '${field.label} is required';
          }
          return null;
        },
      ),
    );
  }

  /// Date fields open a calendar instead of being typed; expiry dates cannot be in the past.
  Widget _dateField(AdminFieldConfig field) {
    final controller = controllers[field.key]!;
    Future<void> pick() async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final isExpiry = field.key.contains('expiry');
      final first = isExpiry ? today : DateTime(1950);
      final existing = DateTime.tryParse(controller.text);
      final picked = await showDatePicker(
        context: context,
        initialDate: existing != null && !existing.isBefore(first) ? existing : today,
        firstDate: first,
        lastDate: DateTime(now.year + 25),
      );
      if (picked != null) {
        setState(() => controller.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: pick,
        decoration: InputDecoration(
          labelText: '${field.label}${field.required ? ' *' : ''}',
          hintText: 'Select date',
          suffixIcon: controller.text.isEmpty || field.required
              ? const Icon(Icons.calendar_month)
              : IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(controller.clear),
                ),
        ),
        validator: (value) {
          if (field.required && (value == null || value.trim().isEmpty)) {
            return '${field.label} is required';
          }
          return null;
        },
      ),
    );
  }
}
