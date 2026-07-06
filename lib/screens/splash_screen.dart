import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../layout/main_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scale = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();

    Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;

      final user = FirebaseAuth.instance.currentUser;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => user != null
            ? const MainScreen()
            : LoginScreen(),
        ),
      );
    });
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
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo_argenpo.png',
                  height: 210,
                ),
                const SizedBox(height: 24),
                Text(
                  'ArgEnPo',
                  style: AppTextStyles.appBarTitle.copyWith(
                    color: AppColors.primary,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Les comptes entre amis,\nsans prise de tête.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.subtitle.copyWith(
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}