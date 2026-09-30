import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:intl/intl.dart';
import '../../../theme/glass_widgets.dart';
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

  @override
  void initState() {
    super.initState();
    final user = controller.profile.value;
    
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _genderController = TextEditingController(text: user?.gender.isEmpty == true ? 'Male' : user?.gender);
    _dobController = TextEditingController(text: user?.dob ?? '');
    _panController = TextEditingController(text: user?.panNumber ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _genderController.dispose();
    _dobController.dispose();
    _panController.dispose();
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

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'gender': _genderController.text.trim(),
      'dob': _dobController.text.trim(),
      'pan_number': _panController.text.trim(),
    };

    final success = await controller.updateProfile(data);
    if (success) {
      Get.back();
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
          DecoCircle(size: 250, color: theme.colorScheme.primary, alignment: Alignment.topRight, offset: const Offset(50, -50)),
          DecoCircle(size: 200, color: const Color(0xFF8B5CF6), alignment: Alignment.bottomLeft, offset: const Offset(-50, 50)),
          
          SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF2A2312),
                            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.5), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: controller.profile.value?.profileImage != null
                                ? Image.network(
                                    controller.profile.value!.profileImage!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, _, __) => _buildInitials(),
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
                              border: Border.all(color: const Color(0xFF0F1522), width: 3),
                            ),
                            child: const Icon(IconlyBold.camera, size: 16, color: Colors.black),
                          ),
                        ),
                      ],
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
                    value: _genderController.text.isEmpty ? null : _genderController.text,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      prefixIcon: Icon(IconlyLight.user, color: theme.colorScheme.primary.withValues(alpha: 0.7)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                    ),
                    dropdownColor: const Color(0xFF161C2C),
                    items: ['Male', 'Female', 'Other']
                        .map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(color: Colors.white))))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) _genderController.text = v;
                    },
                  ),
                  const SizedBox(height: 20),

                  _buildLabel("Date of Birth"),
                  GestureDetector(
                    onTap: _selectDate,
                    child: AbsorbPointer(
                      child: GlassTextField(
                        controller: _dobController,
                        hintText: "YYYY-MM-DD",
                        prefixIcon: IconlyLight.calendar,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildLabel("PAN Number"),
                  GlassTextField(
                    controller: _panController,
                    hintText: "Enter PAN number",
                    prefixIcon: IconlyLight.document,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  Obx(() => GlassButton(
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
                      )),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white70,
        ),
      ),
    );
  }

  Widget _buildInitials() {
    final user = controller.profile.value;
    return Center(
      child: Text(
        user?.firstName.isNotEmpty == true ? user!.firstName[0].toUpperCase() : "A",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 36,
        ),
      ),
    );
  }
}
