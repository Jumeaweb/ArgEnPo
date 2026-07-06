import 'package:flutter/material.dart';

class NavigationItem {
  final Widget page;
  final IconData icon;
  final String title;
  final String subtitle;

  const NavigationItem({
    required this.page,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}