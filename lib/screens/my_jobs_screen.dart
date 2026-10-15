import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/job.dart';
import '../providers/data_provider.dart';
import '../widgets/rating_stars.dart';
import '../widgets/status_chip.dart';

/// Jobs tabbed by status. Customers manage/review; laborers accept/decline.
class MyJobsScreen extends StatelessWidget {
  const MyJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Jobs'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'In Progress'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _JobList(status: 'pending'),
            _JobList(status: 'in_progress'),
            _JobList(status: 'completed'),
          ],
        ),
      ),
    );
  }
}

class _JobList extends StatelessWidget {
  final String status;

  const _JobList({required this.status});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final jobs = data.jobs.where((j) => j.status == status).toList()
      ..sort((a, b) => b.jobId.compareTo(a.jobId));
    if (jobs.isEmpty) {
      return const Center(child: Text('No jobs here'));
    }
    return RefreshIndicator(
      onRefresh: () => data.refreshAll(),
      child: ListView.builder(
        itemCount: jobs.length,
        itemBuilder: (context, i) => _JobTile(job: jobs[i]),
      ),
    );
  }
}

class _JobTile extends StatelessWidget {
  final Job job;

  const _JobTile({required this.job});

  String _otherParty(DataProvider data) {
    if (data.isCustomer) {
      final lid = job.laborId;
      if (lid == null) return 'Unassigned';
      for (final p in data.laborers) {
        if (p.laborId == lid) return data.laborerName(p);
      }
      return 'Laborer';
    }
    return data.userName(job.customerId);
  }

  @override
  Widget build(BuildContext context) {
    final data = context.read<DataProvider>();
    final isCustomer = data.isCustomer;
    final isLaborer = data.isLaborer;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(job.jobDescription,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                StatusChip(status: job.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${_otherParty(data)}'
              '${job.budget != null ? ' • Rs ${job.budget!.toStringAsFixed(0)}' : ''}',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (isCustomer &&
                    (job.status == 'pending' ||
                        job.status == 'in_progress'))
                  OutlinedButton(
                    onPressed: () => _setStatus(context, data, job.jobId,
                        'completed', 'Job marked completed'),
                    child: const Text('Mark Completed'),
                  ),
                if (isCustomer && job.status == 'completed')
                  FilledButton.tonal(
                    onPressed: () => _writeReview(context, data, job),
                    child: const Text('Write Review'),
                  ),
                if (isLaborer && job.status == 'pending') ...[
                  FilledButton(
                    onPressed: () => _setStatus(context, data, job.jobId,
                        'in_progress', 'Job accepted'),
                    child: const Text('Accept'),
                  ),
                  OutlinedButton(
                    onPressed: () => _confirmDecline(context, data, job.jobId),
                    child: const Text('Decline'),
                  ),
                ],
                if (isLaborer && job.status == 'in_progress')
                  OutlinedButton(
                    onPressed: () => _setStatus(context, data, job.jobId,
                        'completed', 'Job marked completed'),
                    child: const Text('Mark Completed'),
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

  Future<void> _writeReview(
      BuildContext context, DataProvider data, Job job) async {
    final laborId = job.laborId;
    if (laborId == null) return;
    double rating = 5;
    final commentCtrl = TextEditingController();
    String comment = '';
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Review ${_otherParty(data)}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RatingStars(
                rating: rating,
                size: 32,
                onChanged: (v) => setState(() => rating = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Comment',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () {
                  comment = commentCtrl.text.trim();
                  Navigator.of(context).pop(true);
                },
                child: const Text('Submit')),
          ],
        ),
      ),
    );
    commentCtrl.dispose();
    if (submitted == true && context.mounted) {
      final messenger = ScaffoldMessenger.of(context);
      try {
        await data.addReview(
          jobId: job.jobId,
          laborId: laborId,
          rating: rating.round(),
          comment: comment,
        );
        messenger.showSnackBar(
            const SnackBar(content: Text('Thanks for your review!')));
      } catch (e) {
        messenger.showSnackBar(SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    }
  }
}
