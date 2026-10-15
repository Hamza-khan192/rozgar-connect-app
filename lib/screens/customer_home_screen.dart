import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../providers/data_provider.dart';
import '../widgets/app_page_route.dart';
import '../widgets/laborer_card.dart';
import 'laborer_detail_screen.dart';
import 'post_job_screen.dart';

/// Customer landing: search + skill filter chips + laborer cards.
class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final _searchCtrl = TextEditingController();
  int? _selectedSkill;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilter() {
    context
        .read<DataProvider>()
        .searchLaborers(_searchCtrl.text, _selectedSkill);
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rozgar Connect'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Post a job',
            onPressed: () {
              Navigator.of(context).push(
                  AppPageRoute(builder: (_) => const PostJobScreen()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Search mason, electrician, plumber...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _applyFilter(),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('All'),
                    selected: _selectedSkill == null,
                    onSelected: (_) {
                      setState(() => _selectedSkill = null);
                      _applyFilter();
                    },
                  ),
                ),
                for (final skill in data.skills)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(skill.skillName),
                      selected: _selectedSkill == skill.skillId,
                      onSelected: (_) {
                        setState(() => _selectedSkill = skill.skillId);
                        _applyFilter();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: _buildList(data)),
        ],
      ),
    );
  }

  Widget _buildList(DataProvider data) {
    if (!data.laborersLoaded && data.lastError == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (data.lastError != null && data.laborers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Could not load laborers:\n${data.lastError}',
              textAlign: TextAlign.center),
        ),
      );
    }
    if (data.laborers.isEmpty) {
      return const Center(child: Text('No laborers found'));
    }
    return RefreshIndicator(
      onRefresh: () => data.refreshAll(),
      child: ListView.builder(
        itemCount: data.laborers.length,
        itemBuilder: (context, i) {
          final profile = data.laborers[i];
          final detail = data.detailCache[profile.laborId];
          final card = LaborerCard(
            name: data.laborerName(profile),
            skillNames: data.skillNamesFor(profile.laborId),
            avgRating: detail?.avgRating ?? 0,
            reviewCount: detail?.reviews.length ?? 0,
            dailyWage: profile.dailyWage,
            availability: profile.availabilityStatus,
            isFavorite: data.isFav(profile.laborId),
            onTap: () {
              Navigator.of(context).push(AppPageRoute(
                  builder: (_) =>
                      LaborerDetailScreen(laborId: profile.laborId)));
            },
            onFavoriteToggle: () {
              unawaited(
                  context.read<DataProvider>().toggleFavorite(profile.laborId));
            },
          );
          // Staggered entrance for the first items; plain afterwards
          // so scrolling stays smooth.
          if (i >= 10) return card;
          return card
              .animate(delay: Duration(milliseconds: 70 * i))
              .fadeIn(duration: 350.ms)
              .slideY(
                  begin: 0.12, end: 0, duration: 350.ms, curve: Curves.easeOut);
        },
      ),
    );
  }
}
