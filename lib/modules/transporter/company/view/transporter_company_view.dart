import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../../../theme/glass_widgets.dart';
import '../controller/transporter_company_controller.dart';
import '../model/company_model.dart';
import './transporter_company_form.dart';
import './transporter_company_detail.dart';

class TransporterCompanyView extends StatelessWidget {
  TransporterCompanyView({super.key});

  final TransporterCompanyController controller = Get.put(
    TransporterCompanyController(),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: theme.textTheme.bodyLarge?.color,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "My Companies",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
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
                Icon(
                  IconlyLight.work,
                  size: 64,
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                ),
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
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 80,
            ),
            itemCount: controller.companies.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final company = controller.companies[index];
              return _buildCompanyCard(context, company);
            },
          ),
        );
      }),
    );
  }

  Widget _buildCompanyCard(BuildContext context, CompanyModel company) {
    final theme = Theme.of(context);
    final location = [
      company.city,
      company.state,
      company.pincode,
    ].where((value) => value != null && value.trim().isNotEmpty).join(', ');

    return GlassCard(
      onTap: () => Get.to(() => TransporterCompanyDetail(company: company)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  IconlyBold.work,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.legalName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if ((company.companyType ?? '').isNotEmpty)
                      Text(
                        company.companyType!,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                  ],
                ),
              ),
              _statusChip(
                company.isVerified == true ? 'VERIFIED' : 'UNVERIFIED',
                company.isVerified == true ? Colors.green : Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if ((company.gstNumber ?? '').isNotEmpty)
            _infoRow(IconlyLight.document, 'GST', company.gstNumber!),
          if ((company.panNumber ?? '').isNotEmpty)
            _infoRow(IconlyLight.wallet, 'PAN', company.panNumber!),
          if (location.isNotEmpty)
            _infoRow(IconlyLight.location, 'Location', location),
          if ((company.addressLine1 ?? '').isNotEmpty)
            _infoRow(IconlyLight.home, 'Address', company.addressLine1!),
          if (company.yearOfEstablishment != null ||
              company.numberOfEmployees != null)
            _infoRow(
              Icons.business_outlined,
              'Business',
              [
                if (company.yearOfEstablishment != null)
                  'Est. ${company.yearOfEstablishment}',
                if (company.numberOfEmployees != null)
                  '${company.numberOfEmployees} employees',
              ].join(' • '),
            ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              if (company.isPrimary)
                _statusChip('PRIMARY', Colors.green)
              else
                TextButton(
                  onPressed: () => controller.setPrimaryCompany(company.id),
                  child: const Text('Set Primary'),
                ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () =>
                    Get.to(() => TransporterCompanyForm(company: company)),
                icon: const Icon(IconlyLight.edit, size: 16),
                label: const Text('Edit'),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Delete company',
                onPressed: () => _showDeleteConfirmDialog(context, company.id),
                icon: const Icon(
                  IconlyLight.delete,
                  color: Colors.red,
                  size: 19,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          SizedBox(
            width: 58,
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text("Delete Company?"),
        content: const Text(
          "Are you sure you want to delete this company? This action cannot be undone.",
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
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
