import 'package:flutter/material.dart';

import '../models/navigation_item.dart';
import '../screens/groups_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../theme/theme.dart';

import 'app_bottom_navigation.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;

  final List<NavigationItem> navigationItems = const [
    NavigationItem(
      page: HomeScreen(),
      icon: Icons.home,
      title: 'ArgEnPo',
      subtitle: 'Les comptes entre amis, sans prise de tête.',
    ),
    NavigationItem(
      page: GroupsScreen(),
      icon: Icons.group,
      title: 'Groupes',
      subtitle: 'Mes groupes de partage',
    ),
    NavigationItem(
      page: ProfileScreen(),
      icon: Icons.person,
      title: 'Profil',
      subtitle: 'Mon compte',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: selectedIndex,
        children: [
          for (final item in navigationItems) item.page,
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: selectedIndex,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
      ),
    );
  }
}
