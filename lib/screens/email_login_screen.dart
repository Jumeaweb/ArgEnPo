import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';
import '../layout/main_screen.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() =>
      _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final AuthService _authService = AuthService();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();

  bool createAccount = false;

  Future<void> submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final name = nameController.text.trim();

    if (email.isEmpty) {
      _showMessage('Veuillez saisir votre adresse email.');
      return;
    }

    if (password.isEmpty) {
      _showMessage('Veuillez saisir votre mot de passe.');
      return;
    }

    if (createAccount && name.isEmpty) {
      _showMessage('Veuillez saisir votre nom.');
      return;
    }

    try {
      if (createAccount) {
        await _authService.createAccountWithEmail(
          email: email,
          password: password,
          name: name,
        );
      } else {
        await _authService.signInWithEmail(
          email: email,
          password: password,
        );
      }

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const MainScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      _showMessage(e.toString());
    }
  }

  Future<void> resetPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      _showMessage('Veuillez saisir votre adresse email.');
      return;
    }

    try {
      await _authService.resetPassword(email);

      _showMessage('Email de réinitialisation envoyé.');
    } catch (e) {
      _showMessage(e.toString());
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        title: Text(
          createAccount ? 'Créer un compte' : 'Connexion Email',
          style: AppTextStyles.appBarTitle,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.padding),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  createAccount
                      ? 'Créer un compte ArgEnPo'
                      : 'Se connecter avec Email',
                  style: AppTextStyles.sectionTitle,
                ),

                const SizedBox(height: 20),

                if (createAccount) ...[
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),

                const SizedBox(height: 24),

                AppButton(
                  text: createAccount
                      ? 'Créer le compte'
                      : 'Se connecter',
                  icon: createAccount
                      ? Icons.person_add
                      : Icons.login,
                  onPressed: submit,
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        createAccount = !createAccount;
                      });
                    },
                    child: Text(
                      createAccount
                          ? 'J’ai déjà un compte'
                          : 'Créer un compte',
                      style: AppTextStyles.subtitle.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: resetPassword,
                    child: Text(
                      'Mot de passe oublié ?',
                      style: AppTextStyles.subtitle.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}