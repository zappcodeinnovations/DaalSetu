import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:daalsetu/theme/glass_widgets.dart';
import 'package:daalsetu/modules/transporter/company/controller/transporter_company_controller.dart';
import 'package:daalsetu/modules/transporter/company/view/transporter_company_form.dart';
import 'package:daalsetu/modules/transporter/company/view/transporter_company_detail.dart';

class TransporterCompanyView extends StatelessWidget {
  TransporterCompanyView({super.key});

  final TransporterCompanyController controller = Get.put(TransporterCompanyController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "My Companies",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => TransporterCompanyForm()),
        icon: const Icon(IconlyLight.plus),
        label: const Text("Register Company"),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.companies.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.companies.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(IconlyLight.work, size: 64, color: theme.colorScheme.primary.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  "No companies registered yet",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Tap the + button to register a new company",
                  style: GoogleFonts.inter(
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchCompanies(),
          child: ListView.separated(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
            itemCount: controller.companies.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final company = controller.companies[index];
              return GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                      child: Icon(IconlyLight.work, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            company.legalName,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          if (company.isPrimary)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "PRIMARY",
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(IconlyLight.more_square),
                      onSelected: (value) async {
                        if (value == 'view') {
                          final details = await controller.fetchCompanyDetails(company.id);
                          if (details != null) {
                            Get.to(() => TransporterCompanyDetail(company: details));
                          }
                        } else if (value == 'edit') {
                          final details = await controller.fetchCompanyDetails(company.id);
                          if (details != null) {
                            Get.to(() => TransporterCompanyForm(company: details));
                          }
                        } else if (value == 'set_primary') {
                          controller.setPrimaryCompany(company.id);
                        } else if (value == 'delete') {
                          _showDeleteConfirmDialog(context, company.id);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'view', child: Text("View Details")),
                        const PopupMenuItem(value: 'edit', child: Text("Edit")),
                        if (!company.isPrimary)
                          const PopupMenuItem(value: 'set_primary', child: Text("Set as Primary")),
                        const PopupMenuItem(value: 'delete', child: Text("Delete", style: TextStyle(color: Colors.red))),
                      ],
                    )
                  ],
                ),
              );
            },
          ),
        );
      }),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text("Delete Company?"),
        content: const Text("Are you sure you want to delete this company? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteCompany(id);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
