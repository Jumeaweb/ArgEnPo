import 'package:flutter/material.dart';

import '../models/invitation_model.dart';
import '../services/invitation_service.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';

class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({super.key});

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  final InvitationService _invitationService = InvitationService();

  Future<void> _acceptInvitation(InvitationModel invitation) async {
    try {
      await _invitationService.acceptInvitation(invitation);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invitation acceptée'),
        ),
      );

      Navigator.pop(context);
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
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
        ),
      );
    }
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
      body: StreamBuilder<List<InvitationModel>>(
        stream: _invitationService.watchPendingInvitationsForCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.padding),
                child: Text(
                  'Erreur de chargement des invitations',
                  style: AppTextStyles.subtitle,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final invitations = snapshot.data ?? [];

          if (invitations.isEmpty) {
            return Center(
              child: Text(
                'Aucune invitation reçue',
                style: AppTextStyles.subtitle,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.padding),
            itemCount: invitations.length,
            itemBuilder: (context, index) {
              final invitation = invitations[index];

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
                      'Invitation envoyée par ${invitation.invitedByName}',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                _declineInvitation(invitation.id),
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
    );
  }
}