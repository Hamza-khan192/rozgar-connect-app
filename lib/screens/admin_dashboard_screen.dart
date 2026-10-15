import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../widgets/app_page_route.dart';
import '../widgets/status_chip.dart';
import 'login_screen.dart';

/// Admin dashboard: stat cards + tabs for Users and Jobs management.
class AdminDashboardScreen extends StatelessWidget {
  final int initialTab;

  const AdminDashboardScreen({super.key, this.initialTab = 0});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Kya aap logout karna chahte hain?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Nahi'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Haan, logout'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      AppPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () => _confirmLogout(context),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Users'),
              Tab(text: 'Jobs'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _OverviewTab(),
            _UsersTab(),
            _JobsTab(),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final pending = data.jobs.where((j) => j.status == 'pending').length;
    return RefreshIndicator(
      onRefresh: () => data.refreshAll(),
      child: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          _StatCard(
              title: 'Users',
              value: '${data.usersById.length}',
              icon: Icons.people,
              color: Colors.blue),
          _StatCard(
              title: 'Laborers',
              value: '${data.laborers.length}',
              icon: Icons.handyman,
              color: Colors.teal),
          _StatCard(
              title: 'Jobs',
              value: '${data.jobs.length}',
              icon: Icons.work,
              color: Colors.orange),
          _StatCard(
              title: 'Pending Jobs',
              value: '$pending',
              icon: Icons.pending_actions,
              color: Colors.red),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(value,
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _UsersTab extends StatelessWidget {
  const _UsersTab();

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final letters = parts.where((w) => w.isNotEmpty).map((w) => w[0]);
    return letters.take(2).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final users = data.usersById.values.toList()
      ..sort((a, b) => a.userId.compareTo(b.userId));
    final selfId = data.currentUser?.userId;
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, i) {
        final user = users[i];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(child: Text(_initials(user.name))),
            title: Text(user.name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${user.phone} • ${user.roleLabel}'),
            trailing: user.userId == selfId
                ? const Chip(label: Text('You'))
                : IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Delete user',
                    onPressed: () =>
                        _confirmDelete(context, data, user.userId, user.name),
                  ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, DataProvider data,
      int userId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete user?'),
        content: Text(
            'Delete "$name" and all their data? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final messenger = ScaffoldMessenger.of(context);
      try {
        await data.deleteUser(userId);
        messenger
            .showSnackBar(const SnackBar(content: Text('User deleted')));
      } catch (e) {
        messenger.showSnackBar(SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    }
  }
}

class _JobsTab extends StatelessWidget {
  const _JobsTab();

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final jobs = data.jobs.toList()
      ..sort((a, b) => b.jobId.compareTo(a.jobId));
    if (jobs.isEmpty) {
      return const Center(child: Text('No jobs yet'));
    }
    return ListView.builder(
      itemCount: jobs.length,
      itemBuilder: (context, i) {
        final job = jobs[i];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            title: Text(job.jobDescription,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              '${data.userName(job.customerId)}'
              '${job.budget != null ? ' • Rs ${job.budget!.toStringAsFixed(0)}' : ''}',
            ),
            trailing: StatusChip(status: job.status),
          ),
        );
      },
    );
  }
}
