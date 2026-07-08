import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../services/auth_service.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';
import '../layout/main_screen.dart';

import 'email_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();

  String appVersion = '';

  @override
  void initState() {
    super.initState();
    loadVersion();
  }

  Future<void> loadVersion() async {
    final info = await PackageInfo.fromPlatform();

    if (!mounted) return;

    setState(() {
      appVersion = '${info.version}+${info.buildNumber}';
    });
  }

  Future<void> _loginGoogle(BuildContext context) async {
    try {
      await _authService.signInWithGoogle();
      if (!context.mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const MainScreen(),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.padding),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE8F5E9),
              AppColors.background,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),

              Image.asset(
                'assets/images/logo_argenpo.png',
                height: 260,
              ),

              const SizedBox(height: 12),

              Text(
                'Partagez les dépenses\nentre amis simplement.',
                textAlign: TextAlign.center,
                style: AppTextStyles.sectionTitle.copyWith(
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 40),

              AppButton(
                text: 'Continuer avec Google',
                icon: Icons.login,
                onPressed: () => _loginGoogle(context),
              ),

              const SizedBox(height: 12),

              AppButton(
                text: 'Continuer avec Apple',
                icon: Icons.apple,
                backgroundColor: AppColors.textPrimary,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Connexion Apple bientôt disponible',
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              AppButton(
                text: 'Continuer avec Email',
                icon: Icons.email_outlined,
                backgroundColor: AppColors.primary,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EmailLoginScreen(),
                    ),
                  );
                },
              ),

              const Spacer(),

              Text(
                appVersion.isEmpty
                    ? ''
                    : 'Version $appVersion',
                style: AppTextStyles.small.copyWith(
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}