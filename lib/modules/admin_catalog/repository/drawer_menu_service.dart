import 'package:daalsetu/modules/admin_catalog/model/drawer_menu_model.dart';
import 'package:daalsetu/routes/app_routes.dart';
import 'package:daalsetu/modules/admin_catalog/config/admin_module_config.dart';
import 'package:flutter/material.dart';

class DrawerMenuService {
  Future<List<DrawerMenuSection>> fetchMenu() async {
    // Simulated fetch delay to mimic architecture requirements
    await Future.delayed(const Duration(milliseconds: 100));

    return [
      DrawerMenuSection(
        sectionTitle: 'GENERAL',
        items: [
          DrawerMenuItem(
            key: 'notifications',
            title: 'Notifications',
            icon: Icons.notifications_none_rounded,
            route: AppRoutes.sellerNotifications,
          ),
          DrawerMenuItem(
            key: 'registered_company',
            title: 'Registered Company',
            icon: Icons.apartment_rounded,
            route: AppRoutes.sellerCompany,
            requiredRoles: const ['super_admin', 'admin'],
          ),
        ],
      ),
      DrawerMenuSection(
        sectionTitle: 'MASTERS',
        items: [
          DrawerMenuItem(
            key: 'users',
            title: 'User Management',
            icon: Icons.people_alt_outlined,
            route: AppRoutes.users,
          ),
          DrawerMenuItem(
            key: 'salesman',
            title: AdminModules.byKey('salesman').title,
            icon: AdminModules.byKey('salesman').icon,
            route: AppRoutes.adminModule('salesman'),
          ),
          DrawerMenuItem(
            key: 'kyc',
            title: AdminModules.byKey('kyc').title,
            icon: AdminModules.byKey('kyc').icon,
            route: AppRoutes.adminModule('kyc'),
          ),
          DrawerMenuItem(
            key: 'category_requests',
            title: AdminModules.byKey('category_requests').title,
            icon: AdminModules.byKey('category_requests').icon,
            route: AppRoutes.adminModule('category_requests'),
          ),
          DrawerMenuItem(
            key: 'categories',
            title: AdminModules.byKey('categories').title,
            icon: AdminModules.byKey('categories').icon,
            route: AppRoutes.adminModule('categories'),
          ),
          DrawerMenuItem(
            key: 'sub_categories',
            title: AdminModules.byKey('sub_categories').title,
            icon: AdminModules.byKey('sub_categories').icon,
            route: AppRoutes.adminModule('sub_categories'),
          ),
          DrawerMenuItem(
            key: 'brands',
            title: AdminModules.byKey('brands').title,
            icon: AdminModules.byKey('brands').icon,
            route: AppRoutes.adminModule('brands'),
          ),
          DrawerMenuItem(
            key: 'tags',
            title: AdminModules.byKey('tags').title,
            icon: AdminModules.byKey('tags').icon,
            route: AppRoutes.adminModule('tags'),
          ),
          DrawerMenuItem(
            key: 'drivers',
            title: AdminModules.byKey('drivers').title,
            icon: AdminModules.byKey('drivers').icon,
            route: AppRoutes.adminModule('drivers'),
          ),
          DrawerMenuItem(
            key: 'vehicles',
            title: AdminModules.byKey('vehicles').title,
            icon: AdminModules.byKey('vehicles').icon,
            route: AppRoutes.adminModule('vehicles'),
          ),
        ],
      ),
      DrawerMenuSection(
        sectionTitle: 'OFFER',
        items: [
          DrawerMenuItem(
            key: 'create_offer',
            title: 'Create Offer',
            icon: Icons.add_business_rounded,
            route: AppRoutes.adminCreateOffer,
          ),
          DrawerMenuItem(
            key: 'offers',
            title: AdminModules.byKey('offers').title,
            icon: AdminModules.byKey('offers').icon,
            route: AppRoutes.adminModule('offers'),
          ),
          DrawerMenuItem(
            key: 'buyer_requirements',
            title: AdminModules.byKey('buyer_requirements').title,
            icon: AdminModules.byKey('buyer_requirements').icon,
            route: AppRoutes.adminModule('buyer_requirements'),
          ),
          DrawerMenuItem(
            key: 'buyer_offers',
            title: AdminModules.byKey('buyer_offers').title,
            icon: AdminModules.byKey('buyer_offers').icon,
            route: AppRoutes.adminModule('buyer_offers'),
          ),
          DrawerMenuItem(
            key: 'offer_images',
            title: AdminModules.byKey('offer_images').title,
            icon: AdminModules.byKey('offer_images').icon,
            route: AppRoutes.adminModule('offer_images'),
          ),
          DrawerMenuItem(
            key: 'offer_videos',
            title: AdminModules.byKey('offer_videos').title,
            icon: AdminModules.byKey('offer_videos').icon,
            route: AppRoutes.adminModule('offer_videos'),
          ),
        ],
      ),
    ];
  }
}
