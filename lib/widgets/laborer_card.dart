import 'package:flutter/material.dart';

/// Card used on the customer home screen and favorites screen.
class LaborerCard extends StatelessWidget {
  final int laborId;
  final String name;
  final List<String> skillNames;
  final double avgRating;
  final int reviewCount;
  final double? dailyWage;
  final String availability;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const LaborerCard({
    super.key,
    required this.laborId,
    required this.name,
    required this.skillNames,
    required this.avgRating,
    this.reviewCount = 0,
    this.dailyWage,
    required this.availability,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    final letters = parts.where((w) => w.isNotEmpty).map((w) => w[0]);
    return letters.take(2).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final available = availability == 'available';
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Hero(
                tag: 'laborer-avatar-$laborId',
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    _initials,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: available ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          available ? 'Available' : 'Busy',
                          style: TextStyle(
                            fontSize: 12,
                            color: available
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      skillNames.isEmpty
                          ? 'General labor'
                          : skillNames.take(3).join(' • '),
                      style: TextStyle(
                          fontSize: 13, color: theme.colorScheme.secondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            size: 16, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          avgRating > 0
                              ? '${avgRating.toStringAsFixed(1)} ($reviewCount)'
                              : 'New',
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          dailyWage == null
                              ? 'Wage on request'
                              : 'Rs ${dailyWage!.toStringAsFixed(0)}/day',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : null,
                ),
                onPressed: onFavoriteToggle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
