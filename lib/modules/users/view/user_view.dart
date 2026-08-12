import 'package:iconly/iconly.dart';
import '../model/user_model.dart';
import './add_user_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/user_controller.dart';

class UserScreen extends StatelessWidget {
  UserScreen({super.key});

  final UserController controller = Get.put(UserController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        title: Text(
          "Users",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Get.toNamed('/add-user');
          Get.to(() => AddUserScreen());
        },
        icon: const Icon(IconlyLight.add_user),
        label: const Text("Add User"),
        backgroundColor: theme.colorScheme.primary,
      ),

      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: theme.colorScheme.primary),
          );
        }

        if (controller.users.isEmpty) {
          return Center(
            child: Text("No Users Found", style: theme.textTheme.bodyMedium),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchUsers,
          color: theme.colorScheme.primary,
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: controller.users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = controller.users[index];
              return _buildUserCard(context, user);
            },
          ),
        );
      }),
    );
  }

  Widget _buildUserCard(BuildContext context, UserModel id) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        Get.toNamed('/users-details', arguments: id);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            /// PROFILE IMAGE
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              backgroundImage: id.profileImage != null
                  ? NetworkImage(id.profileImage!)
                  : null,
              child: id.profileImage == null
                  ? Text(
                      id.username.substring(0, 1).toUpperCase(),
                      style: theme.textTheme.titleMedium,
                    )
                  : null,
            ),

            const SizedBox(width: 16),

            /// NAME + ROLE
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    id.fullName.isEmpty ? id.username : id.fullName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      id.role.toUpperCase(),
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              IconlyLight.arrow_right_2,
              size: 14,
              color: theme.iconTheme.color,
            ),
          ],
        ),
      ),
    );
  }
}
