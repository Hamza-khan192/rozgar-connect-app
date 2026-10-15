import 'package:flutter/material.dart';

/// Colored chip for job statuses and laborer availability.
class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    late final Color bg;
    late final Color fg;
    switch (s) {
      case 'pending':
        bg = Colors.orange.shade100;
        fg = Colors.orange.shade800;
      case 'in_progress':
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade800;
      case 'completed':
      case 'available':
        bg = Colors.green.shade100;
        fg = Colors.green.shade800;
      case 'busy':
        bg = Colors.red.shade100;
        fg = Colors.red.shade800;
      default:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade800;
    }
    return Chip(
      label: Text(
        s.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
      backgroundColor: bg,
      side: BorderSide.none,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}
