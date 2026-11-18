import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/install_service.dart';
import '../theme/theme.dart';

import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 5));

  late final List<Animation<double>> _wordFades;
  late final List<Animation<double>> _wordSlides;

  static const List<String> _words = ['Argent', 'Entre', 'Potes'];

  @override
  void initState() {
    super.initState();

    // Compteur d'installations, sans identité ni contenu : lancé sans
    // attendre, il n'a aucune influence sur l'affichage.
    InstallService().sendPing();

    // Les trois mots apparaissent l'un après l'autre en fondu.
    _wordFades = List.generate(_words.length, (i) {
      final start = 0.08 + i * 0.16;
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, start + 0.16, curve: Curves.easeOut),
        ),
      );
    });

    // Chaque mot monte légèrement pendant son apparition.
    _wordSlides = List.generate(_words.length, (i) {
      final start = 0.08 + i * 0.16;
      return Tween<double>(begin: 20, end: 0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, start + 0.16, curve: Curves.easeOut),
        ),
      );
    });

    _controller.addStatusListener(_onStatus);
    _controller.forward();
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _controller.removeStatusListener(_onStatus);

    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            session != null ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Halos décoratifs, façon maquette (verts au lieu de corail/turquoise).
          Positioned(
            top: -140,
            left: -100,
            child: _blob(AppColors.primary, 0.10, 420),
          ),
          Positioned(
            bottom: -120,
            right: -80,
            child: _blob(AppColors.secondary, 0.08, 360),
          ),

          // Contenu central.
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'BIENVENUE SUR',
                  style: AppTextStyles.small.copyWith(
                    letterSpacing: 3,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),
                ...List.generate(_words.length, (i) {
                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _wordFades[i].value,
                        child: Transform.translate(
                          offset: Offset(0, _wordSlides[i].value),
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Text(
                          _words[i],
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),

                // Petit trait puis nom de l'application.
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return Opacity(
                      opacity: _wordFades[2].value.clamp(0.0, 1.0),
                      child: Column(
                        children: [
                          Container(
                            width: 120,
                            height: 2,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ShaderMask(
                            shaderCallback: (bounds) =>
                                const LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.secondary
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                            child: const Text(
                              'ArgEnPo',
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Partagez les dépenses entre amis,\nsimplement.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.subtitle.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Halo circulaire adouci (radial-gradient du HTML).
  Widget _blob(Color color, double opacity, double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
