import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../theme/theme.dart';
import '../services/user_service.dart';
import '../widgets/widgets.dart';

import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();

  String displayName = '';
  String email = '';

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final name = await _userService.getUserDisplayName(user.id);

    if (!mounted) return;

    setState(() {
      displayName = name;
      email = user.email ?? '';
    });
  }

  Future<void> _signOut() async {
    await AuthService().signOut();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final initial =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        toolbarHeight: 72,
        title: const Row(
          children: [
            Icon(Icons.person, size: 28),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Profil', style: AppTextStyles.appBarTitle),
                Text('Mon compte', style: AppTextStyles.appBarSubtitle),
              ],
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.padding),
        children: [
          AppCard(
            padding: const EdgeInsets.all(AppDimensions.padding),
            child: Column(
              children: [
                CircleAvatar(
                  radius: AppDimensions.iconCircleRadius + 8,
                  backgroundColor: AppColors.primary,
                  child: Text(initial, style: AppTextStyles.avatarInitial),
                ),
                const SizedBox(height: AppDimensions.padding),
                Text(displayName, style: AppTextStyles.title),
                const SizedBox(height: 4),
                Text(email, style: AppTextStyles.subtitle),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.padding),
          AppButton(
            text: 'Déconnexion',
            onPressed: _signOut,
          ),
        ],
      ),
    );
  }
}
