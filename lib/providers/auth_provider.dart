import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/api_repository.dart';
import '../data/app_repository.dart';
import '../models/user.dart';

/// Owns the session: login / register / logout / restore.
class AuthProvider extends ChangeNotifier {
  final AppRepository _repo;

  User? _currentUser;
  bool _restoring = true;

  AuthProvider(this._repo);

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isRestoring => _restoring;

  Future<void> login(
      {required String phone, required String password}) async {
    final user = await _repo.login(phone: phone, password: password);
    _currentUser = user;
    await _persist(user);
    notifyListeners();
  }

  Future<void> register(
      {required String name,
      required String phone,
      required String password,
      required String role}) async {
    final user = await _repo.register(
        name: name, phone: phone, password: password, role: role);
    _currentUser = user;
    await _persist(user);
    notifyListeners();
  }

  /// Restores a previously persisted session (called once from SplashScreen).
  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('user_id');
    if (id != null) {
      _currentUser = User(
        userId: id,
        name: prefs.getString('user_name') ?? '',
        phone: prefs.getString('user_phone') ?? '',
        role: prefs.getString('user_role') ?? 'customer',
      );
    }
    _restoring = false;
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_phone');
    await prefs.remove('user_role');
    final repo = _repo;
    if (repo is ApiRepository) {
      await repo.clearToken();
    }
    notifyListeners();
  }

  Future<void> _persist(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', user.userId);
    await prefs.setString('user_name', user.name);
    await prefs.setString('user_phone', user.phone);
    await prefs.setString('user_role', user.role);
  }
}
