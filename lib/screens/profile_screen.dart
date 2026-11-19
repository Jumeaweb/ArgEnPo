import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../services/refresh_bus.dart';
import '../services/user_service.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';

import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();

  String displayName = '';
  String email = '';
  String appVersion = '';
  bool saving = false;

  @override
  void initState() {
    super.initState();
    loadProfile();
    loadVersion();
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

  Future<void> loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();

    if (!mounted) return;

    setState(() {
      appVersion = packageInfo.version;
    });
  }

  Future<void> _editDisplayName() async {
    final controller = TextEditingController(text: displayName);

    final newName = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Modifier mon nom'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Votre nom',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (newName == null || newName.trim().isEmpty) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => saving = true);

    try {
      await _userService.updateDisplayName(user.id, newName);

      if (!mounted) return;

      setState(() {
        displayName = newName.trim();
      });

      // Le nom est affiché sur le tableau de bord et dans les groupes.
      RefreshBus.instance.notify();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nom modifié')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Réinitialiser le mot de passe ?'),
        content: Text(
          'Un e-mail avec un lien de réinitialisation sera envoyé à '
          '$email.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _authService.resetPassword(email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'E-mail de réinitialisation envoyé à $email',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
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
                const SizedBox(height: AppDimensions.padding),
                OutlinedButton.icon(
                  onPressed: saving ? null : _editDisplayName,
                  icon: const Icon(Icons.edit),
                  label: const Text('Modifier mon nom'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.padding),
          AppCard(
            child: ListTile(
              leading: const Icon(
                Icons.lock_reset,
                color: AppColors.primary,
              ),
              title: Text(
                'Réinitialiser mon mot de passe',
                style: AppTextStyles.title,
              ),
              subtitle: Text(
                'Un e-mail vous sera envoyé',
                style: AppTextStyles.subtitle,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _resetPassword,
            ),
          ),
          const SizedBox(height: AppDimensions.padding),
          AppButton(
            text: 'Déconnexion',
            onPressed: _signOut,
          ),
          const SizedBox(height: AppDimensions.padding),
          Center(
            child: Text(
              appVersion.isEmpty ? 'ArgEnPo' : 'ArgEnPo • Version $appVersion',
              style: AppTextStyles.subtitle,
            ),
          ),
        ],
      ),
    );
  }
}
