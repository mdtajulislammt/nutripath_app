import '../models/meal_slot.dart';
import '../models/food_item.dart';
import '../models/user_profile.dart';
import '../core/utils/bmr_calculator.dart';

class AiDietPlan {
  final int dailyKcalBudget;
  final int waterGoalGlasses;
  final double waterGoalLiters;
  final int walkMinGoal;
  final Map<MealSlot, List<FoodItem>> meals;
  final Map<MealSlot, int> slotBudgets;
  final String summaryBengali;
  final GoalType goalType;

  const AiDietPlan({
    required this.dailyKcalBudget,
    required this.waterGoalGlasses,
    required this.waterGoalLiters,
    required this.walkMinGoal,
    required this.meals,
    required this.slotBudgets,
    required this.summaryBengali,
    required this.goalType,
  });

  int get totalKcal => meals.values.expand((l) => l).fold(0, (sum, i) => sum + i.kcal);
  double get totalProtein => meals.values.expand((l) => l).fold(0.0, (sum, i) => sum + i.p);
  double get totalCarbs => meals.values.expand((l) => l).fold(0.0, (sum, i) => sum + i.c);
  double get totalFat => meals.values.expand((l) => l).fold(0.0, (sum, i) => sum + i.f);

  bool get isWeightGain => goalType == GoalType.gain;
  bool get isWeightLoss => goalType == GoalType.loss;
}

