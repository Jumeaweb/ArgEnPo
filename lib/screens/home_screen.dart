import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/group_model.dart';
import '../models/invitation_model.dart';
import '../services/expense_service.dart';
import '../services/group_service.dart';
import '../services/invitation_service.dart';

import '../theme/theme.dart';
import '../widgets/widgets.dart';

import 'create_group_screen.dart';
import 'group_screen.dart';
import 'invitations_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GroupService _groupService = GroupService();
  final ExpenseService _expenseService = ExpenseService();
  final InvitationService _invitationService = InvitationService();

  List<GroupModel> groups = [];
  bool _hasCheckedInvitations = false;

  @override
  void initState() {
    super.initState();
    _initializeHome();
  }

  Future<void> _initializeHome() async {
    await _invitationService.linkPendingInvitationsForCurrentUser();
    await loadGroups();
    await _checkInvitationsAfterLogin();
  }

  Future<void> loadGroups() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final data = await _groupService.getUserGroups(uid);

    if (!mounted) return;

    setState(() {
      groups = data;
    });
  }

  Future<void> _checkInvitationsAfterLogin() async {
    if (_hasCheckedInvitations) return;

    _hasCheckedInvitations = true;

    final invitations =
        await _invitationService.getPendingInvitationsForCurrentUser();

    if (!mounted || invitations.isEmpty) return;

    final invitationCount = invitations.length;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          invitationCount == 1
              ? 'Vous avez 1 invitation en attente'
              : 'Vous avez $invitationCount invitations en attente',
        ),
        action: SnackBarAction(
          label: 'Voir',
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const InvitationsScreen(),
              ),
            );

            loadGroups();
          },
        ),
      ),
    );
  }

  Future<void> _openInvitationsScreen() async {
    await _invitationService.linkPendingInvitationsForCurrentUser();

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const InvitationsScreen(),
      ),
    );

    loadGroups();
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  Widget _buildInvitationsButton() {
    return StreamBuilder<List<InvitationModel>>(
      stream: _invitationService.watchPendingInvitationsForCurrentUser(),
      builder: (context, snapshot) {
        final invitationCount = snapshot.data?.length ?? 0;

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.mail_outline),
              tooltip: 'Invitations reçues',
              onPressed: _openInvitationsScreen,
            ),
            if (invitationCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    invitationCount > 9 ? '9+' : '$invitationCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
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
          'ArgEnPo',
          style: AppTextStyles.appBarTitle,
        ),
        actions: [
          _buildInvitationsButton(),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: _signOut,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateGroupScreen(),
            ),
          );

          loadGroups();
        },
        child: const Icon(Icons.add, size: 32),
      ),
      body: groups.isEmpty
          ? Center(
              child: Text(
                'Aucun groupe pour le moment',
                style: AppTextStyles.subtitle,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.padding),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final g = groups[index];

                return FutureBuilder<List<Object>>(
                  future: Future.wait<Object>([
                    _expenseService.getExpenseCount(g.id),
                    _expenseService.getTotalAmount(g.id),
                  ]),
                  builder: (context, snapshot) {
                    final expenseCount =
                        snapshot.hasData ? snapshot.data![0] as int : 0;

                    final totalAmount =
                        snapshot.hasData ? snapshot.data![1] as double : 0.0;

                    return AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GroupScreen(
                              groupId: g.id,
                              groupName: g.name,
                              members: g.members,
                            ),
                          ),
                        );

                        loadGroups();
                      },
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: AppDimensions.iconCircleRadius,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              g.name.isNotEmpty
                                  ? g.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: AppColors.textLight,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  g.name,
                                  style: AppTextStyles.title,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${g.members.length} amis • $expenseCount dépenses',
                                  style: AppTextStyles.subtitle,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${totalAmount.toStringAsFixed(2)} €',
                                style: AppTextStyles.amount,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Total',
                                style: AppTextStyles.subtitle,
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