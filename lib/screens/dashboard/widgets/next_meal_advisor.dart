import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../models/meal_slot.dart';
import '../../../providers/app_state_provider.dart';
import '../../meal_log/meal_logging_dialog.dart';
import '../../chat/ai_chat_screen.dart';

class NextMealAdvisor extends StatelessWidget {
  final int remainingKcal;
  final Map<MealSlot, int> slotCalories;

  const NextMealAdvisor({
    super.key,
    required this.remainingKcal,
    required this.slotCalories,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final meals = state.meals;

    // Determine the next upcoming meal slot
    MealSlot? nextSlot;
    if ((meals[MealSlot.breakfast] ?? []).isEmpty) {
      nextSlot = MealSlot.breakfast;
    } else if ((meals[MealSlot.lunch] ?? []).isEmpty) {
      nextSlot = MealSlot.lunch;
    } else if ((meals[MealSlot.snack] ?? []).isEmpty) {
      nextSlot = MealSlot.snack;
    } else if ((meals[MealSlot.dinner] ?? []).isEmpty) {
      nextSlot = MealSlot.dinner;
    }

    final suggestedItems = nextSlot != null ? (state.aiPlan.meals[nextSlot] ?? []) : [];
    final nextSlotBudget = nextSlot != null
        ? (state.aiPlan.slotBudgets[nextSlot] ?? (state.metrics.budget * nextSlot.targetShare).round())
        : 0;

    final foodsSummary = suggestedItems.isNotEmpty
        ? suggestedItems.map((e) => "${e.name} (${e.qty})").join(' • ')
        : 'স্বাস্থ্যকর ও হালকা দেশি খাবার গ্রহণ করুন।';

    // Real-time target analysis
    final isTotalOver = state.isOverBudget;
    final excess = state.excessKcal;
    final isGain = state.metrics.isWeightGain;

    MealSlot? overSlot;
    int overDiff = 0;
    for (final s in MealSlot.values) {
      final diff = state.slotDifference(s);
      if (diff > 30) {
        overSlot = s;
        overDiff = diff;
        break;
      }
    }

    String aiFeedbackMessage;
    if (isTotalOver) {
      aiFeedbackMessage = '⚠️ আজকের মোট ক্যালরি টার্গেট (${state.dailyBudget} kcal) পূর্ণ হয়ে +$excess kcal বেশি হয়েছে। এখন ভারী খাবার এড়িয়ে পানি ও শসা গ্রহণ করুন।';
    } else if (overSlot != null) {
      aiFeedbackMessage = '💡 ${overSlot.label}-এ টার্গেটের চেয়ে $overDiff kcal বেশি হয়েছে। পরবর্তী ${nextSlot != null ? nextSlot.label : 'বেলা'}-এ কিছুটা কম ক্যালরি খেয়ে ব্যালেন্স করুন।';
    } else if (isGain && remainingKcal > 300) {
      aiFeedbackMessage = '💪 ওজন বৃদ্ধির জন্য আজ এখনও $remainingKcal kcal পুষ্টিকর ক্যালরি গ্রহণ বাকি। পরবর্তী বেলাগুলোতে বাদাম, কলা বা দুধ যোগ করুন।';
    } else if (nextSlot != null) {
      aiFeedbackMessage = '🎯 আপনার খাওয়া খাবার সঠিক ক্যালরি টার্গেটের সাথে সামঞ্জস্যপূর্ণ রয়েছে।';
    } else {
      aiFeedbackMessage = '🎉 চমৎকার! আপনি আজকের ৪ বেলার খাবার সফলভাবে ট্র্যাক করেছেন এবং ক্যালরি ব্যালেন্স নিখুঁত রেখেছেন।';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isTotalOver
              ? const [Color(0xFFDC2626), Color(0xFFB91C1C)]
              : (overSlot != null
                  ? const [Color(0xFFD97706), Color(0xFFB45309)]
                  : const [Color(0xFF00A778), Color(0xFF047857)]),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: (isTotalOver
                    ? const Color(0xFFDC2626)
                    : (overSlot != null ? const Color(0xFFD97706) : const Color(0xFF00A778)))
                .withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    LucideIcons.sparkles,
                    color: Colors.white,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'AI MEAL ADVISOR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              if (nextSlot != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'পরবর্তী: ${nextSlot.label}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Real-time AI Status Callout
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isTotalOver
                      ? Icons.warning_rounded
                      : (overSlot != null ? Icons.info_outline : Icons.auto_awesome),
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    aiFeedbackMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
          if (nextSlot != null) ...[
            Text.rich(
              TextSpan(
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  height: 1.45,
                  fontWeight: FontWeight.w400,
                ),
                children: [
                  TextSpan(text: '${nextSlot.label}-এর আদর্শ AI বাজেট: '),
                  TextSpan(
                    text: '~$nextSlotBudget kcal',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const TextSpan(text: ' (দৈনিক অবশিষ্ট: '),
                  TextSpan(
                    text: '$remainingKcal kcal',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: ')\n'),
                  const TextSpan(
                    text: 'AI সুপারিশ: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: foodsSummary),
                ],
              ),
            ),
          ] else ...[
            const Text(
              '🎉 চমৎকার! আপনি আজকের ৪ বেলার খাবার সফলভাবে ট্র্যাক করেছেন। পর্যাপ্ত পানি পান করুন ও বিশ্রাম নিন।',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (nextSlot != null) ...[
                () {
                  final MealSlot targetSlot = nextSlot!;
                  return InkWell(
                    onTap: () async {
                      await state.addAiSuggestedMeal(targetSlot);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${targetSlot.label}-এ AI খাবারগুলো যুক্ত হয়েছে!'),
                            backgroundColor: const Color(0xFF10B981),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, size: 14, color: Color(0xFF00A778)),
                          SizedBox(width: 5),
                          Text(
                            'AI খাবার যোগ করুন',
                            style: TextStyle(
                              color: Color(0xFF00A778),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }(),
                // Custom log meal dialog
                () {
                  final MealSlot targetSlot = nextSlot!;
                  return InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => MealLoggingDialog(targetSlot: targetSlot),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                      ),
                      child: const Text(
                        'অন্য খাবার',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }(),
              ],
              // AI Chat button
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AiChatScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.bot, color: Colors.white, size: 14),
                      SizedBox(width: 5),
                      Text(
                        'AI পুষ্টিবিদ চ্যাট',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
