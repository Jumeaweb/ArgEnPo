class ExpenseCategories {
  static const List<String> all = [
    'Assurances',
    'Autre',
    'Courses',
    'Hébergement',
    'Location',
    'Loisirs',
    'Restaurant',
    'Transport',
  ];
}
class ExpenseCategoryIcons {
  static String get(String category) {
    switch (category) {
      case 'Assurances':
        return '🛡️';

      case 'Courses':
        return '🛒';

      case 'Hébergement':
        return '🏨';

      case 'Location':
        return '🔑';

      case 'Loisirs':
        return '🎬';

      case 'Restaurant':
        return '🍽️';

      case 'Transport':
        return '🚗';

      default:
        return '💶';
    }
  }
}