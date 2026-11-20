import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// Vérification et installation des mises à jour de l'application.
///
/// La source de vérité est la page Releases du dépôt GitHub Jumeaweb/ArgEnPo :
/// c'est la même API « releases/latest » que le badge de jumeaweb.fr, donc
/// publier une release GitHub suffit pour que tout se mette à jour.
class UpdateService {
  static const _owner = 'Jumeaweb';
  static const _repo = 'ArgEnPo';
  static const _latestUrl =
      'https://api.github.com/repos/$_owner/$_repo/releases/latest';

  UpdateService._private();

  static final UpdateService instance = UpdateService._private();

  String? _cachedApkUrl;
  String? _cachedNotes;

  /// Résultat d'une vérification de version.
  /// [updateAvailable] est vrai si [latestVersion] est plus récente que
  /// [currentVersion].
  Future<UpdateCheck> checkForUpdate({required String currentVersion}) async {
    final http.Response response;

    try {
      response = await http
          .get(
            Uri.parse(_latestUrl),
            headers: {
              'Accept': 'application/vnd.github+json',
              // L'API GitHub exige un User-Agent.
              'User-Agent': 'ArgEnPo',
            },
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw UpdateException('Délai dépassé : vérifiez votre connexion.');
    } on SocketException {
      throw UpdateException('Pas de connexion internet.');
    }

    if (response.statusCode == 404) {
      // Aucune release publiée : rien à proposer.
      throw UpdateException('Aucune version disponible.');
    }

    if (response.statusCode != 200) {
      throw UpdateException('GitHub a répondu ${response.statusCode}.');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    final tag = (data['tag_name'] as String? ?? '').trim();
    if (tag.isEmpty) {
      throw UpdateException('Version introuvable dans la release GitHub.');
    }

    final latestVersion = tag.replaceFirst(RegExp('^v', caseSensitive: false), '');

    // L'APK est l'asset joint à la release qui finit par .apk.
    String? apkUrl;
    final assets = data['assets'] as List<dynamic>? ?? const [];
    for (final asset in assets) {
      final name = (asset['name'] as String? ?? '').toLowerCase();
      final url = asset['browser_download_url'] as String?;
      if (url != null && name.endsWith('.apk')) {
        apkUrl = url;
        break;
      }
    }

    if (apkUrl == null) {
      throw UpdateException(
        'La release $latestVersion ne contient pas de fichier APK.',
      );
    }

    _cachedApkUrl = apkUrl;
    _cachedNotes = data['body'] as String? ?? '';

    return UpdateCheck(
      currentVersion: currentVersion,
      latestVersion: latestVersion,
      apkUrl: apkUrl,
      notes: _cachedNotes!,
      updateAvailable: isNewer(latestVersion, currentVersion),
    );
  }

  /// Compare deux numéros de version « 1.2.3 » partie par partie.
  /// Renvoie vrai si [candidate] est strictement plus récente que [current].
  static bool isNewer(String candidate, String current) {
    final c = _versionParts(candidate);
    final u = _versionParts(current);

    for (var i = 0; i < c.length; i++) {
      if (i >= u.length || c[i] > u[i]) return true;
      if (c[i] < u[i]) return false;
    }

    return false;
  }

  static List<int> _versionParts(String version) {
    // Ne garde que les chiffres : « 1.0.4+5 » ou « v1.0.4 » -> [1, 0, 4].
    final match = RegExp(r'[\d.]+').firstMatch(version);
    if (match == null) return [0];

    return match.group(0)!
        .split('.')
        .map((p) => int.tryParse(p) ?? 0)
        .toList();
  }

  /// Télécharge l'APK de la dernière version puis ouvre l'installeur Android.
  ///
  /// [onProgress] reçoit la progression de 0.0 à 1.0. Si l'utilisateur n'a
  /// pas encore autorisé « installer des apps inconnues » pour ArgEnPo,
  /// Android affiche l'écran d'autorisation (à faire une seule fois).
  Future<void> downloadAndInstall({
    void Function(double progress)? onProgress,
  }) async {
    final apkUrl = _cachedApkUrl;

    if (apkUrl == null) {
      throw UpdateException(
        'Vérifiez d\'abord les mises à jour avant de télécharger.',
      );
    }

    final request = http.Request('GET', Uri.parse(apkUrl));
    request.headers['User-Agent'] = 'ArgEnPo';

    final response = await http.Client().send(request);

    if (response.statusCode != 200) {
      throw UpdateException(
        'Téléchargement impossible (code ${response.statusCode}).',
      );
    }

    final contentLength = response.contentLength ?? 0;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/argenpo-mise-a-jour.apk');

    final sink = file.openWrite();
    var received = 0;

    try {
      await for (final chunk in response.stream) {
        received += chunk.length;
        sink.add(chunk);

        if (contentLength > 0 && onProgress != null) {
          onProgress((received / contentLength).clamp(0.0, 1.0));
        }
      }
      await sink.flush();
    } finally {
      await sink.close();
    }

    onProgress?.call(1.0);

    final result = await OpenFilex.open(
      file.path,
      type: 'application/vnd.android.package-archive',
    );

    if (result.type != ResultType.done) {
      throw UpdateException(
        'Ouverture de l\'installeur impossible : ${result.message}',
      );
    }
  }
}

/// Le résultat d'une vérification.
class UpdateCheck {
  final String currentVersion;
  final String latestVersion;
  final String apkUrl;
  final String notes;
  final bool updateAvailable;

  const UpdateCheck({
    required this.currentVersion,
    required this.latestVersion,
    required this.apkUrl,
    required this.notes,
    required this.updateAvailable,
  });
}

/// Erreur compréhensible affichée à l'utilisateur.
class UpdateException implements Exception {
  final String message;

  const UpdateException(this.message);

  @override
  String toString() => message;
}
