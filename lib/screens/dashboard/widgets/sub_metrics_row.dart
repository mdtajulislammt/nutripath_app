import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';

class SubMetricsRow extends StatelessWidget {
  final int waterGlasses;
  final int walkMinutes;
  final int walkMinGoal;
  final VoidCallback onAddWater;
  final VoidCallback onRemoveWater;
  final Function(int) onAddWalkMinutes;

  const SubMetricsRow({
    super.key,
    required this.waterGlasses,
    required this.walkMinutes,
    required this.walkMinGoal,
    required this.onAddWater,
    required this.onRemoveWater,
    required this.onAddWalkMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final waterLiters = (waterGlasses * 0.45).toStringAsFixed(1);
    final isWalkGoalReached = walkMinutes >= walkMinGoal;

    return Row(
      children: [
        Expanded(
          child: _MiniHabitCard(
            icon: LucideIcons.droplets,
            iconColor: AppColors.water,
            title: 'Water Intake',
            value: '$waterLiters L / 3.6 L',
            subtext: '$waterGlasses glasses',
            onPlus: onAddWater,
            onMinus: onRemoveWater,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniHabitCard(
            icon: LucideIcons.footprints,
            iconColor: AppColors.walk,
            title: 'Brisk Walk',
            value: '$walkMinutes / $walkMinGoal min',
            subtext: isWalkGoalReached ? 'Goal Reached! 🎉' : 'Keep moving 🚶‍♂️',
            onPlus: () => onAddWalkMinutes(10),
            onMinus: () => onAddWalkMinutes(-10),
          ),
        ),
      ],
    );
  }
}

class _MiniHabitCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtext;
  final VoidCallback onPlus;
  final VoidCallback onMinus;

  const _MiniHabitCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtext,
    required this.onPlus,
    required this.onMinus,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(subtext, style: const TextStyle(fontSize: 11, color: AppColors.slate500)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: onMinus,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.slate300),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.remove, size: 16, color: AppColors.slate600),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: onPlus,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.emeraldPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
