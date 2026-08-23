import 'package:flutter/material.dart';

import '../theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late Color fg;
    switch (status) {
      case 'waiting':
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF075985);
      case 'called':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
      case 'serving':
        bg = const Color(0xFFD9F2EF);
        fg = AppTheme.accentDark;
      case 'completed':
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF047857);
      case 'Open':
        bg = const Color(0xFFD9F2EF);
        fg = AppTheme.accentDark;
      default:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: AppTheme.muted, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
