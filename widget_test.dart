import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bonsamis/theme/theme.dart';
import 'package:bonsamis/widgets/widgets.dart';

void main() {
  test('Le thème centralisé expose les couleurs de la marque', () {
    expect(AppColors.primary, const Color(0xFF1B5E20));
    expect(AppColors.lightGreen, const Color(0xFFE8F5E9));
    expect(AppColors.secondary, const Color(0xFF2E7D32));
  });

  test('Le thème centralisé expose les textes qui ont remplacé les styles en dur',
      () {
    expect(AppTextStyles.badge.fontSize, 11);
    expect(AppTextStyles.badge.fontWeight, FontWeight.bold);
    expect(AppTextStyles.badge.color, AppColors.textLight);

    expect(AppTextStyles.buttonSmall.fontSize, 11);

    expect(AppTextStyles.categoryIcon.fontSize,
        AppDimensions.categoryIconSize);

    expect(AppTextStyles.avatarInitial.fontSize, AppDimensions.avatarFontSize);
    expect(AppTextStyles.avatarInitial.fontWeight, FontWeight.bold);
    expect(AppTextStyles.avatarInitial.color, AppColors.textLight);
  });

  testWidgets('AppBadge applique le style centralisé',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppBadge(text: 'Remboursé', icon: Icons.check),
        ),
      ),
    );

    expect(find.text('Remboursé'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);

    final badgeText = tester.widget<Text>(find.text('Remboursé'));
    expect(badgeText.style, AppTextStyles.badge);
  });

  testWidgets('AppButton utilise le style de bouton centralisé',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppButton(text: 'Ajouter')),
      ),
    );

    expect(find.text('Ajouter'), findsOneWidget);

    final material = tester.widget<ElevatedButton>(
      find.byType(ElevatedButton),
    );
    expect(
      material.style?.backgroundColor?.resolve({}),
      AppColors.secondary,
    );
  });
}
