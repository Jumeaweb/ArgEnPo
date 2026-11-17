/// Configuration du backend Supabase.
///
/// Créez le projet au choix de la région "West EU (Paris)" puis
/// collez ici l'URL et la clé publique (publishable) disponibles dans
/// le dashboard Supabase : Settings > API.
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://vgcvrzcaruyznhjmikvk.supabase.co',
  );

  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_HwwGIOjDMvUA0aaqY-hs5w_7M4ylbZf',
  );

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}
