import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/laborer_detail.dart';
import '../models/review.dart';
import '../providers/data_provider.dart';
import '../widgets/app_page_route.dart';
import '../widgets/rating_stars.dart';
import '../widgets/section_title.dart';
import '../widgets/status_chip.dart';
import 'post_job_screen.dart';

/// Full laborer profile: info, skills, reviews, hire + favorite actions.
class LaborerDetailScreen extends StatefulWidget {
  final int laborId;

  const LaborerDetailScreen({super.key, required this.laborId});

  @override
  State<LaborerDetailScreen> createState() => _LaborerDetailScreenState();
}

class _LaborerDetailScreenState extends State<LaborerDetailScreen> {
  late final Future<LaborerDetail> _future;

  @override
  void initState() {
    super.initState();
    _future =
        context.read<DataProvider>().laborerDetailFuture(widget.laborId);
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final letters = parts.where((w) => w.isNotEmpty).map((w) => w[0]);
    return letters.take(2).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Laborer profile')),
      body: FutureBuilder<LaborerDetail>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || !snap.hasData) {
            return Center(
                child: Text('Could not load profile:\n${snap.error}',
                    textAlign: TextAlign.center));
          }
          final detail = snap.data!;
          final profile = detail.profile;
          final name = data.laborerName(profile);
          final fav = data.isFav(profile.laborId);
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        color: theme.colorScheme.primaryContainer,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Hero(
                              tag: 'laborer-avatar-${profile.laborId}',
                              child: CircleAvatar(
                                radius: 40,
                                backgroundColor: theme.colorScheme.primary,
                                child: Text(
                                  _initials(name),
                                  style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(name,
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                StatusChip(
                                    status: profile.availabilityStatus),
                                const SizedBox(width: 8),
                                RatingStars(rating: detail.avgRating),
                                const SizedBox(width: 4),
                                Text(
                                  detail.avgRating > 0
                                      ? '${detail.avgRating.toStringAsFixed(1)} (${detail.reviews.length})'
                                      : 'No ratings yet',
                                  style:
                                      const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              profile.wageLabel,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            if (profile.hourlyRate != null)
                              Text(
                                'Rs ${profile.hourlyRate!.toStringAsFixed(0)}/hour'
                                '${profile.experience != null ? ' • ${profile.experience} yrs experience' : ''}',
                                style: const TextStyle(fontSize: 13),
                              ),
                          ],
                        ),
                      ),
                      const SectionTitle('Skills'),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final s in detail.skills)
                              Chip(label: Text(s.skillName)),
                            if (detail.skills.isEmpty)
                              const Text('No skills listed yet'),
                          ],
                        ),
                      ),
                      if (profile.skills != null &&
                          profile.skills!.isNotEmpty) ...[
                        const SectionTitle('About'),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(profile.skills!),
                        ),
                      ],
                      const SectionTitle('Reviews'),
                      if (detail.reviews.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('No reviews yet.'),
                        )
                      else
                        for (final r in detail.reviews) _reviewTile(data, r),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(
                                  scale: animation, child: child),
                          child: Icon(
                            fav ? Icons.favorite : Icons.favorite_border,
                            key: ValueKey(fav),
                            color: fav ? Colors.red : null,
                            size: 30,
                          ),
                        ),
                        tooltip: fav
                            ? 'Remove from favorites'
                            : 'Save to favorites',
                        onPressed: () {
                          unawaited(context
                              .read<DataProvider>()
                              .toggleFavorite(profile.laborId));
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.work),
                          label: const Text('Hire Now'),
                          onPressed: profile.isAvailable
                              ? () {
                                  Navigator.of(context).push(
                                      AppPageRoute(
                                          builder: (_) => PostJobScreen(
                                              laborId: profile.laborId)));
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _reviewTile(DataProvider data, Review r) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Row(
          children: [
            RatingStars(rating: r.rating.toDouble(), size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(data.userName(r.customerId),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        subtitle: r.comment == null || r.comment!.isEmpty
            ? null
            : Text(r.comment!),
      ),
    );
  }
}
