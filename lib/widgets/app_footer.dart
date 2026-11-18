import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/theme.dart';

/// Pied de page commun : lien éditeur et numéro de version, sur une ligne.
class AppFooter extends StatefulWidget {
  const AppFooter({super.key});

  @override
  State<AppFooter> createState() => _AppFooterState();
}

class _AppFooterState extends State<AppFooter> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();

    if (!mounted) return;

    setState(() {
      _version = info.version;
    });
  }

  Future<void> _openSite() async {
    final url = Uri.parse('https://www.jumeaweb.fr/');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _openSite,
            child: Text(
              'Par JUMEAWEB',
              style: AppTextStyles.small.copyWith(
                color: AppColors.primary,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_version.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              '•',
              style: AppTextStyles.small.copyWith(color: AppColors.textGrey),
            ),
            const SizedBox(width: 8),
            Text(
              'Version $_version',
              style: AppTextStyles.small.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
