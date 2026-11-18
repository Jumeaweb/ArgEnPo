import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'screens/reset_password_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!SupabaseConfig.isConfigured) {
    runApp(const BonsAmisApp(missingConfig: true));
    return;
  }

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  // Lien de l'e-mail « mot de passe oublié » : quand l'utilisateur clique
  // sur le lien (argenpo://reset-callback), Supabase émet l'événement
  // passwordRecovery et on ouvre l'écran de saisie du nouveau mot de passe.
  Supabase.instance.client.auth.onAuthStateChange.listen((state) {
    if (state.event == AuthChangeEvent.passwordRecovery) {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
        (route) => false,
      );
    }
  });

  runApp(const BonsAmisApp());
}

class BonsAmisApp extends StatelessWidget {
  final bool missingConfig;

  const BonsAmisApp({super.key, this.missingConfig = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: AppTheme.lightTheme,
      home: missingConfig
          ? const Scaffold(
              body: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Backend non configuré : complétez SUPABASE_URL et '
                    'SUPABASE_ANON_KEY dans lib/config/supabase_config.dart',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          : const SplashScreen(),
    );
  }
}
