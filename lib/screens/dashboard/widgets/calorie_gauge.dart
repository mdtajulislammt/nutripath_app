import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';

class CalorieGauge extends StatelessWidget {
  final int consumed;
  final int budget;
  final int remaining;
  final double percent;
  final bool isWeightGain;
  final bool isWeightLoss;
  final int dailyAdjustmentKcal;
  final int waterGlasses;
  final int waterGoalGlasses;
  final double waterGoalLiters;
  final int walkMinutes;
  final int walkMinGoal;
  final VoidCallback onAddWater;
  final VoidCallback onRemoveWater;
  final VoidCallback onAddWalk;

  const CalorieGauge({
    super.key,
    required this.consumed,
    required this.budget,
    required this.remaining,
    required this.percent,
    this.isWeightGain = false,
    this.isWeightLoss = false,
    this.dailyAdjustmentKcal = 0,
    required this.waterGlasses,
    this.waterGoalGlasses = 12,
    this.waterGoalLiters = 3.0,
    required this.walkMinutes,
    required this.walkMinGoal,
    required this.onAddWater,
    required this.onRemoveWater,
    required this.onAddWalk,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.slate800 : Colors.white;
    final innerTileBg = isDark ? AppColors.slate700 : const Color(0xFFF8FAFC);
    final borderColor = isDark ? AppColors.slate700 : const Color(0xFFE2E8F0);
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? AppColors.slate400 : const Color(0xFF64748B);

    final bool isOverBudget = consumed > budget;
    final int diffKcal = (consumed - budget).abs();

    final int totalWaterDots = waterGoalGlasses > 0 ? waterGoalGlasses : 12;
    final currentWaterLiters = (waterGlasses * 0.25).toStringAsFixed(2);
    final targetLiters = waterGoalLiters > 0 ? waterGoalLiters.toStringAsFixed(2) : (totalWaterDots * 0.25).toStringAsFixed(2);
    final walkProgress = (walkMinutes / (walkMinGoal > 0 ? walkMinGoal : 40)).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isOverBudget ? const Color(0xFFFCA5A5) : borderColor,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Column(
        children: [
          // Circular Progress Arc
          CircularPercentIndicator(
            radius: 80.0,
            lineWidth: 15.0,
            animation: true,
            percent: percent.clamp(0.0, 1.0),
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: isOverBudget
                ? const Color(0xFFEF4444)
                : const Color(0xFF10B981),
            backgroundColor: isDark ? AppColors.slate700 : const Color(0xFFF0F5F9),
            startAngle: 0.0,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isOverBudget ? '+$diffKcal' : '$remaining',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: isOverBudget ? const Color(0xFFEF4444) : textDark,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  isOverBudget ? 'kcal অতিরিক্ত' : 'kcal বাকি',
                  style: TextStyle(
                    color: isOverBudget ? const Color(0xFFEF4444) : textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Real-time Goal & Target Status Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isOverBudget
                  ? (isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2))
                  : (isWeightGain && consumed < budget
                      ? (isDark ? const Color(0xFF451A03) : const Color(0xFFFFFBEB))
                      : (isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5))),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isOverBudget
                    ? const Color(0xFFFCA5A5)
                    : (isWeightGain && consumed < budget
                        ? const Color(0xFFFDE68A)
                        : const Color(0xFFA7F3D0)),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isOverBudget
                      ? Icons.warning_amber_rounded
                      : (isWeightGain && consumed < budget
                          ? Icons.info_outline
                          : Icons.check_circle_outline),
                  size: 15,
                  color: isOverBudget
                      ? const Color(0xFFDC2626)
                      : (isWeightGain && consumed < budget
                          ? const Color(0xFFD97706)
                          : const Color(0xFF059669)),
                ),
                const SizedBox(width: 6),
                Text(
                  isOverBudget
                      ? 'টার্গেটের চেয়ে $diffKcal kcal বেশি হয়েছে'
                      : (isWeightGain
                          ? (consumed >= budget
                              ? 'সারপ্লাস লক্ষ্য অর্জিত! (+$diffKcal kcal)'
                              : 'ওজন বৃদ্ধিতে আরও $remaining kcal বাকি')
                          : 'টার্গেটের মধ্যে আছেন ($remaining kcal বাকি)'),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isOverBudget
                        ? const Color(0xFFDC2626)
                        : (isWeightGain && consumed < budget
                            ? const Color(0xFFD97706)
                            : const Color(0xFF059669)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Two Stat Boxes: Consumed vs Target
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  decoration: BoxDecoration(
                    color: innerTileBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Consumed',
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$consumed',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: textDark,
                              ),
                            ),
                            TextSpan(
                              text: ' kcal',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.normal,
                                color: textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isOverBudget
                            ? '⚠️ অতিরিক্ত'
                            : (consumed == 0 ? 'শুরু করুন' : 'নিরাপদ সীমায়'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isOverBudget ? const Color(0xFFDC2626) : const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  decoration: BoxDecoration(
                    color: innerTileBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Target',
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: _formatThousands(budget),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: textDark,
                              ),
                            ),
                            TextSpan(
                              text: ' kcal',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.normal,
                                color: textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isWeightGain
                            ? '+$dailyAdjustmentKcal kcal সারপ্লাস'
                            : (isWeightLoss
                                ? '-${dailyAdjustmentKcal.abs()} kcal ডেফিসিট'
                                : 'রক্ষণাবেক্ষণ'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isWeightGain ? const Color(0xFF0284C7) : const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Water Tracker Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: innerTileBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.droplets,
                          size: 15,
                          color: Color(0xFF17A4E2),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Water',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textDark,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$currentWaterLiters / $targetLiters L ($waterGlasses/$totalWaterDots gls)',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Minus button
                    InkWell(
                      onTap: onRemoveWater,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.slate800 : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: borderColor),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.remove,
                            size: 14,
                            color: textDark,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Dot progress indicator for dynamic glasses
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(totalWaterDots, (index) {
                          final isFilled = index < waterGlasses;
                          return Container(
                            width: (180 / totalWaterDots).clamp(5.0, 11.0),
                            height: 12,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4.5),
                              color: isFilled
                                  ? const Color(0xFF17A4E2)
                                  : (isDark ? AppColors.slate600 : const Color(0xFFE2E8F0)),
                            ),
                          );
                        }),
                      ),
                    ),

                    const SizedBox(width: 8),
                    // Plus button
                    InkWell(
                      onTap: onAddWater,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.slate800 : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: borderColor),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.add,
                            size: 14,
                            color: textDark,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Brisk Walk & Exercise Tracker Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: innerTileBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.footprints,
                          size: 15,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Brisk walk & Exercise',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textDark,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          '$walkMinutes/$walkMinGoal min',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: onAddWalk,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.slate800 : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: borderColor),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.add,
                                size: 14,
                                color: textDark,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: walkProgress,
                    minHeight: 6,
                    backgroundColor: isDark ? AppColors.slate600 : const Color(0xFFCCFBF1),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatThousands(int number) {
    if (number >= 1000) {
      final whole = number ~/ 1000;
      final rem = number % 1000;
      return '$whole,${rem.toString().padLeft(3, '0')}';
    }
    return number.toString();
  }
}
