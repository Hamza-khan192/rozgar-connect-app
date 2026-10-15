import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_page_route.dart';
import 'login_screen.dart';
import 'root_nav.dart';

/// Restores the saved session, then routes to the role home or login.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    final auth = context.read<AuthProvider>();
    await auth.restore();
    // Let the entrance animation play before routing.
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      AppPageRoute(builder: (_) => _nextFor(auth.currentUser)),
    );
  }

  Widget _nextFor(User? user) {
    if (user == null) return const LoginScreen();
    if (user.isAdmin) return const AdminRoot();
    if (user.isLaborer) return const LaborerRoot();
    return const CustomerRoot();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.handyman, size: 72, color: theme.colorScheme.primary)
                .animate()
                .fadeIn(duration: 500.ms)
                .scale(
                    begin: const Offset(0.6, 0.6),
                    end: const Offset(1, 1),
                    duration: 700.ms,
                    curve: Curves.easeOutBack),
            const SizedBox(height: 16),
            Text(
              'Rozgar Connect',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            )
                .animate(delay: 200.ms)
                .fadeIn(duration: 500.ms)
                .slideY(
                    begin: 0.4,
                    end: 0,
                    duration: 500.ms,
                    curve: Curves.easeOut),
            const SizedBox(height: 8),
            const Text('Mazdoor • Mistri • Rozgar — Mardan')
                .animate(delay: 400.ms)
                .fadeIn(duration: 500.ms),
          ],
        ),
      ),
    );
  }
}
