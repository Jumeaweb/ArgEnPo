import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

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

  runApp(const BonsAmisApp());
}

class BonsAmisApp extends StatelessWidget {
  final bool missingConfig;

  const BonsAmisApp({super.key, this.missingConfig = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
