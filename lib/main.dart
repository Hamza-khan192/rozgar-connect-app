import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config.dart';
import 'data/api_repository.dart';
import 'data/app_repository.dart';
import 'data/mock_repository.dart';
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final AppRepository repo = kUseApi ? ApiRepository() : MockRepository();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(repo)),
        ChangeNotifierProxyProvider<AuthProvider, DataProvider>(
          create: (_) => DataProvider(repo),
          update: (_, auth, data) => data!..setUser(auth.currentUser),
        ),
      ],
      child: const RozgarApp(),
    ),
  );
}

class RozgarApp extends StatelessWidget {
  const RozgarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rozgar Connect',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const SplashScreen(),
    );
  }
}
