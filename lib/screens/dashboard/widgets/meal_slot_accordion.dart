import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../models/meal_slot.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/app_state_provider.dart';
import '../../meal_log/meal_logging_dialog.dart';

class MealSlotAccordion extends StatefulWidget {
  final MealSlot slot;

  const MealSlotAccordion({super.key, required this.slot});

  @override
  State<MealSlotAccordion> createState() => _MealSlotAccordionState();
}

class _MealSlotAccordionState extends State<MealSlotAccordion> {
  bool _showSuggestedMenu = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final items = state.meals[widget.slot] ?? [];
    final currentKcal = state.slotKcal(widget.slot);
    final slotTarget = state.slotBudget(widget.slot);
    final diff = currentKcal - slotTarget;
    final isOver = diff > 30;
    final isUnder = items.isNotEmpty && diff < -30;
    final isExact = items.isNotEmpty && diff.abs() <= 30;
    final isEmpty = items.isEmpty;

    final suggestedItems = state.aiPlan.meals[widget.slot] ?? [];
    final suggestedKcal = suggestedItems.fold<int>(0, (sum, i) => sum + i.kcal);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.slate800 : Colors.white;
    final borderColor = isDark ? AppColors.slate700 : const Color(0xFFE2E8F0);
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? AppColors.slate400 : const Color(0xFF64748B);
    final suggestionBg = isDark ? const Color(0xFF063326) : const Color(0xFFF0FDF4);
    final suggestionBorder = isDark ? const Color(0xFF047857) : const Color(0xFFBBF7D0);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOver ? const Color(0xFFFCA5A5) : borderColor,
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      LucideIcons.utensils,
                      size: 15,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.slot.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: textDark,
                    ),
                  ),
                ],
              ),
              // Target Comparison Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isEmpty
                      ? (isDark ? AppColors.slate700 : const Color(0xFFF1F5F9))
                      : (isOver
                          ? (isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2))
                          : (isUnder
                              ? (isDark ? const Color(0xFF451A03) : const Color(0xFFFFFBEB))
                              : (isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5)))),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isEmpty
                        ? Colors.transparent
                        : (isOver
                            ? const Color(0xFFFCA5A5)
                            : (isUnder ? const Color(0xFFFDE68A) : const Color(0xFFA7F3D0))),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isOver) ...[
                      const Icon(Icons.arrow_upward, size: 12, color: Color(0xFFDC2626)),
                      const SizedBox(width: 3),
                      Text(
                        '+$diff kcal বেশি',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ] else if (isUnder) ...[
                      const Icon(Icons.arrow_downward, size: 12, color: Color(0xFFD97706)),
                      const SizedBox(width: 3),
                      Text(
                        '${diff.abs()} kcal বাকি',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ] else if (isExact) ...[
                      const Icon(Icons.check, size: 12, color: Color(0xFF059669)),
                      const SizedBox(width: 3),
                      const Text(
                        'টার্গেট পূরণ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ] else ...[
                      Text(
                        'বাজেট: $slotTarget kcal',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Real-time slot progress bar and note
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isEmpty
                    ? 'AI প্রস্তাবিত বাজেট: $slotTarget kcal'
                    : (isOver
                        ? 'টার্গেটের চেয়ে $diff kcal বেশি খেয়েছেন'
                        : (isUnder
                            ? 'টার্গেটের চেয়ে ${diff.abs()} kcal কম (বাকি)'
                            : 'টার্গেটের সাথে নিখুঁত মিল')),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isEmpty
                      ? textMuted
                      : (isOver
                          ? const Color(0xFFDC2626)
                          : (isUnder
                              ? const Color(0xFFD97706)
                              : const Color(0xFF059669))),
                ),
              ),
              Text(
                '$currentKcal / $slotTarget kcal',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: isEmpty
                  ? 0.0
                  : (currentKcal / (slotTarget > 0 ? slotTarget : 1)).clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: isDark ? AppColors.slate700 : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                isOver
                    ? const Color(0xFFEF4444)
                    : (isExact
                        ? const Color(0xFF10B981)
                        : (isUnder ? const Color(0xFFF59E0B) : const Color(0xFF10B981))),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Logged Food Items List (if any)
          if (items.isNotEmpty) ...[
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 1.5),
                          Text(
                            item.qty,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${item.kcal} kcal',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => state.removeMealItem(widget.slot, item.id),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          LucideIcons.trash2,
                          size: 15,
                          color: isDark ? AppColors.slate400 : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // AI Meal Suggestion Box ("ar ki ki khete hobe ta meals e suggestion dibe")
          if (suggestedItems.isNotEmpty) ...[
            if (items.isEmpty) ...[
              // Prominent AI Recommendation Card when meal slot is not yet logged
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: suggestionBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: suggestionBorder, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.sparkles, size: 14, color: Color(0xFF10B981)),
                        const SizedBox(width: 6),
                        Text(
                          'AI এর প্রস্তাবিত খাবার ($suggestedKcal kcal):',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.emeraldLight : const Color(0xFF047857),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...suggestedItems.map((sug) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.5),
                          child: Row(
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "${sug.name} (${sug.qty})",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.slate200 : const Color(0xFF1E293B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                "${sug.kcal} kcal",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 10),
                    // 1-Tap Add All AI Suggested Items
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await state.addAiSuggestedMeal(widget.slot);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${widget.slot.label}-এ AI খাবারগুলো যুক্ত হয়েছে!'),
                                backgroundColor: const Color(0xFF10B981),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.auto_awesome, size: 14),
                        label: const Text(
                          'AI খাবারগুলো সরাসরি যোগ করুন',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ] else ...[
              // Collapsible AI Suggestion preview when slot already has foods logged
              InkWell(
                onTap: () => setState(() => _showSuggestedMenu = !_showSuggestedMenu),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.sparkles, size: 13, color: Color(0xFF10B981)),
                      const SizedBox(width: 6),
                      Text(
                        _showSuggestedMenu ? 'AI খাবার তালিকা লুকান' : 'AI এর প্রস্তাবিত মেনু দেখুন',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _showSuggestedMenu ? Icons.expand_less : Icons.expand_more,
                        size: 14,
                        color: const Color(0xFF10B981),
                      ),
                    ],
                  ),
                ),
              ),
              if (_showSuggestedMenu) ...[
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: suggestionBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: suggestionBorder, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...suggestedItems.map((sug) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              "• ${sug.name} (${sug.qty}) - ${sug.kcal} kcal",
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? AppColors.slate200 : const Color(0xFF334155),
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ],

          // "+ Log Meal / কাস্টম খাবার যোগ করুন" Button
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => MealLoggingDialog(targetSlot: widget.slot),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate700 : const Color(0xFFFBFDFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor,
                  width: 1,
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add,
                      size: 15,
                      color: textDark,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      items.isEmpty ? 'অন্য যেকোনো খাবার খুঁজুন (Log Custom)' : 'আরও খাবার যোগ করুন',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