class AiDietPlanService {
  static AiDietPlan generatePlan(UserProfile profile) {
    final metrics = calculateMetrics(profile);
    final budget = metrics.budget;
    final conditions = profile.conditions;
    final isGain = metrics.isWeightGain;

    final isDiabetes = conditions.any((c) => c.toLowerCase().contains('diabet'));
    final isHighBp = conditions.any((c) => c.toLowerCase().contains('bp') || c.toLowerCase().contains('pressure'));
    final isGastric = conditions.any((c) => c.toLowerCase().contains('gastric') || c.toLowerCase().contains('acid'));
    final isFattyLiver = conditions.any((c) => c.toLowerCase().contains('fatty') || c.toLowerCase().contains('liver'));

    final waterGoal = metrics.waterGoalGlasses;
    final waterLiters = metrics.waterGoalLiters;
    final walkGoal = metrics.walkMinGoal;

    // Slot budget shares
    final int bBudget = (budget * 0.25).round();
    final int lBudget = (budget * (isGain ? 0.38 : 0.40)).round();
    final int sBudget = (budget * (isGain ? 0.15 : 0.12)).round();
    final int dBudget = budget - bBudget - lBudget - sBudget;

    final slotBudgets = {
      MealSlot.breakfast: bBudget,
      MealSlot.lunch: lBudget,
      MealSlot.snack: sBudget,
      MealSlot.dinner: dBudget,
    };

    List<FoodItem> breakfast;
    List<FoodItem> lunch;
    List<FoodItem> snack;
    List<FoodItem> dinner;

    if (isGain) {
      // ==========================================
      // WEIGHT GAIN DIET PLAN (ওজন বৃদ্ধির খাদ্যতালিকা)
      // ==========================================

      // 1. Breakfast (সকালের পুষ্টিকর নাস্তা)
      breakfast = [
        FoodItem(
          id: 'ai_gain_bf_1',
          name: isDiabetes ? 'লাল আটার রুটি (ঘিয়ে হালকা সেঁকা)' : 'ঘিয়ে সেঁকা লাল আটার পরোটা/রুটি',
          qty: bBudget > 450 ? '৩টি' : '২টি',
          kcal: bBudget > 450 ? 270 : 190,
          p: bBudget > 450 ? 9.0 : 6.0,
          c: bBudget > 450 ? 46.0 : 32.0,
          f: 6.0,
        ),
        FoodItem(
          id: 'ai_gain_bf_2',
          name: isHighBp ? 'সেদ্ধ ডিম (পূর্ণ ১টি + ১টি সাদা অংশ)' : 'পূর্ণ ডিমের ওমলেট / সেদ্ধ ডিম',
          qty: '২টি',
          kcal: 155,
          p: 13.0,
          c: 1.2,
          f: 11.0,
        ),
        FoodItem(
          id: 'ai_gain_bf_3',
          name: isDiabetes ? 'পেয়ারা / আপেল ও খেজুর' : 'পাকা সাগর কলা ও খেজুর',
          qty: '১টি কলা + ৩টি খেজুর',
          kcal: 130,
          p: 2.0,
          c: 32.0,
          f: 0.5,
        ),
        const FoodItem(
          id: 'ai_gain_bf_4',
          name: 'খাঁটি তরল গরুর দুধ (হালকা গরম)',
          qty: '১ গ্লাস (২০০ মিলি)',
          kcal: 130,
          p: 6.8,
          c: 10.0,
          f: 7.0,
        ),
      ];

      // 2. Lunch (দুপুরের ভরপেট পুষ্টিকর খাবার)
      lunch = [
        FoodItem(
          id: 'ai_gain_lu_1',
          name: isDiabetes ? 'লাল চালের পুষ্টিকর ভাত' : 'সাদা বা লাল চালের ভাত',
          qty: lBudget > 700 ? '২.৫ কাপ (৩০০ গ্রাম)' : '২ কাপ (২৫০ গ্রাম)',
          kcal: lBudget > 700 ? 380 : 320,
          p: 7.0,
          c: 72.0,
          f: 1.0,
        ),
        FoodItem(
          id: 'ai_gain_lu_2',
          name: isFattyLiver ? 'বড় রুই মাছের ঝোল (কম তেলে)' : 'দেশি মুরগির মাংস ভুনা বা বড় রুই মাছ',
          qty: '১ বড় বাটি (১২০ গ্রাম)',
          kcal: 220,
          p: 26.0,
          c: 3.0,
          f: 11.0,
        ),
        const FoodItem(
          id: 'ai_gain_lu_3',
          name: 'ঘন মসুর বা বুটের ডাল',
          qty: '১ বড় বাটি (২০০ মিলি)',
          kcal: 160,
          p: 10.5,
          c: 24.0,
          f: 2.5,
        ),
        FoodItem(
          id: 'ai_gain_lu_4',
          name: isDiabetes ? 'করল্লা ও শাক ভাজি' : 'আলু-পটল ভাজি বা ডিম ভাজি',
          qty: '১ বাটি',
          kcal: 110,
          p: 4.0,
          c: 14.0,
          f: 4.5,
        ),
        const FoodItem(
          id: 'ai_gain_lu_5',
          name: 'শসা, গাজর ও লেবুর সালাদ',
          qty: '১ প্লেট',
          kcal: 30,
          p: 1.0,
          c: 6.0,
          f: 0.2,
        ),
      ];

      // 3. Evening Snack (বিকালের হাই-ক্যালোরি হেলদি স্ন্যাক্স)
      snack = [
        FoodItem(
          id: 'ai_gain_sn_1',
          name: isDiabetes ? 'ছোলা ভাজা ও শসা' : 'ব্যানানা মিল্কশেক বা ছাতুর শরবত',
          qty: '১ গ্লাস (২৫০ মিলি)',
          kcal: 180,
          p: 7.0,
          c: 32.0,
          f: 3.5,
        ),
        const FoodItem(
          id: 'ai_gain_sn_2',
          name: 'মিক্সড বাদাম (কাজু, কাঠবাদাম, চিনা বাদাম)',
          qty: '১ মুঠো (৩০ গ্রাম)',
          kcal: 175,
          p: 6.0,
          c: 6.0,
          f: 15.0,
        ),
      ];

      // 4. Dinner (রাতের পুষ্টিকর খাবার)
      dinner = [
        FoodItem(
          id: 'ai_gain_di_1',
          name: 'লাল আটার রুটি বা ভাত',
          qty: dBudget > 550 ? '৩টি রুটি' : '২টি রুটি',
          kcal: dBudget > 550 ? 240 : 160,
          p: 8.0,
          c: 48.0,
          f: 2.0,
        ),
        const FoodItem(
          id: 'ai_gain_di_2',
          name: 'মুরগির বুকের মাংস বা মাছের দোপেঁয়াজা',
          qty: '১ বাটি (১০০ গ্রাম)',
          kcal: 180,
          p: 24.0,
          c: 2.0,
          f: 8.0,
        ),
        const FoodItem(
          id: 'ai_gain_di_3',
          name: 'ঘন ডাল ও মিক্সড সবজি তরকারি',
          qty: '১ বাটি',
          kcal: 120,
          p: 6.0,
          c: 18.0,
          f: 2.5,
        ),
        FoodItem(
          id: 'ai_gain_di_4',
          name: isGastric ? 'হালকা গরম পানি' : 'ঘুমানোর আগে ১ গ্লাস হালকা গরম দুধ',
          qty: '১ গ্লাস',
          kcal: 110,
          p: 6.0,
          c: 9.0,
          f: 5.5,
        ),
      ];
    } else {
      // ==========================================
      // WEIGHT LOSS DIET PLAN (ওজন কমানোর খাদ্যতালিকা)
      // ==========================================

      // 1. Breakfast (সকালের স্বাস্থ্যকর নাস্তা)
      breakfast = [
        FoodItem(
          id: 'ai_loss_bf_1',
          name: isDiabetes ? 'লাল আটার পাতলা রুটি (লো-গ্লাইসেমিক)' : 'লাল আটার পাতলা শুকনো রুটি',
          qty: bBudget > 320 ? '২টি' : '১টি',
          kcal: bBudget > 320 ? 150 : 80,
          p: bBudget > 320 ? 6.0 : 3.0,
          c: bBudget > 320 ? 30.0 : 16.0,
          f: 1.0,
        ),
        FoodItem(
          id: 'ai_loss_bf_2',
          name: isHighBp ? 'সেদ্ধ ডিম (কুসুম ছাড়া বা ১টি পুরো)' : 'সেদ্ধ ডিম',
          qty: '১টি',
          kcal: 75,
          p: 6.5,
          c: 0.6,
          f: 5.0,
        ),
        const FoodItem(
          id: 'ai_loss_bf_3',
          name: 'শসা, টমেটো ও লেবুর সালাদ',
          qty: '১ বাটি',
          kcal: 25,
          p: 1.0,
          c: 4.5,
          f: 0.2,
        ),
        FoodItem(
          id: 'ai_loss_bf_4',
          name: isGastric ? 'হালকা গরম পানি বা আদা চা (চিনি ছাড়া)' : 'চিনি ছাড়া গ্রিন টি / রং চা',
          qty: '১ কাপ',
          kcal: 2,
          p: 0.0,
          c: 0.5,
          f: 0.0,
        ),
      ];

      // 2. Lunch (দুপুরের সুষম খাবার)
      lunch = [
        FoodItem(
          id: 'ai_loss_lu_1',
          name: isDiabetes ? 'লাল চালের পরিমিত ভাত' : 'ভাত (লাল বা সাদা চাল)',
          qty: lBudget > 500 ? '১.৫ কাপ (২২০ গ্রাম)' : '১ কাপ (১৫০ গ্রাম)',
          kcal: lBudget > 500 ? 270 : 200,
          p: lBudget > 500 ? 5.5 : 4.0,
          c: lBudget > 500 ? 58.0 : 44.0,
          f: 0.6,
        ),
        FoodItem(
          id: 'ai_loss_lu_2',
          name: isFattyLiver ? 'তাজা রুই/কাতল মাছ পাতলা ঝোল (কম তেল)' : 'রুই/কাতল মাছের পাতলা ঝোল',
          qty: '১ মাঝারি টুকরো (৯০ গ্রাম)',
          kcal: 140,
          p: 18.0,
          c: 2.0,
          f: 6.5,
        ),
        const FoodItem(
          id: 'ai_loss_lu_3',
          name: 'পাতলা মসুর ডাল',
          qty: '১ বাটি (১৫০ মিলি)',
          kcal: 90,
          p: 6.0,
          c: 13.0,
          f: 1.5,
        ),
        FoodItem(
          id: 'ai_loss_lu_4',
          name: isDiabetes ? 'করল্লা বা শাক ভাজি (কম তেলে)' : 'সবুজ শাক ও পাঁচমিশালি সবজি',
          qty: '১ বাটি',
          kcal: 60,
          p: 2.5,
          c: 7.0,
          f: 2.5,
        ),
      ];

      // 3. Evening Snack (বিকালের হালকা নাস্তা)
      snack = [
        const FoodItem(
          id: 'ai_loss_sn_1',
          name: 'শুকনা মুড়ি',
          qty: '১ মুঠো (২৫ গ্রাম)',
          kcal: 75,
          p: 1.5,
          c: 17.0,
          f: 0.2,
        ),
        FoodItem(
          id: 'ai_loss_sn_2',
          name: isDiabetes ? 'ভেজানো কাঁচা ছোলা ও শসা' : 'চিনা বাদাম / কাজু বাদাম',
          qty: '১০-১২টি',
          kcal: 65,
          p: 3.0,
          c: 3.0,
          f: 5.0,
        ),
        const FoodItem(
          id: 'ai_loss_sn_3',
          name: 'চিনি ছাড়া গ্রিন টি',
          qty: '১ কাপ',
          kcal: 2,
          p: 0.0,
          c: 0.5,
          f: 0.0,
        ),
      ];

      // 4. Dinner (রাতের হালকা খাবার)
      dinner = [
        FoodItem(
          id: 'ai_loss_di_1',
          name: 'লাল আটার পাতলা রুটি',
          qty: dBudget > 300 ? '২টি' : '১টি',
          kcal: dBudget > 300 ? 150 : 80,
          p: dBudget > 300 ? 6.0 : 3.0,
          c: dBudget > 300 ? 30.0 : 16.0,
          f: 1.0,
        ),
        const FoodItem(
          id: 'ai_loss_di_2',
          name: 'মুরগির বুকের মাংস পাতলা ঝোল (চামড়া ছাড়া)',
          qty: '১ মাঝারি বাটি (১০০ গ্রাম)',
          kcal: 135,
          p: 22.0,
          c: 1.5,
          f: 4.0,
        ),
        const FoodItem(
          id: 'ai_loss_di_3',
          name: 'পেঁপে ও লাউ সবজি ভুনা (হালকা মসলা)',
          qty: '১ বাটি',
          kcal: 55,
          p: 1.5,
          c: 8.0,
          f: 1.5,
        ),
        const FoodItem(
          id: 'ai_loss_di_4',
          name: 'কাঁচা শসা ও টমেটো সালাদ',
          qty: '১ ছোট প্লেট',
          kcal: 20,
          p: 0.8,
          c: 3.5,
          f: 0.2,
        ),
      ];
    }

    // Comprehensive Bengali Summary for User
    final goalText = isGain
        ? 'স্বাস্থ্যকর উপায়ে **ওজন বৃদ্ধি (Weight Gain)**'
        : (metrics.isWeightLoss ? 'সুস্থ গতিতে **ওজন কমানো (Weight Loss)**' : '**ওজন নিয়ন্ত্রণ (Maintenance)**');

    final adjustmentText = isGain
        ? 'দৈনিক ক্যালোরি উদ্বৃত্ত (Surplus): **+${metrics.dailyAdjustmentKcal} kcal**'
        : (metrics.isWeightLoss ? 'দৈনিক ক্যালোরি ঘাটতি (Deficit): **${metrics.dailyAdjustmentKcal} kcal**' : 'বাজেট সমন্বয়');

    final summary = 'আপনার BMR: ${metrics.bmr} kcal, TDEE: ${metrics.tdee} kcal।\n'
        'আপনার লক্ষ্য $goalText। এর জন্য $adjustmentText সহ দৈনিক প্রস্তাবিত ক্যালোরি বাজেট **${metrics.budget} kcal**।\n\n'
        '📌 **বেলা অনুযায়ী ক্যালোরি বণ্টন:**\n'
        '• সকালের নাস্তা: ~$bBudget kcal\n'
        '• দুপুরের খাবার: ~$lBudget kcal\n'
        '• বিকালের নাস্তা: ~$sBudget kcal\n'
        '• রাতের খাবার: ~$dBudget kcal\n\n'
        '💧 প্রতিদিন **$waterGoal গ্লাস ($waterLiters লিটার) পানি** এবং 🏃 **$walkGoal মিনিট শরীরচর্চা/ব্যায়াম** সম্পন্ন করার লক্ষ্য রাখা হয়েছে।';

    return AiDietPlan(
      dailyKcalBudget: budget,
      waterGoalGlasses: waterGoal,
      waterGoalLiters: waterLiters,
      walkMinGoal: walkGoal,
      meals: {
        MealSlot.breakfast: breakfast,
        MealSlot.lunch: lunch,
        MealSlot.snack: snack,
        MealSlot.dinner: dinner,
      },
      slotBudgets: slotBudgets,
      summaryBengali: summary,
      goalType: metrics.goalType,
    );
  }
}
