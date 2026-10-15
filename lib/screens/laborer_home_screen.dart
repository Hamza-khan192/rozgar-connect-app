import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/job.dart';
import '../providers/data_provider.dart';
import '../widgets/section_title.dart';
import '../widgets/status_chip.dart';

/// Laborer dashboard: profile card, edit profile, update location,
/// incoming job requests.
class LaborerHomeScreen extends StatelessWidget {
  const LaborerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final profile = data.myProfile;
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => data.refreshAll(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _profileCard(context, data),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit Profile'),
                              onPressed: () =>
                                  _showEditDialog(context, data),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              icon: const Icon(Icons.my_location),
                              label: const Text('Update Location'),
                              onPressed: () =>
                                  _updateLocation(context, data),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SectionTitle('Incoming Requests'),
                    _requestsSection(context, data),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _profileCard(BuildContext context, DataProvider data) {
    final user = data.currentUser;
    final profile = data.myProfile!;
    final theme = Theme.of(context);
    final location = data.myLocation;
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(Icons.handyman,
                      size: 30,
                      color: theme.colorScheme.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? 'Laborer',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(user?.phone ?? '',
                          style: const TextStyle(
                              fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ),
                StatusChip(status: profile.availabilityStatus),
              ],
            ),
            const Divider(height: 24),
            _infoRow('Daily wage',
                profile.dailyWage == null ? 'Not set' : 'Rs ${profile.dailyWage!.toStringAsFixed(0)}'),
            _infoRow('Hourly rate',
                profile.hourlyRate == null ? 'Not set' : 'Rs ${profile.hourlyRate!.toStringAsFixed(0)}'),
            _infoRow('Experience',
                profile.experience == null ? 'Not set' : '${profile.experience} years'),
            _infoRow('Location',
                location == null ? 'Not set' : location.coordsLabel),
            const SizedBox(height: 8),
            const Text('Skills',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final name in data.mySkillNames())
                  Chip(label: Text(name)),
                if (data.mySkillNames().isEmpty)
                  const Text('No skills selected yet',
                      style: TextStyle(color: Colors.grey)),
              ],
            ),
            if (profile.skills != null && profile.skills!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(profile.skills!,
                  style: const TextStyle(color: Colors.grey)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
              width: 110,
              child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _requestsSection(BuildContext context, DataProvider data) {
    final pending =
        data.jobs.where((j) => j.status == 'pending').toList()
          ..sort((a, b) => b.jobId.compareTo(a.jobId));
    if (pending.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text('No new requests right now.',
            style: TextStyle(color: Colors.grey)),
      );
    }
    return Column(
      children: [for (final job in pending) _requestTile(context, data, job)],
    );
  }

  Widget _requestTile(BuildContext context, DataProvider data, Job job) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(job.jobDescription,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              '${data.userName(job.customerId)}'
              '${job.budget != null ? ' • Rs ${job.budget!.toStringAsFixed(0)}' : ''}',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => _setStatus(context, data, job.jobId,
                        'in_progress', 'Job accepted'),
                    child: const Text('Accept'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        _confirmDecline(context, data, job.jobId),
                    child: const Text('Decline'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setStatus(BuildContext context, DataProvider data, int jobId,
      String status, String doneMessage) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await data.updateJobStatus(jobId, status);
      messenger.showSnackBar(SnackBar(content: Text(doneMessage)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> _confirmDecline(
      BuildContext context, DataProvider data, int jobId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline job?'),
        content: const Text('This will remove the job request.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Decline')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final messenger = ScaffoldMessenger.of(context);
      try {
        await data.deleteJob(jobId);
        messenger
            .showSnackBar(const SnackBar(content: Text('Job declined')));
      } catch (e) {
        messenger.showSnackBar(SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    }
  }

  Future<void> _updateLocation(BuildContext context, DataProvider data) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      // Demo coordinates near Mardan with a tiny random offset.
      final rand = Random();
      final lat = 34.2019 + (rand.nextDouble() - 0.5) * 0.02;
      final lng = 72.0525 + (rand.nextDouble() - 0.5) * 0.02;
      await data.updateLocation(latitude: lat, longitude: lng);
      messenger.showSnackBar(SnackBar(
          content: Text(
              'Location saved: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> _showEditDialog(BuildContext context, DataProvider data) async {
    final profile = data.myProfile;
    if (profile == null) return;
    final dailyCtrl =
        TextEditingController(text: profile.dailyWage?.toStringAsFixed(0) ?? '');
    final hourlyCtrl = TextEditingController(
        text: profile.hourlyRate?.toStringAsFixed(0) ?? '');
    final expCtrl =
        TextEditingController(text: profile.experience?.toString() ?? '');
    final aboutCtrl = TextEditingController(text: profile.skills ?? '');
    bool available = profile.isAvailable;
    final selected = data.mySkillIds.toSet();
    final messenger = ScaffoldMessenger.of(context);

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: dailyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Daily wage (Rs)',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: hourlyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Hourly rate (Rs)',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: expCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Experience (years)',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: aboutCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'About (short description)',
                      border: OutlineInputBorder()),
                ),
                SwitchListTile(
                  title: const Text('Available for work'),
                  value: available,
                  onChanged: (v) => setState(() => available = v),
                ),
                const Text('Skills',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final s in data.skills)
                      FilterChip(
                        label: Text(s.skillName),
                        selected: selected.contains(s.skillId),
                        onSelected: (v) => setState(() {
                          if (v) {
                            selected.add(s.skillId);
                          } else {
                            selected.remove(s.skillId);
                          }
                        }),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Save')),
          ],
        ),
      ),
    );

    final about = aboutCtrl.text.trim();
    final daily = double.tryParse(dailyCtrl.text.trim());
    final hourly = double.tryParse(hourlyCtrl.text.trim());
    final exp = int.tryParse(expCtrl.text.trim());
    dailyCtrl.dispose();
    hourlyCtrl.dispose();
    expCtrl.dispose();
    aboutCtrl.dispose();

    if (saved == true && context.mounted) {
      try {
        await data.updateProfile(
          dailyWage: daily,
          hourlyRate: hourly,
          experience: exp,
          availability: available ? 'available' : 'busy',
          skillIds: selected.toList(),
          about: about.isEmpty ? null : about,
        );
        messenger.showSnackBar(
            const SnackBar(content: Text('Profile updated')));
      } catch (e) {
        messenger.showSnackBar(SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    }
  }
}
