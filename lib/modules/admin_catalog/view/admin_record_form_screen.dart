import 'package:daalsetu/modules/admin_catalog/config/admin_actions.dart';
import 'package:daalsetu/modules/admin_catalog/config/admin_module_config.dart';
import 'package:daalsetu/modules/admin_catalog/model/admin_record.dart';
import 'package:daalsetu/modules/admin_catalog/repository/admin_catalog_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

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
  final multiValues = <String, Set<String>>{};
  final filePaths = <String, String>{};
  final optionFutures = <String, Future<List<AdminOption>>>{};
  bool saving = false;

  bool get editing => widget.record != null;

  Iterable<AdminFieldConfig> get visibleFields => widget.config.fields
      .where((field) => field.hiddenValue == null && !(editing && field.createOnly));

  @override
  void initState() {
    super.initState();
    for (final field in visibleFields) {
      if (field.optionsLoader != null) optionFutures[field.key] = field.optionsLoader!();
      final current = _initialValue(field);
      if (field.multiSelect) {
        multiValues[field.key] = {
          if (current is List)
            for (final item in current) item is Map ? '${item['id']}' : '$item',
        }..removeWhere((value) => value.isEmpty || value == 'null');
      } else if (!field.isFile) {
        controllers[field.key] = TextEditingController(
          text: (current ?? field.defaultValue ?? '').toString(),
        );
      }
    }
  }

  Object? _initialValue(AdminFieldConfig field) {
    final record = widget.record;
    if (record == null) return null;
    if (field.initialValue != null) return field.initialValue!(record.data);
    var current = record[field.key];
    if (current == null && field.key.endsWith('_id')) {
      final relation = record[field.key.substring(0, field.key.length - 3)];
      if (relation is Map) current = relation['id'];
    }
    if (current == null && field.key.endsWith('_ids')) {
      current = record[field.key.substring(0, field.key.length - 4) + 's'];
    }
    if (current is Map) current = current['id'];
    return current;
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
    for (final field in visibleFields) {
      final missingList = field.multiSelect && field.required && (multiValues[field.key] ?? {}).isEmpty;
      final missingFile = field.isFile && field.required && !editing && !filePaths.containsKey(field.key);
      if (missingList || missingFile) {
        _showError('${field.label} is required');
        return;
      }
    }
    setState(() => saving = true);
    final body = <String, dynamic>{};
    for (final field in widget.config.fields) {
      if (field.isFile || (editing && field.createOnly)) continue;
      if (field.multiSelect) {
        body[field.key] = (multiValues[field.key] ?? {}).map((id) => int.tryParse(id) ?? id).toList();
        continue;
      }
      final raw = field.hiddenValue ?? controllers[field.key]?.text.trim() ?? '';
      if (field.singleSelectAsList) {
        body[field.key] = raw.toString().isEmpty
            ? <dynamic>[]
            : <dynamic>[int.tryParse(raw.toString()) ?? raw];
        continue;
      }
      if (field.sendAsBoolean) {
        body[field.key] = raw.toString().toLowerCase() == 'true';
        continue;
      }
      final isChoice = field.options.isNotEmpty || field.optionsLoader != null;
      if (raw.toString().isEmpty && (field.isDate || isChoice)) {
        // An unpicked choice is left out so the backend keeps its default instead of rejecting "".
        if (field.isDate) body[field.key] = null;
        continue;
      }
      body[field.key] = field.numeric && raw.toString().isNotEmpty ? int.tryParse('$raw') ?? raw : raw;
    }
    try {
      final repository = AdminCatalogRepository(widget.config);
      if (editing) {
        await repository.update(widget.config.recordId(widget.record!), body, files: filePaths);
      } else {
        await repository.create(body, files: filePaths);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(editing ? 'Updated successfully' : 'Created successfully')),
      );
      Navigator.pop(context, true);
    } catch (error) {
      _showError(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('${editing ? 'Edit' : 'Create'} ${widget.config.title}')),
        body: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(children: visibleFields.map(_field).toList()),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: saving ? null : save,
                  icon: saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save_outlined),
                  label: Text(editing ? 'Save changes' : 'Create'),
                ),
              ),
            ],
          ),
        ),
      );

  String _label(AdminFieldConfig field) => '${field.label}${field.required ? ' *' : ''}';

  Widget _field(AdminFieldConfig field) {
    final Widget child;
    if (field.isFile) {
      child = _fileField(field);
    } else if (field.optionsLoader != null) {
      child = FutureBuilder<List<AdminOption>>(
        future: optionFutures[field.key],
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return InputDecorator(
              decoration: InputDecoration(labelText: _label(field)),
              child: const LinearProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return InputDecorator(
              decoration: InputDecoration(labelText: _label(field), errorText: 'Could not load choices'),
              child: const SizedBox.shrink(),
            );
          }
          final options = snapshot.data ?? const <AdminOption>[];
          return field.multiSelect ? _multiSelect(field, options) : _dropdown(field, options);
        },
      );
    } else if (field.options.isNotEmpty) {
      final options = field.options.map((value) => AdminOption(value, field.optionLabels[value] ?? value)).toList();
      child = field.multiSelect ? _multiSelect(field, options) : _dropdown(field, options);
    } else if (field.isDate) {
      child = _dateField(field);
    } else {
      child = TextFormField(
        controller: controllers[field.key],
        maxLines: field.multiline ? 4 : 1,
        keyboardType: field.numeric ? TextInputType.number : TextInputType.text,
        inputFormatters: field.numeric ? [FilteringTextInputFormatter.digitsOnly] : null,
        decoration: InputDecoration(labelText: _label(field), alignLabelWithHint: field.multiline),
        validator: (value) =>
            field.required && (value == null || value.trim().isEmpty) ? '${field.label} is required' : null,
      );
    }
    return Padding(padding: const EdgeInsets.only(bottom: 14), child: child);
  }

  Widget _dropdown(AdminFieldConfig field, List<AdminOption> options) {
    final current = controllers[field.key]!.text;
    return DropdownButtonFormField<String>(
      initialValue: options.any((option) => option.value == current) ? current : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: _label(field)),
      items: options
          .map((option) => DropdownMenuItem(
                value: option.value,
                child: Text(option.label, overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: (value) => controllers[field.key]!.text = value ?? '',
      validator: (value) => field.required && value == null ? '${field.label} is required' : null,
    );
  }

  Widget _multiSelect(AdminFieldConfig field, List<AdminOption> options) {
    final selected = multiValues[field.key]!;
    return InputDecorator(
      decoration: InputDecoration(labelText: _label(field), border: const OutlineInputBorder()),
      child: options.isEmpty
          ? const Text('No choices available')
          : Wrap(
              spacing: 8,
              runSpacing: 4,
              children: options
                  .map((option) => FilterChip(
                        label: Text(option.label),
                        selected: selected.contains(option.value),
                        onSelected: (on) => setState(() => on ? selected.add(option.value) : selected.remove(option.value)),
                      ))
                  .toList(),
            ),
    );
  }

  Widget _fileField(AdminFieldConfig field) {
    final path = filePaths[field.key];
    final name = path?.split(RegExp(r'[\\/]')).last;
    final isVideo = field.key.contains('video');
    return OutlinedButton.icon(
      onPressed: () async {
        final picker = ImagePicker();
        final file = isVideo
            ? await picker.pickVideo(source: ImageSource.gallery)
            : await picker.pickImage(source: ImageSource.gallery, imageQuality: 88);
        if (file != null) setState(() => filePaths[field.key] = file.path);
      },
      icon: Icon(isVideo ? Icons.video_file_outlined : Icons.upload_file),
      label: Text(
        name != null ? '${field.label}: $name' : (editing ? '${field.label} (tap to replace)' : _label(field)),
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        alignment: Alignment.centerLeft,
      ),
    );
  }

  /// Date fields open a calendar instead of being typed; expiry dates cannot be in the past.
  Widget _dateField(AdminFieldConfig field) {
    final controller = controllers[field.key]!;
    Future<void> pick() async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final first = field.key.contains('expiry') ? today : DateTime(1950);
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

    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: pick,
      decoration: InputDecoration(
        labelText: _label(field),
        hintText: 'Select date',
        suffixIcon: controller.text.isEmpty || field.required
            ? const Icon(Icons.calendar_month)
            : IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.clear),
                onPressed: () => setState(controller.clear),
              ),
      ),
      validator: (value) =>
          field.required && (value == null || value.trim().isEmpty) ? '${field.label} is required' : null,
    );
  }
}
