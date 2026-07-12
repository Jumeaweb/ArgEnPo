import 'package:flutter/material.dart';

import 'app_radius.dart';

/// Avatar standard du Design System ArgEnPo.
///
/// Affiche en priorité une image distante. En cas d’absence d’image,
/// le composant affiche les initiales, puis une icône de secours.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.radius = 22,
    this.backgroundColor,
    this.foregroundColor,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 2,
    this.maxInitials = 2,
  }) : assert(
          maxInitials > 0,
          'maxInitials doit être supérieur à zéro.',
        );

  final String? imageUrl;
  final String? name;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;

  /// Nombre maximal d’initiales affichées.
  ///
  /// Utiliser `1` pour les groupes et `2` pour les utilisateurs.
  final int maxInitials;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final effectiveBackgroundColor =
        backgroundColor ?? colorScheme.primaryContainer;

    final effectiveForegroundColor =
        foregroundColor ?? colorScheme.onPrimaryContainer;

    final effectiveBorderColor = borderColor ?? colorScheme.surface;

    final trimmedImageUrl = imageUrl?.trim();
    final hasImage =
        trimmedImageUrl != null && trimmedImageUrl.isNotEmpty;

    final initials = _buildInitials(name);

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: effectiveBorderColor,
                width: borderWidth,
              )
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: CircleAvatar(
          radius: radius,
          backgroundColor: effectiveBackgroundColor,
          foregroundImage:
              hasImage ? NetworkImage(trimmedImageUrl) : null,
          onForegroundImageError: hasImage ? (_, _) {} : null,
          child: _FallbackContent(
            initials: initials,
            foregroundColor: effectiveForegroundColor,
          ),
        ),
      ),
    );
  }

  String _buildInitials(String? value) {
    final trimmedName = value?.trim();

    if (trimmedName == null || trimmedName.isEmpty) {
      return '';
    }

    final parts = trimmedName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '';
    }

    if (maxInitials == 1 || parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    final initials = <String>[
      parts.first.substring(0, 1),
      parts.last.substring(0, 1),
    ];

    return initials.take(maxInitials).join().toUpperCase();
  }
}

class _FallbackContent extends StatelessWidget {
  const _FallbackContent({
    required this.initials,
    required this.foregroundColor,
  });

  final String initials;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    if (initials.isEmpty) {
      return Icon(
        Icons.person_rounded,
        color: foregroundColor,
      );
    }

    return Text(
      initials,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: foregroundColor,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}