import 'package:flutter/material.dart';

import '../models/activity_model.dart';
import '../services/activity_service.dart';
import '../theme/activity_theme.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';

class ActivityScreen extends StatelessWidget {
  final String groupId;

  const ActivityScreen({
    super.key,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    final activityService = ActivityService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        title: const Text(
          'Activités',
          style: AppTextStyles.appBarTitle,
        ),
      ),
      body: StreamBuilder<List<ActivityModel>>(
        stream: activityService.watchActivities(groupId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _ActivityLoadingState();
          }

          if (snapshot.hasError) {
            return const _ActivityErrorState();
          }

          final activities = snapshot.data ?? const <ActivityModel>[];

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: activities.isEmpty
                ? const _EmptyActivityState(
                    key: ValueKey('empty-activities'),
                  )
                : _ActivityTimeline(
                    key: const ValueKey('activity-timeline'),
                    activities: activities,
                  ),
          );
        },
      ),
    );
  }
}

class _ActivityTimeline extends StatelessWidget {
  final List<ActivityModel> activities;

  const _ActivityTimeline({
    super.key,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    final groupedActivities = _groupActivitiesByDate(activities);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        for (final entry in groupedActivities.entries) ...[
          _DateSectionHeader(
            title: entry.key,
            activityCount: entry.value.length,
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < entry.value.length; index++)
            _AnimatedActivityEntry(
              activity: entry.value[index],
              index: index,
              isLast: index == entry.value.length - 1,
            ),
          const SizedBox(height: 18),
        ],
      ],
    );
  }

  Map<String, List<ActivityModel>> _groupActivitiesByDate(
    List<ActivityModel> activities,
  ) {
    final grouped = <String, List<ActivityModel>>{};

    for (final activity in activities) {
      final label = _dateLabel(activity.createdAt);
      grouped.putIfAbsent(label, () => <ActivityModel>[]).add(activity);
    }

    return grouped;
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final activityDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(activityDate).inDays;

    if (difference == 0) {
      return 'Aujourd’hui';
    }

    if (difference == 1) {
      return 'Hier';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _AnimatedActivityEntry extends StatelessWidget {
  final ActivityModel activity;
  final int index;
  final bool isLast;

  const _AnimatedActivityEntry({
    required this.activity,
    required this.index,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final cappedIndex = index > 8 ? 8 : index;
    final duration = Duration(
      milliseconds: 260 + (cappedIndex * 40),
    );

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)),
            child: child,
          ),
        );
      },
      child: _TimelineEntry(
        activity: activity,
        isLast: isLast,
      ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  final ActivityModel activity;
  final bool isLast;

  const _TimelineEntry({
    required this.activity,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 48,
          child: Column(
            children: [
              _ActivityAvatar(activity: activity),
              if (!isLast)
                Container(
                  width: 2,
                  height: 42,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: isLast ? 0 : 10,
            ),
            child: _ActivityCard(activity: activity),
          ),
        ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final ActivityModel activity;

  const _ActivityCard({
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    final details = _activityDetails(activity);
    final amount = activity.amount;

    final style = activityStyle(activity.type);

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: style.color.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          activity.userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.title,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _TimeChip(date: activity.createdAt),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          details.message,
                          style: AppTextStyles.subtitle.copyWith(
                            height: 1.3,
                          ),
                        ),
                      ),
                      if (amount != null) ...[
                        const SizedBox(width: 10),
                        _AmountText(
                          amount: amount,
                          color: details.amountColor,
                        ),
                      ],
                    ],
                  ),
                  if (details.secondaryText != null &&
                      details.secondaryText!.trim().isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      details.secondaryText!,
                      style: AppTextStyles.title.copyWith(
                        fontSize: 14,
                        height: 1.25,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final DateTime date;

  const _TimeChip({
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.schedule_rounded,
            size: 13,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            _formatTime(date),
            style: AppTextStyles.subtitle.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}

class _AmountText extends StatelessWidget {
  final double amount;
  final Color color;

  const _AmountText({
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      '${amount.toStringAsFixed(2)} €',
      style: AppTextStyles.amount.copyWith(
        color: color,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ActivityAvatar extends StatelessWidget {
  final ActivityModel activity;

  const _ActivityAvatar({
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    final photoUrl = activity.userPhotoUrl;
    final style = activityStyle(activity.type);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          backgroundImage: photoUrl != null && photoUrl.trim().isNotEmpty
              ? NetworkImage(photoUrl)
              : null,
          child: photoUrl == null || photoUrl.trim().isEmpty
              ? Text(
                  _initials(activity.userName),
                  style: AppTextStyles.title.copyWith(
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                )
              : null,
        ),
        Positioned(
          right: -4,
          bottom: -4,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.background,
                width: 2,
              ),
            ),
            child: Icon(
              style.icon,
              size: 13,
              color: style.color,
            ),
          ),
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}'
            '${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}

class _DateSectionHeader extends StatelessWidget {
  final String title;
  final int activityCount;

  const _DateSectionHeader({
    required this.title,
    required this.activityCount,
  });

  @override
  Widget build(BuildContext context) {
    final countLabel = activityCount == 1
        ? '1 activité'
        : '$activityCount activités';

    return Row(
      children: [
        Text(
          title,
          style: AppTextStyles.title.copyWith(
            color: AppColors.primary,
            fontSize: 17,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            countLabel,
            style: AppTextStyles.subtitle.copyWith(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

class _ActivityLoadingState extends StatelessWidget {
  const _ActivityLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: const [
        _LoadingSectionHeader(),
        SizedBox(height: 14),
        _LoadingTimelineEntry(),
        _LoadingTimelineEntry(),
        _LoadingTimelineEntry(),
      ],
    );
  }
}

class _LoadingSectionHeader extends StatelessWidget {
  const _LoadingSectionHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _LoadingBlock(
          width: 110,
          height: 20,
          borderRadius: 8,
        ),
        Spacer(),
        _LoadingBlock(
          width: 72,
          height: 24,
          borderRadius: 999,
        ),
      ],
    );
  }
}

class _LoadingTimelineEntry extends StatelessWidget {
  const _LoadingTimelineEntry();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 48,
          child: Column(
            children: [
              const _LoadingBlock(
                width: 36,
                height: 36,
                borderRadius: 999,
              ),
              Container(
                width: 2,
                height: 42,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: AppColors.textSecondary.withValues(alpha: 0.12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: AppCard(
              padding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 9,
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _LoadingBlock(
                      width: 4,
                      height: double.infinity,
                      borderRadius: 999,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _LoadingBlock(
                                  width: double.infinity,
                                  height: 15,
                                  borderRadius: 7,
                                ),
                              ),
                              SizedBox(width: 16),
                              _LoadingBlock(
                                width: 54,
                                height: 24,
                                borderRadius: 999,
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          _LoadingBlock(
                            width: 170,
                            height: 13,
                            borderRadius: 7,
                          ),
                          SizedBox(height: 7),
                          _LoadingBlock(
                            width: 120,
                            height: 13,
                            borderRadius: 7,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingBlock extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _LoadingBlock({
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  State<_LoadingBlock> createState() => _LoadingBlockState();
}

class _LoadingBlockState extends State<_LoadingBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _opacity = Tween<double>(
      begin: 0.35,
      end: 0.75,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.textSecondary.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

class _EmptyActivityState extends StatelessWidget {
  const _EmptyActivityState({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Opacity(
            opacity: value.clamp(0, 1),
            child: Transform.scale(
              scale: 0.92 + (0.08 * value),
              child: child,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.history_rounded,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Aucune activité',
                style: AppTextStyles.title,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Les prochaines actions réalisées dans ce groupe apparaîtront ici.',
                style: AppTextStyles.subtitle,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityErrorState extends StatelessWidget {
  const _ActivityErrorState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 46,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Impossible de charger les activités',
              style: AppTextStyles.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Vérifiez votre connexion. La liste se rechargera automatiquement.',
              style: AppTextStyles.subtitle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityPresentation {
  final String message;
  final String? secondaryText;
  final Color amountColor;

  const _ActivityPresentation({
    required this.message,
    required this.secondaryText,
    required this.amountColor,
  });
}

_ActivityPresentation _activityDetails(ActivityModel activity) {
  switch (activity.type) {
    case ActivityType.groupCreated:
      return _ActivityPresentation(
        message: 'a créé le groupe',
        secondaryText: activity.title,
        amountColor: activityStyle(activity.type).color,
      );

    case ActivityType.groupRenamed:
      return _ActivityPresentation(
        message: 'a renommé le groupe',
        secondaryText: activity.title,
        amountColor: activityStyle(activity.type).color,
      );

    case ActivityType.memberAdded:
      return _ActivityPresentation(
        message: 'a ajouté un membre',
        secondaryText: activity.targetUserName,
        amountColor: activityStyle(activity.type).color,
      );

    case ActivityType.memberJoined:
      return _ActivityPresentation(
        message: 'a rejoint le groupe',
        secondaryText: activity.targetUserName,
        amountColor: activityStyle(activity.type).color,
      );

    case ActivityType.memberLeft:
      return _ActivityPresentation(
        message: 'a quitté le groupe',
        secondaryText: activity.targetUserName,
        amountColor: activityStyle(activity.type).color,
      );

    case ActivityType.expenseCreated:
      return _ActivityPresentation(
        message: 'a ajouté une dépense',
        secondaryText: activity.title,
        amountColor: activityStyle(activity.type).color,
      );

    case ActivityType.expenseUpdated:
      return _ActivityPresentation(
        message: 'a modifié une dépense',
        secondaryText: activity.title,
        amountColor: activityStyle(activity.type).color,
      );

    case ActivityType.expenseDeleted:
      return _ActivityPresentation(
        message: 'a supprimé une dépense',
        secondaryText: activity.title,
        amountColor: activityStyle(activity.type).color,
      );

    case ActivityType.repaymentCreated:
      return _ActivityPresentation(
        message: activity.targetUserName == null
            ? 'a enregistré un remboursement'
            : 'a remboursé ${activity.targetUserName}',
        secondaryText: null,
        amountColor: activityStyle(activity.type).color,
      );

    case ActivityType.repaymentDeleted:
      return _ActivityPresentation(
        message: 'a supprimé un remboursement',
        secondaryText: activity.targetUserName,
        amountColor: activityStyle(activity.type).color,
      );

    case ActivityType.invitationSent:
      return _ActivityPresentation(
        message: 'a envoyé une invitation',
        secondaryText: activity.targetUserName,
        amountColor: activityStyle(activity.type).color,
      );

    case ActivityType.invitationAccepted:
      return _ActivityPresentation(
        message: 'a accepté l’invitation',
        secondaryText: activity.title,
        amountColor: activityStyle(activity.type).color,
      );

    case ActivityType.invitationDeclined:
      return _ActivityPresentation(
        message: 'a refusé l’invitation',
        secondaryText: activity.title,
        amountColor: activityStyle(activity.type).color,
      );
  }
}
