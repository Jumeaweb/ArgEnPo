import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/group_model.dart';
import '../models/invitation_model.dart';
import '../services/expense_service.dart';
import '../services/group_service.dart';
import '../services/invitation_service.dart';
import '../services/notification_service.dart';

import '../theme/theme.dart';
import '../widgets/design_system/design_system.dart' hide AppColors;

import 'create_group_screen.dart';
import 'group_screen.dart';
import 'invitations_screen.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GroupService _groupService = GroupService();
  final ExpenseService _expenseService = ExpenseService();
  final InvitationService _invitationService = InvitationService();
  final NotificationService _notificationService = NotificationService();

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

  Future<void> _openNotificationsScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationsScreen(),
      ),
    );
  }

  Future<void> _openCreateGroupScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateGroupScreen(),
      ),
    );

    loadGroups();
  }

  Future<void> _openGroup(GroupModel group) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupScreen(
          groupId: group.id,
          groupName: group.name,
          members: group.members,
        ),
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

  String _formatGroupName(String name) {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      return 'Groupe';
    }

    return '${trimmedName[0].toUpperCase()}${trimmedName.substring(1)}';
  }

  Widget _buildInvitationsButton() {
    return StreamBuilder<List<InvitationModel>>(
      stream: _invitationService.watchPendingInvitationsForCurrentUser(),
      builder: (context, snapshot) {
        final invitationCount = snapshot.data?.length ?? 0;

        return AppBadge(
          count: invitationCount,
          top: 2,
          right: 2,
          child: IconButton(
            icon: const Icon(AppIcons.invitation),
            tooltip: 'Invitations reçues',
            onPressed: _openInvitationsScreen,
          ),
        );
      },
    );
  }

  Widget _buildNotificationsButton() {
    return StreamBuilder<int>(
      stream: _notificationService.watchUnreadCount(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return AppBadge(
          count: unreadCount,
          top: 2,
          right: 2,
          child: IconButton(
            icon: const Icon(AppIcons.notifications),
            tooltip: 'Notifications',
            onPressed: _openNotificationsScreen,
          ),
        );
      },
    );
  }

  Widget _buildGroupCard(GroupModel group) {
    return FutureBuilder<List<Object>>(
      future: Future.wait<Object>([
        _expenseService.getExpenseCount(group.id),
        _expenseService.getTotalAmount(group.id),
      ]),
      builder: (context, snapshot) {
        final expenseCount =
            snapshot.hasData ? snapshot.data![0] as int : 0;

        final totalAmount =
            snapshot.hasData ? snapshot.data![1] as double : 0.0;

        final memberLabel = group.members.length == 1
            ? '1 ami'
            : '${group.members.length} amis';

        final expenseLabel = expenseCount == 1
            ? '1 dépense'
            : '$expenseCount dépenses';

        final formattedGroupName = _formatGroupName(group.name);

        return AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          onTap: () => _openGroup(group),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AppAvatar(
                    name: formattedGroupName,
                    maxInitials: 1,
                    radius: AppDimensions.iconCircleRadius,
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textLight,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppSectionTitle(
                      title: formattedGroupName,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${totalAmount.toStringAsFixed(2)} €',
                        style: AppTextStyles.amount.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Icon(
                        AppIcons.forward,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  AppStatusChip(
                    label: memberLabel,
                    icon: AppIcons.member,
                    compact: true,
                  ),
                  AppStatusChip.info(
                    label: expenseLabel,
                    icon: AppIcons.expense,
                    compact: true,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return AppEmptyState(
      title: 'Aucun groupe pour le moment',
      message:
          'Créez votre premier groupe pour commencer à partager vos dépenses.',
      icon: AppIcons.groups,
      action: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textLight,
        ),
        onPressed: _openCreateGroupScreen,
        icon: const Icon(AppIcons.addGroup),
        label: const Text('Créer un groupe'),
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
          'ArgEnPo',
          style: AppTextStyles.appBarTitle,
        ),
        actions: [
          _buildInvitationsButton(),
          _buildNotificationsButton(),
          IconButton(
            icon: const Icon(AppIcons.logout),
            tooltip: 'Déconnexion',
            onPressed: _signOut,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        onPressed: _openCreateGroupScreen,
        child: const Icon(
          AppIcons.add,
          size: 32,
        ),
      ),
      body: groups.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: loadGroups,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(
                  AppDimensions.padding,
                ),
                itemCount: groups.length,
                separatorBuilder: (context, index) {
                  return const SizedBox(
                    height: AppSpacing.md,
                  );
                },
                itemBuilder: (context, index) {
                  return _buildGroupCard(groups[index]);
                },
              ),
            ),
    );
  }
}