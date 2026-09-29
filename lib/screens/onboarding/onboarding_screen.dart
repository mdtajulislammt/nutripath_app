import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../providers/app_state_provider.dart';
import '../../models/user_profile.dart';
import '../../models/meal_slot.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/bmr_calculator.dart';
import '../../services/ai_diet_plan_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  bool _isGenerating = false;
  final UserProfile _temp = UserProfile();

  final List<String> conditionsList = [
    'Diabetes',
    'High BP',
    'Thyroid',
    'Fatty Liver',
    'Gastric / Acidity',
    'None',
  ];

  @override
  void initState() {
    super.initState();
    final currentProfile = context.read<AppStateProvider>().profile;
    _temp.name = currentProfile.name.isNotEmpty ? currentProfile.name : 'NutriPath User';
    _temp.age = currentProfile.age;
    _temp.gender = currentProfile.gender;
    _temp.weight = currentProfile.weight;
    _temp.heightCm = currentProfile.heightCm;
    _temp.targetWeight = currentProfile.targetWeight;
    _temp.months = currentProfile.months;
    _temp.activity = currentProfile.activity;
    _temp.conditions = List.from(currentProfile.conditions);
    _temp.kcalOverride = null; // Ensure dynamic AI calculation based on user data
    _temp.isGoogleLinked = currentProfile.isGoogleLinked;
    _temp.googleEmail = currentProfile.googleEmail;
    _temp.googleDisplayName = currentProfile.googleDisplayName;
    _temp.googlePhotoUrl = currentProfile.googlePhotoUrl;
  }

  Future<void> _finishOnboarding() async {
    setState(() => _isGenerating = true);
    try {
      _temp.kcalOverride = null;
      final state = context.read<AppStateProvider>();
      await state.completeOnboardingWithAiPlan(_temp);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'আপনার AI ডায়েট প্ল্যান তৈরি হয়েছে এবং খাবারগুলো আজকের রুটিনে যুক্ত হয়েছে!',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      debugPrint('Error finishing onboarding: $e');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "প্রোফাইল ও ডায়েট সেটআপ (${_step + 1}/4)",
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_step + 1) / 4,
                  backgroundColor: isDark ? AppColors.slate700 : AppColors.slate200,
                  color: const Color(0xFF10B981),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: switch (_step) {
                  0 => _buildStepBio(),
                  1 => _buildStepConditions(),
                  2 => _buildStepGoals(),
                  _ => _buildStepActivityAndResult(),
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_step > 0 && !_isGenerating)
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _step--),
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text("পিছনে (Back)"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    onPressed: _isGenerating
                        ? null
                        : () {
                            if (_step < 3) {
                              setState(() => _step++);
                            } else {
                              _finishOnboarding();
                            }
                          },
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Icon(
                            _step == 3 ? Icons.check_circle_outline : Icons.arrow_forward,
                            size: 18,
                          ),
                    label: Text(
                      _isGenerating
                          ? "AI ডায়েট এন্ট্রি হচ্ছে..."
                          : _step == 3
                              ? "AI প্ল্যান নিয়ে শুরু করুন"
                              : "পরবর্তী (Next)",
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepBio() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.emeraldLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.user, color: AppColors.emeraldDark),
              ),
              const SizedBox(width: 12),
              const Text("আপনার শারীরিক তথ্য", style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "আপনার সঠিক BMR এবং দৈনিক ক্যালোরি চাহিদার হিসাব করার জন্য এই তথ্য প্রয়োজন।",
            style: TextStyle(color: AppColors.slate500, fontSize: 12.5),
          ),
          const SizedBox(height: 20),
          TextFormField(
            initialValue: _temp.name,
            decoration: const InputDecoration(
              labelText: "আপনার নাম (Full Name)",
              prefixIcon: Icon(Icons.person_outline, size: 20),
            ),
            onChanged: (v) => _temp.name = v.trim(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _temp.age.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "বয়স (Age)",
                    suffixText: "বছর",
                  ),
                  onChanged: (v) => _temp.age = int.tryParse(v) ?? 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: DropdownButtonFormField<Gender>(
                  initialValue: _temp.gender,
                  decoration: const InputDecoration(labelText: "লিঙ্গ (Gender)"),
                  items: const [
                    DropdownMenuItem(value: Gender.male, child: Text("পুরুষ (Male)")),
                    DropdownMenuItem(value: Gender.female, child: Text("নারী (Female)")),
                  ],
                  onChanged: (v) => setState(() => _temp.gender = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _temp.weight.toString(),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: "বর্তমান ওজন (Weight)",
                    suffixText: "কেজি",
                  ),
                  onChanged: (v) => _temp.weight = double.tryParse(v) ?? 110,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextFormField(
                  initialValue: _temp.heightCm.toString(),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: "উচ্চতা (Height)",
                    suffixText: "সেমি (cm)",
                  ),
                  onChanged: (v) => _temp.heightCm = double.tryParse(v) ?? 175,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepConditions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.emeraldLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.heartHandshake, color: AppColors.emeraldDark),
            ),
            const SizedBox(width: 12),
            const Text("স্বাস্থ্য ও রোগ প্রতিরোধ তালিকা", style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          "আপনার কোনো রোগ থাকলে AI সে অনুযায়ী খাবারে শর্করা, সোডিয়াম বা মসলা সমন্বয় করবে।",
          style: TextStyle(color: AppColors.slate500, fontSize: 12.5),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: conditionsList.map((cond) {
            final isSelected = _temp.conditions.contains(cond);
            return FilterChip(
              label: Text(cond),
              selected: isSelected,
              selectedColor: AppColors.emeraldLight,
              checkmarkColor: AppColors.emeraldDark,
              backgroundColor: isDark ? AppColors.slate800 : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF10B981) : (isDark ? AppColors.slate700 : AppColors.slate300),
                ),
              ),
              onSelected: (val) {
                setState(() {
                  if (cond == 'None') {
                    _temp.conditions = ['None'];
                  } else {
                    _temp.conditions.remove('None');
                    if (val) {
                      _temp.conditions.add(cond);
                    } else {
                      _temp.conditions.remove(cond);
                    }
                    if (_temp.conditions.isEmpty) {
                      _temp.conditions = ['None'];
                    }
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStepGoals() {
    final diffKg = (_temp.targetWeight - _temp.weight).abs();
    final isGain = _temp.targetWeight > _temp.weight + 0.5;
    final isLoss = _temp.targetWeight < _temp.weight - 0.5;

    final goalText = isGain
        ? "টার্গেট বৃদ্ধি (Weight Gain): +${diffKg.toStringAsFixed(1)} কেজি (প্রতি মাসে প্রায় +${(diffKg / _temp.months).toStringAsFixed(1)} কেজি সুস্থ গতিতে)।"
        : (isLoss
            ? "টার্গেট কমানো (Weight Loss): -${diffKg.toStringAsFixed(1)} কেজি (প্রতি মাসে প্রায় -${(diffKg / _temp.months).toStringAsFixed(1)} কেজি সুস্থ গতিতে)।"
            : "বর্তমান ওজন বজায় রাখা (Maintenance): ${_temp.weight.toStringAsFixed(1)} কেজি।");

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.emeraldLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.target, color: AppColors.emeraldDark),
              ),
              const SizedBox(width: 12),
              const Text("টার্গেট ওজন ও সময়সীমা", style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "আপনার কাঙ্ক্ষিত লক্ষ্য অনুযায়ী ওজন কমানো বা বাড়ানোর টার্গেট নির্ধারণ করুন।",
            style: TextStyle(color: AppColors.slate500, fontSize: 12.5),
          ),
          const SizedBox(height: 20),
          TextFormField(
            initialValue: _temp.targetWeight.toString(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: "টার্গেট ওজন (Target Weight)",
              suffixText: "কেজি",
              prefixIcon: Icon(Icons.fitness_center_outlined, size: 20),
            ),
            onChanged: (v) {
              setState(() {
                _temp.targetWeight = double.tryParse(v) ?? 100;
              });
            },
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("সময়সীমা (Timeline):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(
                "${_temp.months} মাস (${_temp.months * 30} দিন)",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981), fontSize: 15),
              ),
            ],
          ),
          Slider(
            value: _temp.months.toDouble(),
            min: 1,
            max: 12,
            divisions: 11,
            activeColor: const Color(0xFF10B981),
            label: "${_temp.months} Months",
            onChanged: (val) => setState(() => _temp.months = val.toInt()),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.emeraldLight.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    goalText,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepActivityAndResult() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final res = calculateMetrics(_temp);
    final aiPlan = AiDietPlanService.generatePlan(_temp);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.emeraldLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.sparkles, color: Color(0xFF10B981)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "AI পুষ্টি ও মিল ক্যালকুলেশন",
                  style: TextStyle(fontSize: 18.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<ActivityLevel>(
            initialValue: _temp.activity,
            decoration: const InputDecoration(labelText: "দৈনিক কাজের ধরন (Activity Level)"),
            items: ActivityLevel.values
                .map((a) => DropdownMenuItem(
                      value: a,
                      child: Text(a.label),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _temp.activity = v!),
          ),
          const SizedBox(height: 18),

          // Energy Budget Breakdown
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slate800 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.5),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "দৈনিক ক্যালোরি ও লক্ষ্য",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "AI Calculated",
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 18),
                _calcRow("মেটাবলিক রেট (BMR):", "${res.bmr} kcal"),
                _calcRow("দৈনিক শক্তি খরচ (TDEE):", "${res.tdee} kcal"),
                if (res.isWeightGain) ...[
                  _calcRow("ক্যালোরি উদ্বৃত্ত (Surplus):", "+${res.dailyAdjustmentKcal} kcal/দিন", isBold: true),
                ] else if (res.isWeightLoss) ...[
                  _calcRow("ক্যালোরি ঘাটতি (Deficit):", "${res.dailyAdjustmentKcal} kcal/দিন", isBold: true),
                ] else ...[
                  _calcRow("ক্যালোরি ব্যালেন্স (Maintenance):", "০ kcal/দিন"),
                ],
                _calcRow("দৈনিক প্রস্তাবিত বাজেট:", "${res.autoBudget} kcal/দিন", isBold: true),
                const SizedBox(height: 8),

                // Habit targets: Water & Walk
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.slate700 : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.droplets, color: Color(0xFF0EA5E9), size: 18),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("পানি পান", style: TextStyle(fontSize: 10.5, color: AppColors.slate500)),
                              Text(
                                "${aiPlan.waterGoalGlasses} গ্লাস (${aiPlan.waterGoalLiters}L)",
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(width: 1, height: 26, color: AppColors.slate400),
                      Row(
                        children: [
                          const Icon(LucideIcons.footprints, color: Color(0xFF10B981), size: 18),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(res.isWeightGain ? "ব্যায়াম/শরীরচর্চা" : "দ্রুত হাঁটা", style: const TextStyle(fontSize: 10.5, color: AppColors.slate500)),
                              Text(
                                "${aiPlan.walkMinGoal} মিনিট",
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MacroPill(label: "Protein", grams: "${res.macros.protein}g", color: AppColors.protein),
                    _MacroPill(label: "Carbs", grams: "${res.macros.carbs}g", color: AppColors.carbs),
                    _MacroPill(label: "Fat", grams: "${res.macros.fat}g", color: AppColors.fat),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Suggested 4 Meals Preview with calories
          const Row(
            children: [
              Icon(LucideIcons.utensils, size: 17, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              Text(
                "AI তৈরি করা ৪ বেলার খাবারের মেনু ও ক্যালোরি:",
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),

          _MealSlotCard(
            title: "সকালের নাস্তা (Breakfast)",
            targetKcal: aiPlan.slotBudgets[MealSlot.breakfast],
            icon: Icons.wb_sunny_outlined,
            items: aiPlan.meals[MealSlot.breakfast] ?? [],
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _MealSlotCard(
            title: "দুপুরের খাবার (Lunch)",
            targetKcal: aiPlan.slotBudgets[MealSlot.lunch],
            icon: Icons.wb_cloudy_outlined,
            items: aiPlan.meals[MealSlot.lunch] ?? [],
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _MealSlotCard(
            title: "বিকালের নাস্তা (Evening Snack)",
            targetKcal: aiPlan.slotBudgets[MealSlot.snack],
            icon: Icons.coffee_outlined,
            items: aiPlan.meals[MealSlot.snack] ?? [],
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _MealSlotCard(
            title: "রাতের খাবার (Dinner)",
            targetKcal: aiPlan.slotBudgets[MealSlot.dinner],
            icon: Icons.nightlight_round_outlined,
            items: aiPlan.meals[MealSlot.dinner] ?? [],
            isDark: isDark,
          ),

          const SizedBox(height: 14),

          // Auto-entry announcement
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome, color: Color(0xFF10B981), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "নিচে 'AI প্ল্যান নিয়ে শুরু করুন' চাপলে এই খাবার ও পানির লক্ষ্যমাত্রা স্বয়ংক্রিয়ভাবে আপনার ড্যাশবোর্ডে এন্ট্রি হয়ে যাবে!",
                    style: TextStyle(fontSize: 12, height: 1.35, color: Color(0xFF047857), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _calcRow(String title, String val, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            val,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: isBold ? const Color(0xFF10B981) : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _MealSlotCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<dynamic> items;
  final int? targetKcal;
  final bool isDark;

  const _MealSlotCard({
    required this.title,
    required this.icon,
    required this.items,
    this.targetKcal,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final totalKcal = items.fold<int>(0, (sum, i) => sum + (i.kcal as int));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.slate700 : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: const Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  targetKcal != null ? "$totalKcal / ~$targetKcal kcal" : "$totalKcal kcal",
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            items.map((i) => "${i.name} (${i.qty})").join(" • "),
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? AppColors.slate300 : const Color(0xFF475569),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroPill extends StatelessWidget {
  final String label;
  final String grams;
  final Color color;

  const _MacroPill({required this.label, required this.grams, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(grams, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
        Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.slate500)),
      ],
    );
  }
}
