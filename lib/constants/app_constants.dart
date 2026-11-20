/// Constantes applicatives partagées.
class AppConstants {
  /// Lien de soutien (Stripe Payment Link, montant libre).
  /// Modifiable dans le dashboard Stripe sans changement d'application :
  /// l'URL est stable d'une version à l'autre.
  static const String donationUrl =
      'https://donate.stripe.com/14A7sK6Wx6Ze6tf16m3sI00';
}
