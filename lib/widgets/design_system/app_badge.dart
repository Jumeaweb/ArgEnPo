import 'package:flutter/material.dart';

/// Badge réutilisable destiné à afficher un compteur sur un widget.
///
/// Exemple :
///
/// AppBadge(
///   count: 3,
///   child: IconButton(
///     icon: const Icon(Icons.notifications_none),
///     onPressed: () {},
///   ),
/// )
class AppBadge extends StatelessWidget {
  const AppBadge({
    required this.child,
    required this.count,
    super.key,
    this.maxCount = 9,
    this.backgroundColor = Colors.red,
    this.foregroundColor = Colors.white,
    this.showWhenZero = false,
    this.top = 6,
    this.right = 6,
  });

  /// Widget sur lequel le badge est superposé.
  final Widget child;

  /// Nombre affiché dans le badge.
  final int count;

  /// Nombre maximal affiché directement.
  ///
  /// Au-delà de cette valeur, le badge affiche par exemple `9+`.
  final int maxCount;

  /// Couleur de fond du badge.
  final Color backgroundColor;

  /// Couleur du texte du badge.
  final Color foregroundColor;

  /// Affiche ou masque le badge lorsque [count] vaut zéro.
  final bool showWhenZero;

  /// Position du badge depuis le haut du widget.
  final double top;

  /// Position du badge depuis la droite du widget.
  final double right;

  String get _displayedCount {
    if (count > maxCount) {
      return '$maxCount+';
    }

    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final shouldShowBadge = count > 0 || showWhenZero;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (shouldShowBadge)
          Positioned(
            top: top,
            right: right,
            child: IgnorePointer(
              child: Semantics(
                label: count == 1
                    ? '1 élément en attente'
                    : '$count éléments en attente',
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _displayedCount,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: 10,
                      height: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}