import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class MacroCardsRow extends StatelessWidget {
  final int protein;
  final int targetProtein;
  final int carbs;
  final int targetCarbs;
  final int fat;
  final int targetFat;

  const MacroCardsRow({
    super.key,
    required this.protein,
    required this.targetProtein,
    required this.carbs,
    required this.targetCarbs,
    required this.fat,
    required this.targetFat,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MacroItemCard(
            label: 'Protein',
            cur: protein,
            target: targetProtein,
            color: const Color(0xFF10B981), // Emerald
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MacroItemCard(
            label: 'Carbs',
            cur: carbs,
            target: targetCarbs,
            color: const Color(0xFF17A4E2), // Blue
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MacroItemCard(
            label: 'Fats',
            cur: fat,
            target: targetFat,
            color: const Color(0xFFE17328), // Orange
          ),
        ),
      ],
    );
  }
}

class _MacroItemCard extends StatelessWidget {
  final String label;
  final int cur;
  final int target;
  final Color color;

  const _MacroItemCard({
    required this.label,
    required this.cur,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.slate800 : Colors.white;
    final borderColor = isDark ? AppColors.slate700 : const Color(0xFFE2E8F0);
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? AppColors.slate400 : const Color(0xFF64748B);
    final trackBg = isDark ? AppColors.slate700 : const Color(0xFFF1F5F9);

    final pct = (cur / (target > 0 ? target : 1)).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$cur',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                  ),
                ),
                TextSpan(
                  text: '/${target}g',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.normal,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 4.5,
              backgroundColor: trackBg,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
