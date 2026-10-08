import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/glass_widgets.dart';
import '../../../utils/tax_id_formatters.dart';
import '../controller/profile_controller.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ProfileController controller = Get.find<ProfileController>();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _genderController;
  late TextEditingController _dobController;
  late TextEditingController _panController;
  late TextEditingController _gstController;
  final ImagePicker _picker = ImagePicker();
  XFile? _profileImage;
  XFile? _panDocument;
  XFile? _gstDocument;
  XFile? _aadhaarDocument;

  @override
  void initState() {
    super.initState();
    final user = controller.profile.value;

    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');

    String initialGender = 'Male';
    if (user != null && user.gender.isNotEmpty) {
      final g = user.gender.toLowerCase();
      if (g == 'female') {
        initialGender = 'Female';
      } else if (g == 'other') {
        initialGender = 'Other';
      } else {
        initialGender = 'Male';
      }
    }
    _genderController = TextEditingController(text: initialGender);
    _dobController = TextEditingController(text: user?.dob ?? '');
    _panController = TextEditingController(text: user?.panNumber ?? '');
    _gstController = TextEditingController(text: user?.gstNumber ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _genderController.dispose();
    _dobController.dispose();
    _panController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.black,
              surface: const Color(0xFF161C2C),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _pickImage(String type) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    setState(() {
      switch (type) {
        case 'profile':
          _profileImage = picked;
          break;
        case 'pan':
          _panDocument = picked;
          break;
        case 'gst':
          _gstDocument = picked;
          break;
        case 'aadhaar':
          _aadhaarDocument = picked;
          break;
      }
    });
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final gstPanError = TaxIdValidator.gstMatchesPan(
      _panController.text,
      _gstController.text,
    );
    if (gstPanError != null) {
      Get.snackbar('Invalid GST number', gstPanError);
      return;
    }

    final data = <String, dynamic>{
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'gender': _genderController.text.trim().toLowerCase(),
    };

    if (_dobController.text.trim().isNotEmpty) {
      data['dob'] = _dobController.text.trim();
    }
    final pan = _panController.text.trim().toUpperCase();
    if (pan.isNotEmpty) {
      data['pan_number'] = pan;
    }

    final gst = _gstController.text.trim().toUpperCase();
    if (gst.isNotEmpty) data['gst_number'] = gst;

    final files = <String, String>{
      if (_profileImage != null) 'profile_image': _profileImage!.path,
      if (_panDocument != null) 'pan_image': _panDocument!.path,
      if (_gstDocument != null) 'gst_image': _gstDocument!.path,
      if (_aadhaarDocument != null) 'adharcard_image': _aadhaarDocument!.path,
    };
    final success = files.isEmpty
        ? await controller.updateProfile(data)
        : await controller.updateProfileWithFiles(
            fields: data.map((key, value) => MapEntry(key, '$value')),
            files: files,
          );
    if (success) {
      await Get.dialog<void>(
        AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 10),
              Expanded(child: Text("Profile Updated")),
            ],
          ),
          content: const Text(
            "Your profile changes have been saved successfully.",
          ),
          actions: [
            FilledButton(
              onPressed: () => Get.back(),
              child: const Text("Done"),
            ),
          ],
        ),
        barrierDismissible: false,
      );
      if (mounted) Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(IconlyLight.arrow_left, color: theme.iconTheme.color),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Edit Profile",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          DecoCircle(
            size: 250,
            color: theme.colorScheme.primary,
            alignment: Alignment.topRight,
            offset: const Offset(50, -50),
          ),
          DecoCircle(
            size: 200,
            color: const Color(0xFF8B5CF6),
            alignment: Alignment.bottomLeft,
            offset: const Offset(-50, 50),
          ),

          SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: () => _pickImage('profile'),
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF2A2312),
                              border: Border.all(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.5,
                                ),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _profileImage != null
                                  ? Image.file(
                                      File(_profileImage!.path),
                                      fit: BoxFit.cover,
                                    )
                                  : controller.profile.value?.profileImage !=
                                            null &&
                                        controller
                                            .profile
                                            .value!
                                            .profileImage!
                                            .isNotEmpty
                                  ? Image.network(
                                      controller.profileImageUrl(
                                        controller.profile.value!.profileImage,
                                      ),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, _, __) =>
                                          _buildInitials(),
                                    )
                                  : _buildInitials(),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF0F1522),
                                  width: 3,
                                ),
                              ),
                              child: const Icon(
                                IconlyBold.camera,
                                size: 16,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildLabel("First Name"),
                  GlassTextField(
                    controller: _firstNameController,
                    hintText: "Enter first name",
                    prefixIcon: IconlyLight.profile,
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 20),

                  _buildLabel("Last Name"),
                  GlassTextField(
                    controller: _lastNameController,
                    hintText: "Enter last name",
                    prefixIcon: IconlyLight.profile,
                  ),
                  const SizedBox(height: 20),

                  _buildLabel("Gender"),
                  DropdownButtonFormField<String>(
                    initialValue: _genderController.text.isEmpty
                        ? null
                        : _genderController.text,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: theme.brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF0F172A),
                    ),
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: theme.brightness == Brightness.dark
                          ? Colors.white70
                          : const Color(0xFF64748B),
                    ),
                    selectedItemBuilder: (BuildContext context) {
                      return ['Male', 'Female', 'Other'].map<Widget>((
                        String item,
                      ) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            item,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: theme.brightness == Brightness.dark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        );
                      }).toList();
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: theme.brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.06)
                          : const Color(0xFFF1F5F9),
                      prefixIcon: Icon(
                        IconlyLight.user,
                        color: theme.colorScheme.primary,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: theme.brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.1)
                              : AppTheme.borderLight,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: theme.brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.1)
                              : AppTheme.borderLight,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                    dropdownColor: theme.brightness == Brightness.dark
                        ? const Color(0xFF161C2C)
                        : Colors.white,
                    items: ['Male', 'Female', 'Other']
                        .map(
                          (g) => DropdownMenuItem(
                            value: g,
                            child: Text(
                              g,
                              style: GoogleFonts.inter(
                                color: theme.brightness == Brightness.dark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _genderController.text = v;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  _buildLabel("Date of Birth"),
                  GestureDetector(
                    onTap: _selectDate,
                    child: AbsorbPointer(
                      child: GlassTextField(
                        controller: _dobController,
                        hintText: "Select date",
                        prefixIcon: IconlyLight.calendar,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildLabel("PAN Number"),
                  GlassTextField(
                    controller: _panController,
                    hintText: "Enter PAN number (e.g. ABCDE1234F)",
                    prefixIcon: IconlyLight.document,
                    inputFormatters: const [TaxIdInputFormatter.pan()],
                    validator: TaxIdValidator.pan,
                  ),
                  const SizedBox(height: 20),

                  _buildLabel("GST Number"),
                  GlassTextField(
                    controller: _gstController,
                    hintText: "Enter GST number (e.g. 29ABCDE1234F1Z5)",
                    prefixIcon: IconlyLight.document,
                    inputFormatters: const [TaxIdInputFormatter.gst()],
                    validator: TaxIdValidator.gst,
                  ),

                  const SizedBox(height: 28),
                  Text(
                    "Documents",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _documentPicker(
                    "PAN Document",
                    'pan',
                    _panDocument,
                    controller.profile.value?.panImage ?? '',
                  ),
                  const SizedBox(height: 10),
                  _documentPicker(
                    "GST Document",
                    'gst',
                    _gstDocument,
                    controller.profile.value?.gstImage ?? '',
                  ),
                  const SizedBox(height: 10),
                  _documentPicker(
                    "Aadhaar Document",
                    'aadhaar',
                    _aadhaarDocument,
                    controller.profile.value?.aadhaarImage ?? '',
                  ),

                  const SizedBox(height: 40),

                  Obx(
                    () => GlassButton(
                      onPressed: _saveProfile,
                      isLoading: controller.isUpdating.value,
                      child: Text(
                        "Save Changes",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white70 : const Color(0xFF334155),
        ),
      ),
    );
  }

  Widget _documentPicker(
    String title,
    String type,
    XFile? selected,
    String uploadedUrl,
  ) {
    final theme = Theme.of(context);
    final hasExisting = uploadedUrl.trim().isNotEmpty;
    return GlassCard(
      onTap: hasExisting ? null : () => _pickImage(type),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(IconlyLight.document, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                ),
                Text(
                  selected != null
                      ? selected.name
                      : hasExisting
                      ? 'Already uploaded'
                      : 'Tap to select JPG or PNG',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            selected != null || hasExisting
                ? Icons.check_circle
                : IconlyLight.upload,
            color: selected != null || hasExisting
                ? Colors.green
                : theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildInitials() {
    final user = controller.profile.value;
    return Center(
      child: Text(
        user?.firstName.isNotEmpty == true
            ? user!.firstName[0].toUpperCase()
            : "A",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 36,
        ),
      ),
    );
  }
}
