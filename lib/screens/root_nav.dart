import 'package:flutter/material.dart';

import 'account_screen.dart';
import 'admin_dashboard_screen.dart';
import 'customer_home_screen.dart';
import 'favorites_screen.dart';
import 'laborer_home_screen.dart';
import 'my_jobs_screen.dart';

/// Bottom-navigation root for customers: Home, My Jobs, Favorites, Account.
class CustomerRoot extends StatefulWidget {
  const CustomerRoot({super.key});

  @override
  State<CustomerRoot> createState() => _CustomerRootState();
}

class _CustomerRootState extends State<CustomerRoot> {
  int _index = 0;

  static const _pages = [
    CustomerHomeScreen(),
    MyJobsScreen(),
    FavoritesScreen(),
    AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'My Jobs'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }
}

/// Bottom-navigation root for laborers: Dashboard, Jobs, Account.
class LaborerRoot extends StatefulWidget {
  const LaborerRoot({super.key});

  @override
  State<LaborerRoot> createState() => _LaborerRootState();
}

class _LaborerRootState extends State<LaborerRoot> {
  int _index = 0;

  static const _pages = [
    LaborerHomeScreen(),
    MyJobsScreen(),
    AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }
}

/// Bottom-navigation root for admins: Dashboard, Users, Jobs.
class AdminRoot extends StatefulWidget {
  const AdminRoot({super.key});

  @override
  State<AdminRoot> createState() => _AdminRootState();
}

class _AdminRootState extends State<AdminRoot> {
  int _index = 0;

  static const _pages = [
    AdminDashboardScreen(initialTab: 0),
    AdminDashboardScreen(initialTab: 1),
    AdminDashboardScreen(initialTab: 2),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Jobs'),
        ],
      ),
    );
  }
}
