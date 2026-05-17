import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/supabase_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/pokedex_lens.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isChecking = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    setState(() {
      _isChecking = true;
      _hasError = false;
    });

    try {
      final client = supabaseClient;
      if (client == null) {
        throw Exception('Supabase is not configured.');
      }

      final hasSession = client.auth.currentSession != null;

      if (!mounted) {
        return;
      }

      if (hasSession) {
        context.go('/home');
      } else {
        context.go('/login');
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isChecking = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const PokedexLens(size: 140),
                const SizedBox(height: 28),
                const Text(
                  'Pokédex',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 24),
                if (_hasError) ...[
                  const Text(
                    'Something went wrong. Try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _checkSession,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.onPrimary,
                    ),
                    child: const Text('Try again'),
                  ),
                ] else if (_isChecking)
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
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
