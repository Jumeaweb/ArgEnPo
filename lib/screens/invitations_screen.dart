import 'package:flutter/material.dart';

import '../models/invitation_model.dart';
import '../services/invitation_service.dart';
import '../services/refresh_bus.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';

class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({super.key});

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  final InvitationService _invitationService = InvitationService();

  late Future<List<InvitationModel>> _invitationsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _invitationsFuture = _invitationService.getPendingInvitations();
  }

  Future<void> _acceptInvitation(InvitationModel invitation) async {
    try {
      await _invitationService.acceptInvitation(invitation);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invitation acceptée : ${invitation.groupName}'),
        ),
      );

      RefreshBus.instance.notify();

      setState(() {
        _reload();
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
        ),
      );
    }
  }

  Future<void> _declineInvitation(String invitationId) async {
    try {
      await _invitationService.declineInvitation(invitationId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invitation refusée'),
        ),
      );

      setState(() {
        _reload();
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
        ),
      );
    }
  }

  Future<bool?> _confirm(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        title: const Text(
          'Invitations reçues',
          style: AppTextStyles.appBarTitle,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _reload();
          });
        },
        child: FutureBuilder<List<InvitationModel>>(
          future: _invitationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(AppDimensions.padding),
                    child: Center(
                      child: Text(
                        'Erreur de chargement des invitations',
                        style: AppTextStyles.subtitle,
                      ),
                    ),
                  ),
                ],
              );
            }

            final invitations = snapshot.data ?? [];

            if (invitations.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(AppDimensions.padding),
                    child: Center(
                      child: Text(
                        'Aucune invitation reçue',
                        style: AppTextStyles.subtitle,
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.padding),
              itemCount: invitations.length,
              itemBuilder: (context, index) {
                final invitation = invitations[index];
                final createdAt =
                    '${invitation.createdAt.day.toString().padLeft(2, '0')}/'
                    '${invitation.createdAt.month.toString().padLeft(2, '0')}/'
                    '${invitation.createdAt.year}';

                return AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invitation.groupName,
                        style: AppTextStyles.title,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$createdAt • Envoyée à ${invitation.email}',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final confirm = await _confirm(
                                  'Refuser l\'invitation ?',
                                  'Vous ne rejoindrez pas '
                                  '${invitation.groupName}.',
                                );

                                if (confirm == true) {
                                  await _declineInvitation(invitation.id);
                                }
                              },
                              child: const Text('Refuser'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  _acceptInvitation(invitation),
                              child: const Text('Accepter'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
