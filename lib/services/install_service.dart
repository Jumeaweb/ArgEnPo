import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Statistiques d'installation, totalement anonymes.
///
/// Au premier lancement, un identifiant aléatoire (uuid) est généré et
/// conservé sur le téléphone. À chaque démarrage, l'app envoie ce seul
/// identifiant avec la version et la plateforme : ni adresse, ni compte,
/// ni contenu de l'application n'est transmis.
class InstallService {
  static const _installIdKey = 'install_id';

  final SupabaseClient _client = Supabase.instance.client;

  /// Appelé au démarrage, sans blocage : les erreurs sont ignorées, le
  /// compteur n'a jamais à gêner l'utilisation de l'application.
  Future<void> sendPing() async {
    try {
      final installId = await _getOrCreateInstallId();
      final packageInfo = await PackageInfo.fromPlatform();

      await _client.rpc('ping_app_install', params: {
        'ping_install_id': installId,
        'ping_app_version': packageInfo.version,
        'ping_platform': Platform.operatingSystem,
      });
    } catch (_) {
      // Silencieux : pas de connexion, pas grave.
    }
  }

  Future<String> _getOrCreateInstallId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_installIdKey);

    if (existing != null) {
      return existing;
    }

    final installId = const Uuid().v4();
    await prefs.setString(_installIdKey, installId);
    return installId;
  }
}
