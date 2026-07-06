import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/group_model.dart';
import '../services/group_service.dart';

import '../theme/theme.dart';
import '../widgets/widgets.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final nameController = TextEditingController();
  final GroupService _groupService = GroupService();

  Future<void> createGroup() async {
    final name = nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir un nom de groupe.'),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser!;
    
    final group = GroupModel(
      id: '',
      name: name,
      createdBy: user.uid,
      members: [user.uid],
      createdAt: DateTime.now(),
    );

    await _groupService.createGroup(
      name: group.name,
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        title: const Text(
          'Créer un groupe',
          style: AppTextStyles.appBarTitle,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.padding),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSectionTitle('Nouveau groupe'),

                Text(
                  'Donne un nom à ton groupe de dépenses.',
                  style: AppTextStyles.subtitle,
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du groupe',
                    prefixIcon: Icon(Icons.group),
                  ),
                ),

                const SizedBox(height: 24),

                AppButton(
                  text: 'Créer le groupe',
                  icon: Icons.add,
                  onPressed: createGroup,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}