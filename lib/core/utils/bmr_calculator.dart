import '../../models/user_profile.dart';

enum GoalType {
  loss,
  gain,
  maintain,
}

class CalculationResult {
  final int bmr;
  final int tdee;
  final int budget;
  final int autoBudget;
  final int walkMinGoal;
  final int waterGoalGlasses;
  final double waterGoalLiters;
  final MacroBudget macros;
  final GoalType goalType;
  final int dailyAdjustmentKcal; // Negative for deficit, positive for surplus, 0 for maintain
  final double weightDifferenceKg;

  const CalculationResult({
    required this.bmr,
    required this.tdee,
    required this.budget,
    required this.autoBudget,
    required this.walkMinGoal,
    required this.waterGoalGlasses,
    required this.waterGoalLiters,
    required this.macros,
    required this.goalType,
    required this.dailyAdjustmentKcal,
    required this.weightDifferenceKg,
  });

  bool get isWeightGain => goalType == GoalType.gain;
  bool get isWeightLoss => goalType == GoalType.loss;
  bool get isMaintenance => goalType == GoalType.maintain;
}

class MacroBudget {
  final int protein; // grams (4 kcal/g)
  final int carbs;   // grams (4 kcal/g)
  final int fat;     // grams (9 kcal/g)

  const MacroBudget({
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}

CalculationResult calculateMetrics(UserProfile p) {
  // 1. Mifflin-St Jeor formula for BMR
  final genderOffset = p.gender == Gender.male ? 5 : -161;
  final bmr = (10 * p.weight + 6.25 * p.heightCm - 5 * p.age + genderOffset).round();

  // 2. Physical Activity Factor
  final factor = switch (p.activity) {
    ActivityLevel.sedentary => 1.2,
    ActivityLevel.commute => 1.3,
    ActivityLevel.walking => 1.4,
  };
  final tdee = (bmr * factor).round();

  final days = (p.months * 30).clamp(30, 365);
  final floor = p.gender == Gender.male ? 1200 : 1100;

  GoalType goalType;
  int adjustmentKcal;
  int auto;
  final diffKg = (p.targetWeight - p.weight).abs();

  // 3. Weight Loss vs Weight Gain Determination
  if (p.targetWeight < (p.weight - 0.5)) {
    // Weight Loss Goal
    goalType = GoalType.loss;
    final deficit = ((diffKg * 7700) / days).round().clamp(200, 1000);
    adjustmentKcal = -deficit;
    auto = (((tdee - deficit) / 50).round() * 50).clamp(floor, 4000);
  } else if (p.targetWeight > (p.weight + 0.5)) {
    // Weight Gain Goal
    goalType = GoalType.gain;
    final surplus = ((diffKg * 7700) / days).round().clamp(250, 800);
    adjustmentKcal = surplus;
    auto = (((tdee + surplus) / 50).round() * 50).clamp(floor, 5000);
  } else {
    // Maintenance Goal
    goalType = GoalType.maintain;
    adjustmentKcal = 0;
    auto = tdee;
  }

  final budget = p.kcalOverride ?? auto;
  final walk = p.weight > 100 ? 45 : (p.weight > 85 ? 40 : 30);

  // Water goal: 35ml per kg of body weight (0.25L per glass)
  final waterGoal = (p.weight * 0.035 / 0.25).round().clamp(8, 18);
  final waterLiters = double.parse((waterGoal * 0.25).toStringAsFixed(2));

  // 4. Macro split: tailored for Gain vs Loss and health conditions
  final isDiabetes = p.conditions.any((c) => c.toLowerCase().contains('diabet'));
  double pPercent;
  double cPercent;
  double fPercent;

  if (goalType == GoalType.gain) {
    // Weight gain: Higher carbs and adequate protein for building mass
    pPercent = isDiabetes ? 0.30 : 0.25;
    cPercent = isDiabetes ? 0.45 : 0.52;
    fPercent = 1.0 - pPercent - cPercent;
  } else if (goalType == GoalType.loss) {
    // Weight loss: Higher protein to preserve lean muscle, controlled carbs
    pPercent = isDiabetes ? 0.35 : 0.30;
    cPercent = isDiabetes ? 0.40 : 0.45;
    fPercent = 1.0 - pPercent - cPercent;
  } else {
    // Maintenance
    pPercent = 0.28;
    cPercent = 0.47;
    fPercent = 0.25;
  }

  final macros = MacroBudget(
    protein: ((budget * pPercent) / 4).round(),
    carbs: ((budget * cPercent) / 4).round(),
    fat: ((budget * fPercent) / 9).round(),
  );

  return CalculationResult(
    bmr: bmr,
    tdee: tdee,
    budget: budget,
    autoBudget: auto,
    walkMinGoal: walk,
    waterGoalGlasses: waterGoal,
    waterGoalLiters: waterLiters,
    macros: macros,
    goalType: goalType,
    dailyAdjustmentKcal: adjustmentKcal,
    weightDifferenceKg: diffKg,
  );
}
