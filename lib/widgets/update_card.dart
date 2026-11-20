import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../services/update_service.dart';
import '../theme/theme.dart';
import 'widgets.dart';

/// Carte « Mise à jour » :
/// - en mode [silentWhenUpToDate] (tableau de bord), la carte ne s'affiche
///   que si une mise à jour est disponible ;
/// - en mode normal (Profil), la carte est toujours visible avec un bouton
///   « Vérifier ».
///
/// Le flux : vérification auprès de GitHub -> téléchargement APK avec
/// barre de progression -> ouverture de l'installeur Android. L'utilisateur
/// confirme alors l'installation (Windows-like) et l'app redémarre sur la
/// nouvelle version, données conservées.
class UpdateCard extends StatefulWidget {
  final bool silentWhenUpToDate;

  const UpdateCard({
    super.key,
    this.silentWhenUpToDate = false,
  });

  @override
  State<UpdateCard> createState() => _UpdateCardState();
}

enum _UpdateState {
  unknown,      // Pas encore vérifié.
  checking,     // Vérification en cours.
  upToDate,     // Dernière version installée.
  available,    // Une nouvelle version existe.
  downloading,  // Téléchargement en cours.
  installing,   // Installeur ouvert, l'utilisateur confirme.
  error,        // Échec (message dans _errorMessage).
}

class _UpdateCardState extends State<UpdateCard> {
  _UpdateState _state = _UpdateState.unknown;
  String? _errorMessage;
  String _currentVersion = '';
  String _latestVersion = '';
  double _progress = 0;

  @override
  void initState() {
    super.initState();

    PackageInfo.fromPlatform().then((info) {
      if (!mounted) return;
      setState(() => _currentVersion = info.version);

      // Dès l'ouverture, la vérification est faite (silencieuse en cas
      // d'échec réseau : on n'accable pas l'utilisateur sans le wifi).
      _check(manual: false);
    });
  }

  Future<void> _check({required bool manual}) async {
    if (_state == _UpdateState.checking || _state == _UpdateState.downloading) {
      return;
    }

    setState(() {
      _state = _UpdateState.checking;
      _errorMessage = null;
    });

    try {
      final check = await UpdateService.instance.checkForUpdate(
        currentVersion: _currentVersion,
      );

      if (!mounted) return;

      setState(() {
        _latestVersion = check.latestVersion;
        _state = check.updateAvailable
            ? _UpdateState.available
            : _UpdateState.upToDate;
      });
    } on UpdateException catch (e) {
      if (!mounted) return;

      setState(() {
        _state = manual ? _UpdateState.error : _UpdateState.unknown;
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _state = manual ? _UpdateState.error : _UpdateState.unknown;
        _errorMessage = 'Erreur inattendue : $e';
      });
    }
  }

  Future<void> _install() async {
    setState(() {
      _state = _UpdateState.downloading;
      _progress = 0;
    });

    try {
      await UpdateService.instance.downloadAndInstall(
        onProgress: (p) {
          if (!mounted) return;
          setState(() => _progress = p);
        },
      );

      if (!mounted) return;

      // L'installeur Android est ouvert : l'utilisateur confirme
      // l'installation (et autorise « apps inconnues » la première fois).
      setState(() => _state = _UpdateState.installing);
    } on UpdateException catch (e) {
      if (!mounted) return;

      setState(() {
        _state = _UpdateState.error;
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _state = _UpdateState.error;
        _errorMessage = 'Erreur pendant la mise à jour : $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_state == _UpdateState.unknown && widget.silentWhenUpToDate) {
      // Pas de mise à jour (ou réseau indisponible) : rien à afficher.
      return const SizedBox.shrink();
    }

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.system_update, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Mise à jour',
                  style: AppTextStyles.title,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _UpdateState.checking:
        return const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Vérification de la dernière version…',
                style: AppTextStyles.subtitle,
              ),
            ),
          ],
        );

      case _UpdateState.upToDate:
        return Text(
          'ArgEnPo $_currentVersion est à jour.',
          style: AppTextStyles.subtitle,
        );

      case _UpdateState.available:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nouvelle version $_latestVersion disponible '
              '(version installée : $_currentVersion).',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: 12),
            AppButton(
              text: 'Mettre à jour',
              icon: Icons.download,
              onPressed: _install,
            ),
          ],
        );

      case _UpdateState.downloading:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Téléchargement… ${(_progress * 100).round()} %',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: _progress > 0 ? _progress : null),
          ],
        );

      case _UpdateState.installing:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirmez l\'installation dans l\'écran système qui s\'est '
              'ouvert. ArgEnPo redémarrera avec la nouvelle version et vos '
              'données seront conservées.',
              style: AppTextStyles.subtitle,
            ),
          ],
        );

      case _UpdateState.error:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _errorMessage ?? 'Erreur inconnue',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: 12),
            AppButton(
              text: 'Réessayer',
              icon: Icons.refresh,
              onPressed: () => _check(manual: true),
            ),
          ],
        );

      case _UpdateState.unknown:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version installée : $_currentVersion.',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: 12),
            AppButton(
              text: 'Vérifier les mises à jour',
              onPressed: () => _check(manual: true),
            ),
          ],
        );
    }
  }
}
