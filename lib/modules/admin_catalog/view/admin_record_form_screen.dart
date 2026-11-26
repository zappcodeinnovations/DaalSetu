import 'package:daalsetu/modules/admin_catalog/config/admin_actions.dart';
import 'package:daalsetu/modules/admin_catalog/config/admin_module_config.dart';
import 'package:daalsetu/modules/admin_catalog/model/admin_record.dart';
import 'package:daalsetu/modules/admin_catalog/repository/admin_catalog_repository.dart';
import 'package:daalsetu/modules/admin_catalog/view/admin_permission_toggle_panel.dart';
import 'package:daalsetu/modules/admin_catalog/view/admin_roles_screen.dart';
import 'package:daalsetu/network/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:daalsetu/theme/app_theme.dart';
import 'package:daalsetu/utils/app_date.dart';
import 'package:daalsetu/utils/app_preferences.dart';
import 'package:daalsetu/utils/input_validators.dart';
import 'package:daalsetu/utils/tax_id_formatters.dart';
import 'package:daalsetu/widgets/hero_header.dart';
import '../../../utils/app_snackbar.dart';
import 'package:daalsetu/widgets/back_navigation.dart';

class AdminRecordFormScreen extends StatefulWidget {
  const AdminRecordFormScreen({
    super.key,
    required this.config,
    this.record,
    this.userRole,
  });

  final AdminModuleConfig config;
  final AdminRecord? record;
  final String? userRole;

  @override
  State<AdminRecordFormScreen> createState() => _AdminRecordFormScreenState();
}

class _AdminRecordFormScreenState extends State<AdminRecordFormScreen> {
  final formKey = GlobalKey<FormState>();
  final controllers = <String, TextEditingController>{};
  final multiValues = <String, Set<String>>{};
  final filePaths = <String, String>{};
  final optionFutures = <String, Future<List<AdminOption>>>{};
  final serverErrors = <String, String>{};
  bool saving = false;
  bool creatingRole = false;
  String _userRole = '';

  bool get editing => widget.record != null;

  bool _isRequired(AdminFieldConfig field) =>
      field.required && (!editing || field.requiredOnEdit);

  Iterable<AdminFieldConfig> get visibleFields => widget.config.fields.where(
    (field) {
      if (field.hiddenValue != null || (editing && field.createOnly)) return false;
      // Bug 3: The unnecessary "Under Admin" dropdown field should be completely removed
      // across Seller, Buyer, and Transporter mobile apps.
      if (field.key == 'parent_admin_id') {
        final role = _userRole;
        if (role == 'seller' || role == 'buyer' || role == 'transporter') {
          return false;
        }
      }
      return true;
    },
  );

