import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/data_provider.dart';
import '../widgets/app_page_route.dart';
import 'laborer_detail_screen.dart';

/// Customer's saved laborers, with remove (heart toggle).
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

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
      appBar: AppBar(title: const Text('Favorites')),
      body: data.favorites.isEmpty
          ? const Center(
              child: Text(
                  'No favorites yet.\nTap the heart on a laborer to save them.'),
            )
          : ListView.builder(
              itemCount: data.favorites.length,
              itemBuilder: (context, i) {
                final fav = data.favorites[i];
                final detail = data.detailCache[fav.laborId];
                final profile = detail?.profile;
                final name = profile == null
                    ? 'Laborer'
                    : data.laborerName(profile);
                final skills = data.skillNamesFor(fav.laborId);
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(_initials(name)),
                    ),
                    title: Text(name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      skills.isEmpty ? 'General labor' : skills.join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.red),
                      tooltip: 'Remove from favorites',
                      onPressed: () {
                        unawaited(context
                            .read<DataProvider>()
                            .toggleFavorite(fav.laborId));
                      },
                    ),
                    onTap: () {
                      Navigator.of(context).push(AppPageRoute(
                          builder: (_) =>
                              LaborerDetailScreen(laborId: fav.laborId)));
                    },
                  ),
                );
              },
            ),
    );
  }
}
