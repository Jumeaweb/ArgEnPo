import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../widgets/widgets.dart';

import 'email_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.padding),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.lightGreen, AppColors.background],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),

              Image.asset('assets/images/logo_argenpo.png', height: 260),

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
                text: 'Continuer avec Email',
                icon: Icons.email_outlined,
                backgroundColor: AppColors.primary,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EmailLoginScreen()),
                  );
                },
              ),

              const Spacer(),

              const AppFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
