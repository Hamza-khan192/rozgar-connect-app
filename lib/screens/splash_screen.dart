import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/auth_provider.dart';
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
    if (!mounted) return;
    final navigator = Navigator.of(context);
    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => _nextFor(auth.currentUser)),
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
            Icon(Icons.handyman,
                size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Rozgar Connect',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Mazdoor • Mistri • Rozgar — Mardan'),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