  @override
  void initState() {
    super.initState();
    _userRole = widget.userRole?.trim().toLowerCase() ?? '';
    if (_userRole.isEmpty) {
      AppPreferences.getRole().then((role) {
        if (mounted && role != null) {
          setState(() => _userRole = role.trim().toLowerCase());
        }
      });
    }
    for (final field in visibleFields) {
      if (field.optionsLoader != null) {
        optionFutures[field.key] = field.optionsLoader!();
      }
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
        if (!editing && field.defaultLoader != null) _fillDefault(field);
      }
    }
  }

  /// Fills a new record's field from the server (never over something the user already typed).
  Future<void> _fillDefault(AdminFieldConfig field) async {
    try {
      final value = await field.defaultLoader!();
      final controller = controllers[field.key];
      if (!mounted || controller == null || value == null || value.isEmpty) return;
      if (controller.text.trim().isEmpty) controller.text = value;
    } catch (_) {
      // The field simply stays empty: it is optional.
    }
  }

  Object? _initialValue(AdminFieldConfig field) {
    final record = widget.record;
    if (record == null) return null;
    if (field.initialValue != null) return field.initialValue!(record.data);
    var current = record[field.key];
    if (field.key == 'status' && (current == null || current.toString().isEmpty)) {
      if (record['status'] != null) {
        current = record['status'].toString().toLowerCase();
      } else if (record['is_active'] == true) {
        current = 'active';
      } else if (record['is_active'] == false) {
        current = 'pending';
      }
    }
    if (field.key == 'mapped_brands') {
      current = record['mapped_brands'] ??
          record['brands'] ??
          record['brand_ids'] ??
          record['mapped_brand_ids'];
    }
    if (current == null && field.key.endsWith('_id')) {
      final relation = record[field.key.substring(0, field.key.length - 3)];
      if (relation is Map) current = relation['id'];
    }
    if (current == null && field.key.endsWith('_ids')) {
      current = record['${field.key.substring(0, field.key.length - 4)}s'];
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

  /// Wipes all form fields clean so fresh empty placeholders are ready for the next entry.
  void resetForm() {
    formKey.currentState?.reset();
    for (final field in visibleFields) {
      if (field.multiSelect) {
        multiValues[field.key]?.clear();
      } else if (!field.isFile) {
        final ctrl = controllers[field.key];
        if (ctrl != null) {
          ctrl.text = (field.defaultValue ?? '').toString();
        }
      }
    }
    filePaths.clear();
    serverErrors.clear();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    for (final field in visibleFields) {
      final missingList =
          field.multiSelect &&
          _isRequired(field) &&
          (multiValues[field.key] ?? {}).isEmpty;
      final missingFile =
          field.isFile &&
          _isRequired(field) &&
          !editing &&
          !filePaths.containsKey(field.key);
      if (missingList || missingFile) {
        _showError('${field.label} is required');
        return;
      }
    }
    setState(() {
      saving = true;
      serverErrors.clear();
    });
    final body = <String, dynamic>{};
    for (final field in widget.config.fields) {
      if (field.isFile || field.derivedFrom != null || (editing && field.createOnly)) continue;
      if (field.key == 'parent_admin_id' && (_userRole == 'seller' || _userRole == 'buyer' || _userRole == 'transporter')) continue;
      if (field.multiSelect) {
        final list = (multiValues[field.key] ?? {})
            .map((id) => int.tryParse(id) ?? id)
            .toList();
        body[field.key] = list;
        if (field.key == 'mapped_brands') {
          body['brands'] = list;
        }
        continue;
      }
      final raw =
          field.hiddenValue ?? controllers[field.key]?.text.trim() ?? '';
      if (field.key == 'status' &&
          (widget.config.key == 'sub_categories' ||
              widget.config.key == 'categories')) {
        body['status'] = raw.toString().toLowerCase();
        body['is_active'] = raw.toString().toLowerCase() == 'active';
        continue;
      }
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
      final isPhoneField =
          field.key.contains('phone') || field.key.contains('mobile');
      if (isPhoneField) {
        body[field.key] = raw.toString();
        continue;
      }
      if (field.numeric) {
        if (raw.toString().isEmpty) {
          // Send null instead of empty string "" so DRF IntegerField doesn't reject with "A valid integer is required."
          body[field.key] = null;
        } else {
          body[field.key] = int.tryParse('$raw') ?? raw;
        }
        continue;
      }
      if (field.key == 'vehicle_number' || field.key == 'rc_number') {
        body[field.key] = InputValidators.compactVehicleNumber(raw.toString());
        continue;
      }
      if (field.key == 'license_number') {
        body[field.key] = InputValidators.compactLicenseNumber(raw.toString());
        continue;
      }
      body[field.key] = raw;
    }
    try {
      final repository = AdminCatalogRepository(widget.config);
      if (editing) {
        await repository.update(
          widget.config.recordId(widget.record!),
          body,
          files: filePaths,
        );
      } else {
        await repository.create(body, files: filePaths);
        resetForm();
      }
      if (!mounted) return;
      AppSnackbar.showSnackBar(context, 
        SnackBar(
          content: Text(
            editing ? 'Updated successfully' : 'Created successfully',
          ),
        ),
      );
      Navigator.pop(context, true);
    } on ApiRequestException catch (error) {
      if (error.fieldErrors != null && error.fieldErrors!.isNotEmpty) {
        setState(() {
          serverErrors.clear();
          for (final entry in error.fieldErrors!.entries) {
            var msg = entry.value;
            if (msg.toLowerCase().contains('a valid integer is required') ||
                msg.toLowerCase().contains('valid integer is required')) {
              msg = 'Please enter a valid number';
            }
            serverErrors[entry.key] = msg;
          }
        });
        formKey.currentState?.validate();
      }
      _showError(error.message);
    } catch (error) {
      _showError(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    AppSnackbar.showSnackBar(context, 
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: HeroHeader(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => goBackOrHome(context),
        ),
        title: '${editing ? 'Edit' : 'Create'} ${widget.config.title}',
        subtitle: 'Configure catalog and system parameters',
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: isDark ? AppTheme.borderColor : const Color(0xFFFFE0B2),
                  width: 1.2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(children: visibleFields.map(_field).toList()),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: saving ? null : const LinearGradient(
                  colors: [
                    Color(0xFFE65100),
                    Color(0xFFF57C00),
                    Color(0xFFFFA000),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                color: saving ? Colors.grey : null,
                borderRadius: BorderRadius.circular(14),
                boxShadow: saving ? null : [
                  BoxShadow(
                    color: const Color(0xFFE65100).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: saving ? null : save,
                  child: Center(
                    child: saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.save_outlined, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                editing ? 'Save changes' : 'Create',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _label(AdminFieldConfig field) =>
      '${field.label}${_isRequired(field) ? ' *' : ''}';

  bool _canCreateRole(AdminFieldConfig field) =>
      widget.config.key == 'salesman' && field.key == 'access_role_ids';

  void _reloadOptions(AdminFieldConfig field) {
    final loader = field.optionsLoader;
    if (loader == null) return;
    setState(() => optionFutures[field.key] = loader());
  }

  Future<void> _createRole(AdminFieldConfig field) async {
    if (creatingRole) return;
    setState(() => creatingRole = true);
    try {
      final response = await ApiClient.get(
        endpoint: '/api/admin/roles/',
        requireAuth: true,
      );
      if (response is! Map) {
        throw Exception('Role permissions could not be loaded.');
      }
      final categories = permissionCategoryList(
        response['permission_categories'],
      );
      if (!mounted) return;
      final created = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) =>
              AdminRoleEditorScreen(permissionCategories: categories),
        ),
      );
      if (created == true && mounted) {
        _reloadOptions(field);
        AppSnackbar.showSnackBar(context, 
          const SnackBar(
            content: Text('Role created. Select it below for this Sub Admin.'),
          ),
        );
      }
    } catch (error) {
      _showError(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => creatingRole = false);
    }
  }

  Widget _field(AdminFieldConfig field) {
    final Widget child;
    if (field.isFile) {
      child = _fileField(field);
    } else if (field.derivedFrom != null) {
      // Filled automatically from the driver picked above (same as the web form); not editable.
      child = TextFormField(
        controller: controllers[field.key],
        readOnly: true,
        decoration: InputDecoration(
          labelText: field.label,
          hintText: 'Auto-filled from the selected driver',
          filled: true,
        ),
      );
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
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: _label(field),
                    errorText: 'Could not load choices',
                  ),
                  child: const SizedBox.shrink(),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _reloadOptions(field),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                    if (_canCreateRole(field)) _createRoleButton(field),
                  ],
                ),
              ],
            );
          }
          final options = snapshot.data ?? const <AdminOption>[];
          return field.multiSelect
              ? _multiSelect(field, options)
              : _dropdown(field, options);
        },
      );
    } else if (field.options.isNotEmpty) {
      final options = field.options
          .map(
            (value) => AdminOption(value, field.optionLabels[value] ?? value),
          )
          .toList();
      child = field.multiSelect
          ? _multiSelect(field, options)
          : _dropdown(field, options);
    } else if (field.isDate) {
      child = _dateField(field);
    } else {
      final isPhoneField =
          field.key.contains('phone') || field.key.contains('mobile');
      final isEmailField = field.key == 'email' || field.key.endsWith('_email');
      final taxFormatter = field.key == 'pan_number'
          ? const TaxIdInputFormatter.pan()
          : field.key == 'gst_number'
          ? const TaxIdInputFormatter.gst()
          : null;
      final isVehicleNumberField = field.key == 'vehicle_number' || field.key == 'rc_number';
      final isLicenseField = field.key == 'license_number';
      final isReadOnly = field.readOnly || field.key == 'branch_ref_code' || field.derivedFrom != null;
      child = TextFormField(
        controller: controllers[field.key],
        readOnly: isReadOnly,
        textCapitalization: isVehicleNumberField || isLicenseField
            ? TextCapitalization.characters
            : TextCapitalization.none,
        maxLines: field.multiline ? 4 : 1,
        keyboardType: field.numeric
            ? TextInputType.number
            : isEmailField
            ? TextInputType.emailAddress
            : TextInputType.text,
        autocorrect: !isEmailField,
        inputFormatters: taxFormatter != null
            ? [taxFormatter]
            : field.numeric
            ? [FilteringTextInputFormatter.digitsOnly]
            : isVehicleNumberField
            ? [IndianIdInputFormatter.vehicle()]
            : isLicenseField
            ? [IndianIdInputFormatter.license()]
            : null,
        maxLength: field.key == 'gst_number'
            ? 15
            : isPhoneField
            ? 10
            : isVehicleNumberField
            ? 10
            : null,
        buildCounter:
            (
              context, {
              required currentLength,
              required isFocused,
              maxLength,
            }) => null,
        decoration: InputDecoration(
          labelText: _label(field),
          filled: isReadOnly ? true : null,
          fillColor: isReadOnly
              ? (Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFF1F5F9))
              : null,
          hintText: isVehicleNumberField
              ? 'e.g., MH31 AB 1234'
              : (field.key == 'license_number' ? 'e.g., MH12 20110012345' : (field.key == 'branch_ref_code' ? 'Read-only branch code' : null)),
          alignLabelWithHint: field.multiline,
          counterText: '',
          errorText: serverErrors[field.key],
          // Show the whole message, never "...".
          errorMaxLines: 3,
        ),
        onChanged: (val) {
          if (serverErrors.containsKey(field.key)) {
            setState(() => serverErrors.remove(field.key));
          }
        },
        validator: (value) {
          if (isReadOnly) return null;
          if (serverErrors[field.key] != null) {
            return serverErrors[field.key];
          }
          if (isPhoneField && value != null && value.trim().isNotEmpty) {
            if (value.trim().length != 10) {
              return 'Phone number must be 10 digits';
            }
          }
          if (isVehicleNumberField && value != null && value.trim().isNotEmpty) {
            final cleaned = value.trim().replaceAll(RegExp(r'[\s-]'), '');
            if (cleaned.length != 10) {
              return 'RC number must be 10 characters (e.g., MH31AB1234)';
            }
          }
          if (field.numeric && value != null && value.trim().isNotEmpty) {
            if (int.tryParse(value.trim()) == null) {
              return 'Please enter a valid number';
            }
          }
          final emailError = isEmailField
              ? InputValidators.email(value, required: _isRequired(field))
              : null;
          final taxError = field.key == 'pan_number'
              ? TaxIdValidator.pan(value, required: _isRequired(field))
              : field.key == 'gst_number'
              ? TaxIdValidator.gst(value, required: _isRequired(field))
              : null;
          final nameError = field.key == 'first_name' || field.key == 'last_name'
              ? InputValidators.personName(value, label: field.label)
              : null;
          final formatError = isVehicleNumberField
              ? InputValidators.vehicleNumber(
                  value,
                  label: field.label.split('(').first.trim(),
                  required: _isRequired(field),
                )
              : isLicenseField
              ? InputValidators.licenseNumber(value, required: _isRequired(field))
              : null;
          return emailError ??
              taxError ??
              nameError ??
              formatError ??
              (_isRequired(field) && (value == null || value.trim().isEmpty)
                  ? '${field.label} is required'
                  : null);
        },
      );
    }
    return Padding(padding: const EdgeInsets.only(bottom: 14), child: child);
  }

  Widget _dropdown(AdminFieldConfig field, List<AdminOption> options) {
    final current = controllers[field.key]!.text;
    return DropdownButtonFormField<String>(
      initialValue: options.any((option) => option.value == current)
          ? current
          : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: _label(field),
        errorText: serverErrors[field.key],
      ),
      items: options
          .map(
            (option) => DropdownMenuItem(
              value: option.value,
              child: Text(option.label, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (value) {
        controllers[field.key]!.text = value ?? '';
        // Fields that mirror this choice (e.g. the driver's phone and licence number) follow it.
        final picked = options.where((option) => option.value == value);
        final extras = picked.isEmpty ? const <String, String>{} : picked.first.extras;
        for (final other in widget.config.fields) {
          if (other.derivedFrom == field.key) {
            controllers[other.key]?.text = extras[other.derivedKey] ?? '';
          }
        }
        setState(() {
          serverErrors.remove(field.key);
        });
      },
      validator: (value) {
        if (serverErrors[field.key] != null) {
          return serverErrors[field.key];
        }
        return _isRequired(field) && (value == null || value.isEmpty)
            ? '${field.label} is required'
            : null;
      },
    );
  }

  Widget _multiSelect(AdminFieldConfig field, List<AdminOption> options) {
    final selected = multiValues[field.key]!;
    final roleField = _canCreateRole(field);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InputDecorator(
          decoration: InputDecoration(
            labelText: _label(field),
            helperText: roleField
                ? 'Select at least one role for this Sub Admin.'
                : null,
            border: const OutlineInputBorder(),
          ),
          child: options.isEmpty
              ? Text(
                  roleField
                      ? 'No roles available. Create a role first.'
                      : 'No choices available',
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: options
                      .map(
                        (option) => FilterChip(
                          label: Text(option.label),
                          selected: selected.contains(option.value),
                          onSelected: (on) => setState(
                            () => on
                                ? selected.add(option.value)
                                : selected.remove(option.value),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        if (roleField) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: _createRoleButton(field),
          ),
        ],
      ],
    );
  }

  Widget _createRoleButton(AdminFieldConfig field) => OutlinedButton.icon(
    onPressed: creatingRole ? null : () => _createRole(field),
    icon: creatingRole
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.add_moderator_outlined),
    label: Text(creatingRole ? 'Opening...' : 'Create New Role'),
  );

  Widget _fileField(AdminFieldConfig field) {
    final path = filePaths[field.key];
    final name = path?.split(RegExp(r'[\\/]')).last;
    final isVideo = field.key.contains('video');
    final button = OutlinedButton.icon(
      onPressed: () async {
        final picker = ImagePicker();
        final file = isVideo
            ? await picker.pickVideo(source: ImageSource.gallery)
            : await picker.pickImage(
                source: ImageSource.gallery,
                imageQuality: 88,
              );
        if (file != null) setState(() => filePaths[field.key] = file.path);
      },
      icon: Icon(isVideo ? Icons.video_file_outlined : Icons.upload_file),
      label: Text(
        name != null
            ? '${field.label}: $name'
            : (editing ? '${field.label} (tap to replace)' : _label(field)),
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        alignment: Alignment.centerLeft,
      ),
    );

    if (name == null) return button;

    return Row(
      children: [
        Expanded(child: button),
        const SizedBox(width: 6),
        IconButton(
          tooltip: 'Remove document',
          icon: const Icon(Icons.close_rounded, color: Colors.redAccent),
          onPressed: () => setState(() => filePaths.remove(field.key)),
        ),
      ],
    );
  }

  /// Date fields open a calendar instead of being typed; expiry dates cannot be in the past.
  Widget _dateField(AdminFieldConfig field) {
    final controller = controllers[field.key]!;
    Future<void> pick() async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final first = field.key.contains('expiry') ? today : DateTime(1950);
      final existing = AppDate.parse(controller.text);
      final picked = await showDatePicker(
        context: context,
        initialDate: existing != null && !existing.isBefore(first)
            ? existing
            : today,
        firstDate: first,
        lastDate: DateTime(now.year + 25),
      );
      if (picked != null) {
        // The controller keeps the API format (yyyy-MM-dd); the field shows dd/MM/yyyy.
        setState(() => controller.text = AppDate.apiDate(picked));
      }
    }

    return TextFormField(
      key: ValueKey('${field.key}-${controller.text}'),
      initialValue: AppDate.date(controller.text, empty: ''),
      readOnly: true,
      onTap: pick,
      decoration: InputDecoration(
        labelText: _label(field),
        hintText: 'Select date',
        errorText: serverErrors[field.key],
        suffixIcon: controller.text.isEmpty || _isRequired(field)
            ? const Icon(Icons.calendar_month)
            : IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(controller.clear);
                  if (serverErrors.containsKey(field.key)) {
                    setState(() => serverErrors.remove(field.key));
                  }
                },
              ),
      ),
      validator: (value) {
        if (serverErrors[field.key] != null) {
          return serverErrors[field.key];
        }
        return _isRequired(field) && (value == null || value.trim().isEmpty)
            ? '${field.label} is required'
            : null;
      },
    );
  }
}

