import 'package:iconly/iconly.dart';
import 'package:flutter/material.dart';

enum BranchStatus { active, watchlist, critical }

class Branch {
  final String name;
  final String admin;
  final BranchStatus status;

  Branch({required this.name, required this.admin, required this.status});
}

class BranchesScreen extends StatefulWidget {
  const BranchesScreen({super.key});

  @override
  State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen> {
  final List<Branch> _branches = [
    Branch(name: "Mumbai Branch", admin: "Prem Verma", status: BranchStatus.active),
    Branch(name: "Delhi North", admin: "Rajesh Kumar", status: BranchStatus.watchlist),
    Branch(name: "Bangalore Hub", admin: "Anjali Rao", status: BranchStatus.critical),
    Branch(name: "Pune Sector 5", admin: "Suresh Mehra", status: BranchStatus.active),
    Branch(name: "Kolkata Central", admin: "Debasish Roy", status: BranchStatus.active),
  ];

  String _selectedFilter = "All";
  final List<String> _filters = ["All", "Active", "Watchlist", "Critical"];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(IconlyLight.plus),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildSearchBar(context),
                  const SizedBox(height: 16),
                  _buildFilterChips(context),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _branches.length,
                itemBuilder: (context, index) {
                  return _buildBranchCard(context, _branches[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: "Search by location or admin...",
        prefixIcon: Icon(IconlyLight.search, color: theme.iconTheme.color),
        filled: true,
        fillColor: theme.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;

          return ChoiceChip(
            label: Text(filter),
            labelStyle: TextStyle(
              color: isSelected
                  ? Colors.white
                  : theme.textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w600,
            ),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                setState(() => _selectedFilter = filter);
              }
            },
            backgroundColor: theme.cardColor,
            selectedColor: theme.colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBranchCard(BuildContext context, Branch branch) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor:
                theme.colorScheme.primary.withOpacity(0.15),
            child: Icon(
              IconlyLight.work,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  branch.name,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  "Admin: ${branch.admin}",
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                _buildStatusIndicator(context, branch.status),
              ],
            ),
          ),
          Icon(IconlyLight.arrow_right_2,
              size: 16, color: theme.iconTheme.color),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(
      BuildContext context, BranchStatus status) {
    final theme = Theme.of(context);

    Color color;
    String text;

    switch (status) {
      case BranchStatus.active:
        color = Colors.green;
        text = "ACTIVE";
        break;
      case BranchStatus.watchlist:
        color = Colors.orange;
        text = "WATCHLIST";
        break;
      case BranchStatus.critical:
        color = theme.colorScheme.error;
        text = "CRITICAL";
        break;
    }

    return Row(
      children: [
        CircleAvatar(radius: 4, backgroundColor: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}