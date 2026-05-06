import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              'assets/images/logo.png',
              width: 280,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.business,
                size: 100,
                color: Color(0xFFCC2200),
              ),
            ),
            const SizedBox(height: 16),
            // Brand Text
            const Text(
              'BY TINIRI MARKETING',
              style: TextStyle(
                color: Color(0xFFCC2200),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            // Subtitle
            const Text(
              'Simplifiez votre gestion, développez votre coopérative',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
