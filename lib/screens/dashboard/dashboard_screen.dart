import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../providers/app_state_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/meal_slot.dart';
import 'widgets/calorie_gauge.dart';
import 'widgets/macro_cards.dart';
import 'widgets/next_meal_advisor.dart';
import 'widgets/meal_slot_accordion.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final metrics = state.metrics;
    final budget = metrics.budget;
    final consumed = state.consumedKcal;
    final remaining = (budget - consumed).clamp(0, budget);
    final percent = (consumed / (budget > 0 ? budget : 1)).clamp(0.0, 1.0);

    final slotCalories = {
      for (var slot in MealSlot.values) slot: state.slotKcal(slot),
    };

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? AppColors.slate400 : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: isDark ? AppColors.slate900 : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await state.initBackendSync();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Greeting & Avatar Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good morning,',
                          style: TextStyle(
                            fontSize: 13,
                            color: textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          state.profile.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: textDark,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          state.profile.name.isNotEmpty
                              ? state.profile.name[0].toUpperCase()
                              : 'T',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Streak & Date Filter Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Streak Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFFEDD5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.flame,
                            size: 15,
                            color: Color(0xFFE17328),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${state.streakDays} days',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFC2410C),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Date Selector Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.slate800 : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? AppColors.slate700 : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chevron_left,
                            size: 16,
                            color: textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Today',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: textMuted,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Goal & Calorie Target Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: metrics.isWeightGain
                        ? (isDark ? const Color(0xFF0C2A44) : const Color(0xFFEFF6FF))
                        : (isDark ? const Color(0xFF063326) : const Color(0xFFECFDF5)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: metrics.isWeightGain
                          ? (isDark ? const Color(0xFF1E40AF) : const Color(0xFFBFDBFE))
                          : (isDark ? const Color(0xFF047857) : const Color(0xFFA7F3D0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: metrics.isWeightGain
                              ? const Color(0xFF2563EB).withValues(alpha: 0.15)
                              : const Color(0xFF10B981).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          metrics.isWeightGain ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                          size: 16,
                          color: metrics.isWeightGain ? const Color(0xFF2563EB) : const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              metrics.isWeightGain
                                  ? 'ওজন বৃদ্ধি লক্ষ্য (+${metrics.weightDifferenceKg.toStringAsFixed(1)} কেজি)'
                                  : (metrics.isWeightLoss
                                      ? 'ওজন কমানো লক্ষ্য (-${metrics.weightDifferenceKg.toStringAsFixed(1)} কেজি)'
                                      : 'ওজন বজায় রাখা'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: metrics.isWeightGain
                                    ? (isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF))
                                    : (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46)),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'দৈনিক ক্যালরি টার্গেট: ${metrics.budget} kcal (${metrics.isWeightGain ? "+${metrics.dailyAdjustmentKcal} kcal সারপ্লাস" : "${metrics.dailyAdjustmentKcal} kcal ডেফিসিট"})',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Main Calorie & Habit Gauge Card
                CalorieGauge(
                  consumed: consumed,
                  budget: budget,
                  remaining: remaining,
                  percent: percent,
                  isWeightGain: metrics.isWeightGain,
                  isWeightLoss: metrics.isWeightLoss,
                  dailyAdjustmentKcal: metrics.dailyAdjustmentKcal,
                  waterGlasses: state.waterGlasses,
                  waterGoalGlasses: metrics.waterGoalGlasses,
                  waterGoalLiters: metrics.waterGoalLiters,
                  walkMinutes: state.walkMinutes,
                  walkMinGoal: metrics.walkMinGoal,
                  onAddWater: state.incrementWater,
                  onRemoveWater: state.decrementWater,
                  onAddWalk: () => state.addWalkMinutes(5),
                ),

                const SizedBox(height: 14),

                // Macro split cards (Protein, Carbs, Fats)
                MacroCardsRow(
                  protein: state.consumedProtein.round(),
                  targetProtein: metrics.macros.protein,
                  carbs: state.consumedCarbs.round(),
                  targetCarbs: metrics.macros.carbs,
                  fat: state.consumedFat.round(),
                  targetFat: metrics.macros.fat,
                ),

                const SizedBox(height: 14),

                // AI Meal Advisor Card
                NextMealAdvisor(
                  remainingKcal: remaining,
                  slotCalories: slotCalories,
                ),

                const SizedBox(height: 20),

                // Section Header for Meals
                Text(
                  'Meals',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                    letterSpacing: -0.2,
                  ),
                ),

                const SizedBox(height: 12),

                // Meal Slot Sections
                ...MealSlot.values.map((slot) => MealSlotAccordion(slot: slot)),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
