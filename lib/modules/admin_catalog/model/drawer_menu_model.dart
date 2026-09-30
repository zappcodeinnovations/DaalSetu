import 'package:flutter/material.dart';

/// A single item in the admin sidebar.
class DrawerMenuSection {
  const DrawerMenuSection({
    required this.sectionTitle,
    required this.items,
  });

  final String sectionTitle;
  final List<DrawerMenuItem> items;
}

class DrawerMenuItem {
  const DrawerMenuItem({
    required this.key,
    required this.title,
    required this.icon,
    required this.route,
    this.requiredRoles = const ['admin', 'sub_admin'],
  });

  /// Unique identifier — matches AdminModules key where applicable
  final String key;
  final String title;
  final IconData icon;

  /// Named route or empty string for custom navigation
  final String route;

  /// Which roles can see this item
  final List<String> requiredRoles;

  bool isVisibleFor(String role) =>
      requiredRoles.any((r) => r.toLowerCase() == role.toLowerCase());
}
