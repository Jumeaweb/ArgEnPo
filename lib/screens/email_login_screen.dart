import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';

import 'home_screen.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() =>
      _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final AuthService _authService = AuthService();
  final SupabaseClient _client = Supabase.instance.client;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();

  bool createAccount = false;
  bool obscurePassword = true;

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

      final signedIn = _authService.currentSession != null;

      if (signedIn) {
        // Connexion réussie : on ouvre l'accueil en effaçant toute
        // la pile de navigation (sinon on resterait sur la connexion).
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        // Création de compte : email de confirmation envoyé, pas de
        // session tant que l'utilisateur n'a pas cliqué sur le lien.
        _showMessage(
          'Compte créé. Confirmez votre email avant de vous connecter.',
        );
      }
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
      // Le lien de l'e-mail ouvre directement l'application
      // (schéma déclaré dans AndroidManifest), qui affichera
      // l'écran de saisie du nouveau mot de passe.
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'argenpo://reset-callback',
      );

      _showMessage(
        'Email de réinitialisation envoyé. Ouvrez le lien reçu sur ce téléphone.',
      );
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
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
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