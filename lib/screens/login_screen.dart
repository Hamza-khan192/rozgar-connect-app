import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_page_route.dart';
import 'root_nav.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _goHome(User? user) {
    final navigator = Navigator.of(context);
    Widget next;
    if (user == null) {
      return;
    } else if (user.isAdmin) {
      next = const AdminRoot();
    } else if (user.isLaborer) {
      next = const LaborerRoot();
    } else {
      next = const CustomerRoot();
    }
    navigator.pushReplacement(AppPageRoute(builder: (_) => next));
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final phone = _phoneCtrl.text.trim();
    final password = _passCtrl.text;
    if (phone.isEmpty || password.isEmpty) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Please enter phone and password')));
      return;
    }
    setState(() => _busy = true);
    try {
      await auth.login(phone: phone, password: password);
      if (!mounted) return;
      _goHome(auth.currentUser);
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.handyman,
                    size: 64, color: theme.colorScheme.primary),
                const SizedBox(height: 12),
                const Text(
                  'Rozgar Connect',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text('Find trusted labor in Mardan'),
                const SizedBox(height: 28),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    hintText: '03331234567',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Login'),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                        AppPageRoute(builder: (_) => const SignupScreen()));
                  },
                  child: const Text("Don't have an account? Sign up"),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    _phoneCtrl.text = '03330000000';
                    _passCtrl.text = '123456';
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: theme.colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Demo admin — tap to fill\n03330000000 / 123456',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.secondary),
                    ),
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
