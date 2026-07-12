import 'package:flutter/material.dart';

import '../widgets/design_system/design_system.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: AppSpacing.page,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppSectionTitle(
              title: 'Mes groupes',
              subtitle: 'Retrouvez et gérez vos groupes de dépenses.',
              leading: Icon(AppIcons.groups),
              padding: EdgeInsets.only(
                bottom: AppSpacing.md,
              ),
            ),
            Expanded(
              child: Center(
                child: AppCard(
                  showShadow: false,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 420,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.lg,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              AppIcons.groups,
                              size: 36,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Mes groupes',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Vos groupes apparaîtront ici.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}