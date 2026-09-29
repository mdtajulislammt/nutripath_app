import '../models/chat_message.dart';
import '../models/user_profile.dart';
import '../models/meal_slot.dart';
import '../models/food_item.dart';
import '../core/utils/bmr_calculator.dart';
import 'ai_diet_plan_service.dart';

class BengaliAiNutritionist {
  static Future<ChatMessage> generateResponse({
    required String query,
    required UserProfile profile,
    required CalculationResult metrics,
    required AiDietPlan aiPlan,
    required int consumedKcal,
    required int remainingKcal,
    required int daysOnDiet,
    int waterGlasses = 0,
    int walkMinutes = 0,
    Map<MealSlot, List<FoodItem>>? todayMeals,
  }) async {
    // Brief natural thinking simulation
    await Future.delayed(const Duration(milliseconds: 500));

    final q = query.trim().toLowerCase();
    String replyText = '';
    List<String> followUps = [];

    final name = profile.name.isNotEmpty ? profile.name : 'বন্ধু';
    final isGain = metrics.isWeightGain;
    final isLoss = metrics.isWeightLoss;
    final diffKg = (profile.targetWeight - profile.weight).abs();
    final goalText = isGain
        ? 'ওজন বৃদ্ধি (+${diffKg.toStringAsFixed(1)} কেজি)'
        : (isLoss
            ? 'ওজন কমানো (-${diffKg.toStringAsFixed(1)} কেজি)'
            : 'ওজন বজায় রাখা');

    final bBudget = aiPlan.slotBudgets[MealSlot.breakfast] ?? (metrics.budget * 0.25).round();
    final lBudget = aiPlan.slotBudgets[MealSlot.lunch] ?? (metrics.budget * (isGain ? 0.38 : 0.40)).round();
    final sBudget = aiPlan.slotBudgets[MealSlot.snack] ?? (metrics.budget * (isGain ? 0.15 : 0.12)).round();
    final dBudget = aiPlan.slotBudgets[MealSlot.dinner] ?? (metrics.budget - bBudget - lBudget - sBudget);

    final breakfastFoods = aiPlan.meals[MealSlot.breakfast] ?? [];
    final lunchFoods = aiPlan.meals[MealSlot.lunch] ?? [];
    final snackFoods = aiPlan.meals[MealSlot.snack] ?? [];
    final dinnerFoods = aiPlan.meals[MealSlot.dinner] ?? [];

    // 1. GREETINGS & PERSONAL INTRODUCTION
    if (_matches(q, ['হাই', 'হ্যালো', 'hello', 'hi', 'salam', 'সালাম', 'কেমন আছ', 'kemon acho', 'kemon achen'])) {
      final goalIntro = isGain
          ? 'সুস্থ উপায়ে **+${diffKg.toStringAsFixed(1)} কেজি ওজন বাড়ানো (Weight Gain)**'
          : (isLoss
              ? 'সুস্থ গতিতে **-${diffKg.toStringAsFixed(1)} কেজি ওজন কমানো (Weight Loss)**'
              : 'ওজন বজায় রাখা');

      replyText = 'আসসালামু আলাইকুম $name! আমি আপনার ব্যক্তিগত **AI পুষ্টি ও ডায়েট বিশেষজ্ঞ**। 😊\n\n'
          'আপনার ৪-স্টেপের প্রোফাইল অনুযায়ী:\n'
          '• **বর্তমান ওজন:** ${profile.weight} কেজি | **টার্গেট:** ${profile.targetWeight} কেজি ($goalIntro)\n'
          '• **দৈনিক ক্যালোরি বাজেট:** **${metrics.budget} kcal** (BMR: ${metrics.bmr} kcal, TDEE: ${metrics.tdee} kcal)\n'
          '• **পানি পানের লক্ষ্য:** ${metrics.waterGoalGlasses} গ্লাস (${metrics.waterGoalLiters}L)\n'
          '• **দৈনিক শরীরচর্চা/ব্যায়াম:** ${metrics.walkMinGoal} মিনিট\n\n'
          'আজ কোন বেলা কতটুকু ক্যালোরি খাবেন, কি কি খাবার খাওয়া উচিত বা যেকোনো খাবারের পুষ্টিগুণ জানতে আমাকে প্রশ্ন করুন!';
      followUps = [
        'আমার দৈনিক কত ক্যালোরি খাওয়া উচিত?',
        'আজকে কোন বেলা কি কি খাবার খাব?',
        isGain ? 'ওজন বাড়ানোর সহজ উপায় কি?' : 'ওজন কমানোর সহজ উপায় কি?',
      ];
    }
    // 2. DAILY CALORIE INTAKE & BUDGET (আমার দৈনিক কত ক্যালোরি খাওয়া উচিত?)
    else if (_matches(q, [
      'কত ক্যালোরি খাওয়া উচিত',
      'কত ক্যালরি খাওয়া উচিত',
      'দৈনিক কত ক্যালোরি',
      'koto calorie khabo',
      'koto kcal khawa uchi',
      'বাজেট কত',
      'দৈনিক বাজেট',
      'calorie budget',
      'koto calorie',
      'কত ক্যালোরি',
    ])) {
      final adjustmentText = isGain
          ? 'প্রতিদিন প্রায় **+${metrics.dailyAdjustmentKcal} kcal ক্যালোরি উদ্বৃত্ত (Surplus)** রাখতে হবে'
          : (isLoss
              ? 'প্রতিদিন প্রায় **${metrics.dailyAdjustmentKcal} kcal ক্যালোরি ঘাটতি (Deficit)** রাখতে হবে'
              : 'ক্যালোরি ব্যালেন্স বজায় রাখতে হবে');

      replyText = '🎯 **আপনার দৈনিক ক্যালোরি বিশ্লেষণ ($name):**\n\n'
          '• **আপনার মেটাবলিক রেট (BMR):** ${metrics.bmr} kcal (বিশ্রামরত অবস্থায় শরীরের শক্তি খরচ)\n'
          '• **দৈনিক মোট শক্তি খরচ (TDEE):** ${metrics.tdee} kcal\n'
          '• **লক্ষ্য:** ${profile.weight} কেজি থেকে ${profile.targetWeight} কেজিতে পৌঁছানো (${profile.months} মাসে)\n\n'
          '💡 **আপনার জন্য দৈনিক ক্যালোরি সিলিং হলো:** **${metrics.budget} kcal/দিন**।\n'
          '$adjustmentText।\n\n'
          '📌 **৪ বেলার জন্য সঠিক ক্যালোরি বণ্টন:**\n'
          '১. **সকালের নাস্তা (Breakfast):** ~$bBudget kcal (মোট বাজেটের ২৫%)\n'
          '২. **দুপুরের খাবার (Lunch):** ~$lBudget kcal (মোট বাজেটের ${isGain ? "৩৮%" : "৪০%"})\n'
          '৩. **বিকালের নাস্তা (Snack):** ~$sBudget kcal (মোট বাজেটের ${isGain ? "১৫%" : "১২%"})\n'
          '৪. **রাতের খাবার (Dinner):** ~$dBudget kcal (মোট বাজেটের ${isGain ? "২২%" : "২৩%"})\n\n'
          'প্রতিদিন এই বাজেটের মধ্যে পুষ্টিকর খাবার খেলে আপনার লক্ষ্য ১০০% পূরণ হবে ইনশাআল্লাহ!';
      followUps = [
        'আজকে কোন বেলা কি কি খাবার খাব?',
        'সকালের নাস্তায় কি খাব?',
        'আমার আজকের ক্যালোরি স্ট্যাটাস কি?',
      ];
    }
    // 3. MEALS AND FOOD SUGGESTIONS (কোন বেলা কি খাব এবং কি কি খাব?)
    else if (_matches(q, [
      'কি কি খাব',
      'ki ki khabo',
      'খাবারের তালিকা',
      'চার বেলার খাবার',
      'খাবারের মেনু',
      'food suggestion',
      'meal suggestion',
      'meal plan',
      'ডায়েট চার্ট',
      'diet chart',
      'কোন বেলা কি খাব',
    ])) {
      replyText = '🥗 **আপনার (${metrics.budget} kcal) বাজেটের জন্য ৪ বেলার AI খাবারের তালিকা:**\n\n'
          '🌅 **১. সকালের নাস্তা (~$bBudget kcal):**\n'
          '${_formatItems(breakfastFoods)}\n\n'
          '☀️ **২. দুপুরের খাবার (~$lBudget kcal):**\n'
          '${_formatItems(lunchFoods)}\n\n'
          '☕ **৩. বিকালের নাস্তা (~$sBudget kcal):**\n'
          '${_formatItems(snackFoods)}\n\n'
          '🌙 **৪. রাতের খাবার (~$dBudget kcal):**\n'
          '${_formatItems(dinnerFoods)}\n\n'
          '💧 সাথে সারাদিনে **${metrics.waterGoalGlasses} গ্লাস (${metrics.waterGoalLiters} লিটার)** পানি এবং **${metrics.walkMinGoal} মিনিট** ${isGain ? "ব্যায়াম/শরীরচর্চা" : "দ্রুত হাঁটা"} নিশ্চিত করুন।';
      followUps = [
        'সকালের নাস্তায় কি খাব?',
        'দুপুরের খাবারে কি খাব?',
        'রাতের খাবারে কি খাব?',
      ];
    }
    // 4. BREAKFAST (সকালে কি খাব?)
    else if (_matches(q, ['সকালে কি খাব', 'সকালের খাবার', 'breakfast', 'shokale ki khabo', 'সকালের নাস্তা'])) {
      replyText = '🌅 **সকালের আদর্শ নাস্তার বাজেট: ~$bBudget kcal**\n\n'
          'আপনার স্বাস্থ্য ও লক্ষ্যের ভিত্তিতে AI এর প্রস্তাবিত খাবার:\n'
          '${_formatItems(breakfastFoods)}\n\n'
          '💡 **পরামর্শ:** সকালের নাস্তায় পর্যাপ্ত প্রোটিন রাখুন। এটি সারাদিনের রক্তে শর্করার মাত্রা ও শক্তির ভারসাম্য বজায় রাখে।';
      followUps = [
        'ডিমের পুষ্টিগুণ ও ক্যালোরি কত?',
        '১টি আটার রুটিতে কত ক্যালোরি?',
        'দুপুরে কি খাব?',
      ];
    }
    // 5. LUNCH (দুপুরে কি খাব?)
    else if (_matches(q, ['দুপুরে কি খাব', 'দুপুরের খাবার', 'lunch', 'dupure ki khabo', 'দুপুর'])) {
      replyText = '☀️ **দুপুরের পুষ্টিকর খাবারের বাজেট: ~$lBudget kcal**\n\n'
          'আপনার জন্য AI প্রস্তুতকৃত দুপুরের সুষম খাদ্যতালিকা:\n'
          '${_formatItems(lunchFoods)}\n\n'
          '💡 **খাওয়ার নিয়ম:** খাওয়ার শুরুতে এক গ্লাস পানি এবং এক বাটি তাজা সালাদ খেয়ে নিন, এরপর প্রোটিন ও ভাত গ্রহণ করুন।';
      followUps = [
        '১ কাপ ভাতে কত ক্যালোরি?',
        'মাছের ক্যালোরি কত?',
        'বিকেলে কি খাব?',
      ];
    }
    // 6. SNACKS (বিকেলে কি খাব?)
    else if (_matches(q, ['বিকেলে কি খাব', 'বিকালের নাস্তা', 'snack', 'স্ন্যাক', 'bikele ki khabo', 'হালকা খাবার'])) {
      replyText = '☕ **বিকালের স্বাস্থ্যকর নাস্তার বাজেট: ~$sBudget kcal**\n\n'
          'AI এর স্বাস্থ্যকর স্ন্যাক্স অপশন:\n'
          '${_formatItems(snackFoods)}\n\n'
          '🚫 বিস্কুট, চানাচুর বা তেলে ভাজা খাবার এড়িয়ে চলুন—এগুলোতে প্রচুর ক্ষতিকর ফ্যাট ও চিনি থাকে।';
      followUps = [
        'বাদামের পুষ্টিগুণ কি?',
        'গ্রিন টি দিনে কয় কাপ খাব?',
        'রাতে কি খাব?',
      ];
    }
    // 7. DINNER (রাতে কি খাব?)
    else if (_matches(q, ['রাতে কি খাব', 'রাতের খাবার', 'dinner', 'rate ki khabo', 'রাতের খাবার তালিকা'])) {
      replyText = '🌙 **রাতের খাবারের বাজেট: ~$dBudget kcal**\n\n'
          'AI এর প্রস্তাবিত রাতের হালকা ও পুষ্টিকর খাবার:\n'
          '${_formatItems(dinnerFoods)}\n\n'
          '📌 **গুরুত্বপূর্ণ টিপ:** ঘুমানোর অন্তত ২ ঘণ্টা আগে রাতের খাবার সম্পন্ন করুন যাতে হজমে কোনো বিঘ্ন না ঘটে।';
      followUps = [
        'রাতে ভাত খাওয়া কি ভালো?',
        'ঘুমের আগে দুধ খাওয়ার উপকারিতা',
        'আজকে কত ক্যালোরি খেলাম?',
      ];
    }
    // 8. WEIGHT GAIN GUIDELINES (ওজন বাড়ানোর উপায়)
    else if (_matches(q, ['ওজন বাড়ানো', 'ojon barano', 'weight gain', 'ওজন বাড়াতে চাই', 'স্বাস্থ্য ভালো করার'])) {
      replyText = '💪 **সুস্থ উপায়ে ওজন বৃদ্ধির বৈজ্ঞানিক কৌশল ($name):**\n\n'
          'আপনার লক্ষ্য হলো চর্বি নয়, বরং মাংসপেশি ও সুস্থ টিস্যু গড়ে তোলা:\n'
          '১. **ক্যালোরি উদ্বৃত্ত (Surplus):** আপনার TDEE হলো ${metrics.tdee} kcal। সুস্থ গতিতে ওজন বাড়াতে দৈনিক **${metrics.budget} kcal (+${metrics.dailyAdjustmentKcal} kcal Surplus)** গ্রহণ করুন।\n'
          '২. **উচ্চ প্রোটিন খাদ্য:** ডিম (কুসুমসহ), গরুর দুধ, মুরগি, মাছ, ডাল, ছাতু ও পনির প্রতিদিনের খাদ্যতালিকায় রাখুন।\n'
          '৩. **ক্যালোরি-ঘন পুষ্টিকর খাবার:** বাদাম (কাজু, কাঠবাদাম), খেজুর, পাকা কলা, ঘি, চিনাবাদামের মাখন (Peanut Butter) যোগ করুন।\n'
          '৪. **ঘন ঘন খাবার গ্রহণ:** দিনে ৩টি প্রধান মিল ও ২টি পুষ্টিকর স্ন্যাক্স গ্রহণ করুন।\n'
          '৫. **শক্তি বর্ধক শরীরচর্চা (Strength Training):** প্রতিদিন **${metrics.walkMinGoal} মিনিট** শরীরচর্চা ও পুশ-আপ করুন যাতে ক্যালোরিগুলো পেশিতে রূপান্তর হয়।';
      followUps = [
        'ওজন বাড়ানোর জন্য নাস্তায় কি খাব?',
        'ব্যানানা মিল্কশেক কীভাবে বানাব?',
        'আজকে কি কি খাবার খাব?',
      ];
    }
    // 9. WEIGHT LOSS GUIDELINES (ওজন কমানোর উপায়)
    else if (_matches(q, ['ওজন কমানো', 'ojon komano', 'weight loss', 'ওজন কমাতে চাই', 'মেদ কমানো', 'ভুঁড়ি'])) {
      replyText = '🔥 **সুস্থ উপায়ে ওজন কমানোর বৈজ্ঞানিক কৌশল ($name):**\n\n'
          '১. **ক্যালোরি ঘাটতি (Deficit):** আপনার TDEE হলো ${metrics.tdee} kcal। ওজন কমাতে আপনার দৈনিক বাজেট **${metrics.budget} kcal (${metrics.dailyAdjustmentKcal} kcal Deficit)**। এটি মেনে চললে নিশ্চিত ওজন কমবে।\n'
          '২. **চিনি ও রিফাইন্ড কার্ব বাদ দিন:** চিনিযুক্ত চা, কোল্ড ড্রিঙ্কস, সাদা ময়দা, পরোটা ও মিষ্টি সম্পূর্ণ এড়িয়ে চলুন।\n'
          '৩. **প্রোটিন ও ফাইবার বাড়ান:** ডিম, মুরগির বুকের মাংস, মাছ, ডাল এবং প্রচুর শাকসবজি ও সালাদ খান।\n'
          '৪. **পানি পান:** দৈনিক **${metrics.waterGoalGlasses} গ্লাস (${metrics.waterGoalLiters} লিটার)** পানি পান করুন।\n'
          '৫. **দ্রুত হাঁটা:** প্রতিদিন **${metrics.walkMinGoal} মিনিট** দ্রুত হাঁটুন, যা অতিরিক্ত ২০০-৩০০ ক্যালোরি বার্ন করবে।\n'
          '৬. **পর্যাপ্ত ঘুম:** রাতে অন্তত ৭ ঘণ্টা নিরবচ্ছিন্ন ঘুম মেটাবলিজম ঠিক রাখে।';
      followUps = [
        'ক্যালোরি ডেফিসিট কি?',
        'পেটের মেদ কমানোর টিপস',
        'আজকের খাবারের তালিকা দাও',
      ];
    }
    // 10. REAL-TIME TODAY'S STATUS & TARGET CHECK (টার্গেটের সাথে হচ্ছে কিনা বা বেশি কিনা?)
    else if (_matches(q, [
      'টার্গেট বেশি',
      'টার্গেটের সাথে হচ্ছে কিনা',
      'বেশি কিনা',
      'টার্গেটের চেয়ে বেশি',
      'টার্গেট পূরণ হচ্ছে কিনা',
      'বেশি খাচ্ছি নাকি কম',
      'আমার খাবার কি ঠিক আছে',
      'খাবার ঠিক আছে কিনা',
      'আজকের স্ট্যাটাস',
      'আজকে কত খেলাম',
      'বাজেট বাকি',
      'status',
      'আজকে কি অবস্থা',
      'today',
    ])) {
      final bKcal = (todayMeals?[MealSlot.breakfast] ?? []).fold(0, (sum, i) => sum + i.kcal);
      final lKcal = (todayMeals?[MealSlot.lunch] ?? []).fold(0, (sum, i) => sum + i.kcal);
      final sKcal = (todayMeals?[MealSlot.snack] ?? []).fold(0, (sum, i) => sum + i.kcal);
      final dKcal = (todayMeals?[MealSlot.dinner] ?? []).fold(0, (sum, i) => sum + i.kcal);

      final bItems = todayMeals?[MealSlot.breakfast] ?? [];
      final lItems = todayMeals?[MealSlot.lunch] ?? [];
      final sItems = todayMeals?[MealSlot.snack] ?? [];
      final dItems = todayMeals?[MealSlot.dinner] ?? [];

      final isOverDaily = consumedKcal > metrics.budget;
      final dailyDiff = (consumedKcal - metrics.budget).abs();

      String statusHeadline;
      if (consumedKcal == 0) {
        statusHeadline = 'ℹ️ আপনি আজকে এখনও কোনো খাবার ট্র্যাক করেননি। আপনার আজকের মোট বাজেট **${metrics.budget} kcal**।';
      } else if (isOverDaily) {
        statusHeadline = '🚨 **সতর্কতা: আপনি আজকের মোট টার্গেটের চেয়ে $dailyDiff kcal বেশি খেয়ে ফেলেছেন!**\nদৈনিক বাজেট ছিল **${metrics.budget} kcal**, খাওয়া হয়েছে **$consumedKcal kcal**।';
      } else if (isGain) {
        if (remainingKcal <= 100) {
          statusHeadline = '🎉 **অসাধারণ! ওজন বৃদ্ধির দৈনিক সারপ্লাস টার্গেট প্রায় অর্জিত হয়েছে।** আজ $consumedKcal / ${metrics.budget} kcal গ্রহণ করেছেন।';
        } else {
          statusHeadline = '💪 **ওজন বৃদ্ধির জন্য এখনও $remainingKcal kcal ক্যালরি গ্রহণ করা প্রয়োজন (ঘাটতি আছে)।**';
        }
      } else {
        statusHeadline = '✅ **চমৎকার! আপনি সফলভাবে আপনার ক্যালোরি টার্গেটের মধ্যে আছেন।**\nআজকের বাজেট **${metrics.budget} kcal**-এর মধ্যে আপনি **$consumedKcal kcal** খেয়েছেন (বাকি **$remainingKcal kcal**)।';
      }

      String slotStatusText(String slotTitle, int eaten, int budget, List<FoodItem> items) {
        if (items.isEmpty) {
          return '• **$slotTitle:** এখনও খাওয়া হয়নি (AI বাজেট: ~$budget kcal)';
        }
        final diff = eaten - budget;
        if (diff > 30) {
          return '• **$slotTitle:** $eaten kcal / বাজেট $budget kcal 🔴 **(+$diff kcal অতিরিক্ত বেশি)**';
        } else if (diff < -30) {
          return '• **$slotTitle:** $eaten kcal / বাজেট $budget kcal 🟡 **(${diff.abs()} kcal কম/বাকি)**';
        } else {
          return '• **$slotTitle:** $eaten kcal / বাজেট $budget kcal 🟢 **(নিখুঁত টার্গেট পূরণ)**';
        }
      }

      replyText = '📊 **আপনার আজকের ক্যালোরি ও মিল এনালাইসিস ($name):**\n\n'
          '$statusHeadline\n\n'
          '🍽️ **বেলা অনুযায়ী ক্যালোরি ট্র্যাকিং:**\n'
          '${slotStatusText("সকালের নাস্তা (Breakfast)", bKcal, bBudget, bItems)}\n'
          '${slotStatusText("দুপুরের খাবার (Lunch)", lKcal, lBudget, lItems)}\n'
          '${slotStatusText("বিকালের নাস্তা (Snack)", sKcal, sBudget, sItems)}\n'
          '${slotStatusText("রাতের খাবার (Dinner)", dKcal, dBudget, dItems)}\n\n'
          '💧 **পানি পান:** $waterGlasses / ${metrics.waterGoalGlasses} গ্লাস | 🏃‍♂️ **ব্যায়াম:** $walkMinutes / ${metrics.walkMinGoal} মিনিট\n\n'
          '💡 **AI পরামর্শ:**\n';

      if (isOverDaily) {
        replyText += 'আজকের দিনে আর কোনো অতিরিক্ত ক্যালোরিযুক্ত খাবার গ্রহণ করবেন না। শরীর হালকা রাখতে পর্যাপ্ত পানি ও গ্রিন টি পান করুন এবং রাতে অন্তত ২০-৩০ মিনিট হাঁটুন।';
      } else if (isGain && remainingKcal > 250) {
        replyText += 'ওজন বাড়ানোর জন্য ক্যালোরি ঘাটতি রাখা চলবে না। বাকি $remainingKcal kcal পূরণে বাদাম, দুধ, ছাতু, খেজুর বা কলা খান।';
      } else if (isLoss && remainingKcal > 0) {
        replyText += 'খুবই নিয়ন্ত্রিত ও স্বাস্থ্যসম্মত উপায়ে ডেফিসিট ধরে রেখেছেন! বাকি $remainingKcal kcal-এর মধ্যে হালকা শসা, সালাদ বা গ্রিন টি দিয়ে দিন শেষ করতে পারেন।';
      } else {
        replyText += 'আপনার খাদ্যাভ্যাস ও ক্যালোরি বণ্টন খুবই সুষম হয়েছে। লক্ষ্য অর্জনে এই নিয়ম বজায় রাখুন!';
      }

      followUps = [
        'আজকে কোন বেলা কি কি খাবার খাব?',
        'আমার দৈনিক কত ক্যালোরি খাওয়া উচিত?',
        isGain ? 'ওজন বাড়ানোর জন্য নাস্তায় কি খাব?' : 'ক্যালোরি ডেফিসিট বজায় রাখার টিপস',
      ];
    }
    // 11. FOOD CALORIE: RICE (ভাত)
    else if (_matches(q, ['ভাত', 'rice', 'bhat', 'vath', 'চাল'])) {
      replyText = '🍚 **ভাতের পুষ্টি ও ক্যালোরি তথ্য:**\n\n'
          '• **১ কাপ রান্না করা সাদা ভাত (~১৫০ গ্রাম):** ~২১০ ক্যালোরি (৪৫g কার্ব, ৪g প্রোটিন, ০.৫g ফ্যাট)\n'
          '• **১ ছোট বাটি ভাত (১০০ গ্রাম):** ~১৩০ ক্যালোরি\n'
          '• **লাল চালের ভাত (Brown Rice):** ~২১৫ ক্যালোরি/কাপ (প্রচুর ফাইবারসমৃদ্ধ, যা দীর্ঘক্ষণ পেট ভরিয়ে রাখে)\n\n'
          '${isGain ? "💪 **ওজন বৃদ্ধির টিপ:** দুপুরের খাবারে ২ কাপ ভাত এবং ডিনারে ১.৫ কাপ ভাত ডাল ও মাংসসহ স্বচ্ছন্দে খেতে পারেন।" : "💡 **ওজন কমানোর টিপ:** দিনে ১ বারের বেশি ভাত খাবেন না এবং পরিমাণ ১ কাপের মধ্যে সীমাবদ্ধ রাখুন।" }';
      followUps = [
        'রুটি বনাম ভাত—কোনটি ভালো?',
        '১টি আটার রুটিতে কত ক্যালোরি?',
        'মাছের ক্যালোরি কত?',
      ];
    }
    // 12. FOOD CALORIE: EGG (ডিম)
    else if (_matches(q, ['ডিম', 'egg', 'dim', 'সেদ্ধ ডিম', 'কুসুম', 'ওমলেট'])) {
      replyText = '🥚 **ডিমের পুষ্টি ও ক্যালোরি ব্রেকডাউন:**\n\n'
          '• **১টি মাঝারি সেদ্ধ ডিম:** ~৭০-৭৫ ক্যালোরি (প্রোটিন: ৬.৩g, ফ্যাট: ৫g)\n'
          '• **শুধু সাদা অংশ (Egg White):** মাত্র ১৭ ক্যালোরি (প্রোটিন: ৩.৬g, ফ্যাট: ০g)\n'
          '• **ডিমের কুসুম:** ~৫৫ ক্যালোরি (ভিটামিন এ, ডি, বি১২ ও কোলিন সমৃদ্ধ)\n'
          '• **১টি ডিমের ওমলেট (তেল সহ):** ~১২০-১৫০ ক্যালোরি\n\n'
          '${isGain ? "💪 **ওজন বৃদ্ধির টিপ:** দিনে ২টি পুরো ডিম কুসুমসহ এবং অতিরিক্ত ডিম দুধের সাথে খেতে পারেন।" : "💡 **ওজন কমানোর টিপ:** প্রতিদিন ১টি পুরো ডিম এবং অতিরিক্ত চাইলে শুধু সাদা অংশ খান।" }';
      followUps = [
        'ডিমের কুসুম কি ক্ষতিকর?',
        'মুরগির মাংসের ক্যালোরি কত?',
        'ডালের ক্যালোরি কত?',
      ];
    }
    // 13. FOOD CALORIE: ROTI / PARATHA (রুটি ও পরোটা)
    else if (_matches(q, ['রুটি', 'roti', 'পরোটা', 'paratha', 'আটার রুটি'])) {
      replyText = '🫓 **রুটি ও পরোটার ক্যালোরি তুলনা:**\n\n'
          '• **১টি মাঝারি লাল আটার রুটি:** ~৭০-৮০ ক্যালোরি (১৫g কার্ব, ৩g প্রোটিন)\n'
          '• **১টি সাধারণ তেলের পরোটা:** ~২৫০-৩০০ ক্যালোরি!\n'
          '• **১টি মোগলাই পরোটা:** ~৪৫০-৫৫০ ক্যালোরি!\n\n'
          '${isGain ? "💪 **ওজন বৃদ্ধির টিপ:** সকালে ঘিয়ে হালকা সেঁকা আটার পরোটা বা ২টি রুটি ডিমসহ খান।" : "🎯 **ওজন কমানোর টিপ:** তেলের পরোটা বাদ দিয়ে লাল আটার শুকনো রুটি বেছে নিন।" }';
      followUps = [
        'দিনে কয়টি রুটি খাব?',
        '১ কাপ ভাতের ক্যালোরি কত?',
        'বিকেলের নাস্তায় কি খাওয়া যায়?',
      ];
    }
    // 14. FOOD CALORIE: CHICKEN & MEAT (মাংস)
    else if (_matches(q, ['মাংস', 'chicken', 'মুরগি', 'beef', 'গরুর মাংস', 'murgi'])) {
      replyText = '🍗 **মাংসের ক্যালোরি ও প্রোটিন তথ্য (প্রতি ১০০ গ্রাম):**\n\n'
          '• **মুরগির বুকের মাংস (Skinless Breast):** ~১৬৫ ক্যালোরি | ৩১g প্রোটিন | ৩.৬g ফ্যাট (সেরা লিন প্রোটিন!)\n'
          '• **মুরগির রানের মাংস (Thigh):** ~২০৯ ক্যালোরি | ২৬g প্রোটিন | ১১g ফ্যাট\n'
          '• **চর্বিহীন গরুর মাংস (Lean Beef):** ~২৫০ ক্যালোরি | ২৬g প্রোটিন | ১৫g ফ্যাট\n'
          '• **খাসির মাংস (Mutton):** ~২৯০ ক্যালোরি | উচ্চ চর্বিযুক্ত\n\n'
          '💡 রান্নায় অতিরিক্ত তেল বা ভুনা এড়িয়ে হালকা ঝোল বা গ্রিল করে খাওয়া সবচেয়ে উপকারী।';
      followUps = [
        'মাছে কত ক্যালোরি থাকে?',
        'ডিমের প্রোটিন কত?',
        'দৈনিক কত প্রোটিন প্রয়োজন?',
      ];
    }
    // 15. FOOD CALORIE: FISH (মাছ)
    else if (_matches(q, ['মাছ', 'fish', 'mach', 'রুই', 'ইলিশ'])) {
      replyText = '🐟 **মাছের ক্যালোরি ও ওমেগা-৩ তথ্য (প্রতি ১০০ গ্রাম):**\n\n'
          '• **রুই / কাতলা মাছ:** ~১২০-১৩০ ক্যালোরি | ১৯g প্রোটিন | ৪g ফ্যাট\n'
          '• **তেলাপিয়া / পাঙ্গাশ:** ~১৩০ ক্যালোরি | ২০g প্রোটিন | ৩g ফ্যাট\n'
          '• **ইলিশ মাছ:** ~২৩০-২৬০ ক্যালোরি | ২২g প্রোটিন | ১৯g স্বাস্থ্যকর ওমেগা-৩ ফ্যাট\n'
          '• **ছোট দেশি মাছ (কাচকি, মলা):** ~৮৫-১০০ ক্যালোরি | প্রচুর ক্যালসিয়াম ও ভিটামিন এ\n\n'
          '✨ মাছের প্রোটিন সহজে হজম হয় এবং কার্ডিওভাসকুলার স্বাস্থ্যের জন্য দারুণ উপকারী!';
      followUps = [
        'ইলিশ মাছ খেলে কি ওজন বাড়ে?',
        'মুরগির মাংসের ক্যালোরি কত?',
        'দুপুরে কি খাব?',
      ];
    }
    // 16. WATER INTAKE GUIDELINES (পানি পানের নিয়ম)
    else if (_matches(q, ['পানি', 'water', 'pani', 'কত গ্লাস পানি'])) {
      replyText = '💧 **পানি পানের সঠিক নির্দেশিকা ($name):**\n\n'
          '• **আপনার দৈনিক লক্ষ্য:** **${metrics.waterGoalGlasses} গ্লাস (${metrics.waterGoalLiters} লিটার)**\n'
          '• **সকালে:** ঘুম থেকে উঠে ১-২ গ্লাস হালকা গরম পানি পান করুন।\n'
          '• **খাবারের আগে:** প্রধান খাবার গ্রহণের ৩০ মিনিট আগে ১ গ্লাস পানি পান করুন (হজম ভালো করে ও অতিরিক্ত খাওয়া কমায়)।\n'
          '• **খাবারের সময়:** খাবারের মাঝখানে অতিরিক্ত পানি পান করবেন না (পাকস্থলীর ডাইজেস্টিভ জুস পাতলা হয়ে যায়)।\n'
          '• **ব্যায়ামের সময়:** শরীরচর্চার আগে ও পরে পর্যাপ্ত পানি পান করুন।';
      followUps = [
        'আজকে কত গ্লাস পানি খেলাম?',
        'গ্রিন টি এর উপকারিতা কি?',
        'ব্যায়াম করলে কত ক্যালোরি বার্ন হয়?',
      ];
    }
    // 17. EXERCISE & WALKING (ব্যায়াম ও হাঁটা)
    else if (_matches(q, ['ব্যায়াম', 'exercise', 'হাঁটা', 'walk', 'কদম', 'workout'])) {
      replyText = '🏃‍♂️ **শরীরচর্চা ও ক্যালোরি নির্দেশিকা:**\n\n'
          '• **আপনার দৈনিক টার্গেট:** **${metrics.walkMinGoal} মিনিট**\n'
          '${isGain ? "• **ওজন বৃদ্ধির জন্য ব্যায়াম:** পুশ-আপ, ডাম্বেল, স্কোয়াট ও স্ট্রেন্থ ট্রেইনিং করুন—এতে খাদ্য ক্যালোরি চর্বি না হয়ে পেশিতে রূপান্তর হবে।" : "• **ওজন কমানোর জন্য ব্যায়াম:** মাঝারি থেকে দ্রুত গতিতে হাঁটা (Brisk Walk) ফ্যাট বার্ন করতে অত্যন্ত কার্যকর (৩০ মিনিটে ~১৫০ kcal বার্ন হয়)।" }\n'
          '• দিনে অন্তত ৮,০০০ থেকে ১০,০০০ কদম হাঁটার চেষ্টা করুন।';
      followUps = [
        'ব্যায়ামের আগে কি খাওয়া উচিত?',
        'কতক্ষণ হাঁটলে ১০০ ক্যালোরি বার্ন হয়?',
        'আমার আজকের ক্যালোরি বাজেট কত?',
      ];
    }
    // 18. HEALTH CONDITIONS (ডায়াবেটিস, গ্যাস্ট্রিক, ফ্যাটি লিভার, ইত্যাদি)
    else if (_matches(q, ['ডায়াবেটিস', 'diabetes', 'সুগার', 'গ্যাস্ট্রিক', 'gastric', 'ফ্যাটি লিভার', 'fatty liver', 'প্রেসার', 'bp'])) {
      replyText = '🩺 **আপনার স্বাস্থ্য অবস্থার জন্য AI সতর্কতা ও খাদ্য গাইড:**\n\n'
          'আপনার প্রোফাইলে সংরক্ষিত স্বাস্থ্য সতর্কতা: **${profile.conditions.join(", ")}**\n\n';

      if (profile.conditions.any((c) => c.toLowerCase().contains('diabet'))) {
        replyText += '• **ডায়াবেটিস:** চিনি, মিষ্টি, সাদা ভাত ও মিষ্টি ফল পরিহার করুন। লাল আটার রুটি, করলা, শাকসবজি ও মেথি গ্রহণ করুন।\n';
      }
      if (profile.conditions.any((c) => c.toLowerCase().contains('bp'))) {
        replyText += '• **উচ্চ রক্তচাপ (High BP):** কাঁচা লবণ সম্পূর্ণ পরিহার করুন। পটাশিয়ামসমৃদ্ধ তাজা ফল ও শাকসবজি খান।\n';
      }
      if (profile.conditions.any((c) => c.toLowerCase().contains('gastric'))) {
        replyText += '• **গ্যাস্ট্রিক:** ডুবো তেলে ভাজা ও অতিরিক্ত ঝাল পরিহার করুন। দীর্ঘক্ষণ খালি পেটে থাকবেন না।\n';
      }
      if (profile.conditions.any((c) => c.toLowerCase().contains('fatty'))) {
        replyText += '• **ফ্যাটি লিভার:** চিনিযুক্ত পানীয় ও অতিরিক্ত ফ্যাট বর্জন করুন। ওমেগা-৩ ফ্যাট ও গ্রিন টি গ্রহণ করুন।\n';
      }
      replyText += '\nআপনার জন্য প্রস্তুতকৃত AI মিল প্ল্যানটি এই বিষয়গুলো বিবেচনা করেই তৈরি করা হয়েছে!';
      followUps = [
        'ডায়াবেটিসে ফল খাওয়া যাবে কি?',
        'গ্যাস্ট্রিকের জন্য কি খাবার ভালো?',
        'আজকে কোন বেলা কি খাব?',
      ];
    }
    // 19. APPRECIATION / THANK YOU
    else if (_matches(q, ['ধন্যবাদ', 'dhonnobad', 'thanks', 'thank you'])) {
      replyText = 'আপনাকেও অসংখ্য ধন্যবাদ $name! 😊🙏\n\n'
          'আপনার স্বাস্থ্য ও ডায়েটের পাশে থাকতে পেরে আমি আনন্দিত। লক্ষ্য অর্জনে যেকোনো খাবার গ্রহণের আগে আমাকে নির্দ্বিধায় জিজ্ঞেস করবেন!';
      followUps = [
        'আমার আজকের ক্যালোরি বাজেট কত?',
        'আজকে কোন বেলা কি খাব?',
        'আজকের স্ট্যাটাস দাও',
      ];
    }
    // 20. CONTEXTUAL COMPREHENSIVE FALLBACK READING USER INFO
    else {
      replyText = 'পুষ্টি বিষয়ক প্রশ্নের জন্য ধন্যবাদ $name! 🥗\n\n'
          'আপনার প্রোফাইল তথ্য অনুযায়ী:\n'
          '• **বর্তমান অবস্থা:** ${profile.weight} কেজি → টার্গেট ${profile.targetWeight} কেজি ($goalText)\n'
          '• **দৈনিক প্রস্তাবিত বাজেট:** **${metrics.budget} kcal**\n'
          '• **৪ বেলার আদর্শ বণ্টন:** সকাল (~$bBudget kcal), দুপুর (~$lBudget kcal), বিকাল (~$sBudget kcal), রাত (~$dBudget kcal)।\n\n'
          'আপনি যে খাবারই গ্রহণ করুন, আপনার দৈনিক ক্যালোরি সীমা **${metrics.budget} kcal** এর মধ্যে রাখুন এবং পর্যাপ্ত প্রোটিন, শাকসবজি ও ${metrics.waterGoalGlasses} গ্লাস পানি নিশ্চিত করুন।\n\n'
          'নির্দিষ্ট কোনো খাবার বা মিল প্ল্যান সম্পর্কে বিস্তারিত জানতে নিচে চাপুন:';
      followUps = [
        'আমার দৈনিক কত ক্যালোরি খাওয়া উচিত?',
        'আজকে কোন বেলা কি কি খাবার খাব?',
        'আমার আজকের ক্যালোরি স্ট্যাটাস কি?',
      ];
    }

    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: replyText,
      isUser: false,
      timestamp: DateTime.now(),
      quickFollowUps: followUps,
    );
  }

  static String _formatItems(List<FoodItem> items) {
    if (items.isEmpty) return '• স্বাস্থ্যকর সুষম দেশি খাবার গ্রহণ করুন।';
    return items.map((i) => '• ${i.name} (${i.qty}) — ${i.kcal} kcal').join('\n');
  }

  static bool _matches(String q, List<String> patterns) {
    for (final p in patterns) {
      if (q.contains(p.toLowerCase())) return true;
    }
    return false;
  }
}
