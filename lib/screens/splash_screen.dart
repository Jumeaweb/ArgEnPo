import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      AnimationController(vsync: this, duration: const Duration(seconds: 6));

  late final List<Animation<double>> _wordFades;
  late final List<Animation<double>> _wordSlides;

  static const List<String> _words = ['Argent', 'Entre', 'Potes'];

  @override
  void initState() {
    super.initState();

    // Les trois mots apparaissent l'un après l'autre en fondu.
    _wordFades = List.generate(_words.length, (i) {
      final start = 0.05 + i * 0.18;
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, start + 0.15, curve: Curves.easeOut),
        ),
      );
    });

    // Chaque mot monte légèrement pendant son apparition.
    _wordSlides = List.generate(_words.length, (i) {
      final start = 0.05 + i * 0.18;
      return Tween<double>(begin: 20, end: 0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, start + 0.15, curve: Curves.easeOut),
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
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.lightGreen,
              AppColors.background,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_words.length, (i) {
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
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    _words[i],
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
