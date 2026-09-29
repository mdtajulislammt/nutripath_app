import 'package:flutter_test/flutter_test.dart';
import 'package:nutripath/models/user_profile.dart';
import 'package:nutripath/core/utils/bmr_calculator.dart';

void main() {
  group('AI Dynamic Target Kcal Calculation Tests (Non-Static)', () {
    test('Calculates distinct, dynamic target kcal for different user data', () {
      // User 1: Heavy male seeking weight loss (-20 kg in 3 months)
      final userLoss = UserProfile(
        name: 'Rahim',
        age: 28,
        gender: Gender.male,
        weight: 100.0,
        heightCm: 178.0,
        targetWeight: 80.0,
        months: 3,
        activity: ActivityLevel.commute,
      );
      final resLoss = calculateMetrics(userLoss);

      // User 2: Lean male seeking weight gain (+10 kg in 3 months)
      final userGain = UserProfile(
        name: 'Karim',
        age: 22,
        gender: Gender.male,
        weight: 55.0,
        heightCm: 172.0,
        targetWeight: 65.0,
        months: 3,
        activity: ActivityLevel.walking,
      );
      final resGain = calculateMetrics(userGain);

      // User 3: Female seeking gentle weight loss (-5 kg in 4 months)
      final userFemale = UserProfile(
        name: 'Fatima',
        age: 32,
        gender: Gender.female,
        weight: 68.0,
        heightCm: 160.0,
        targetWeight: 63.0,
        months: 4,
        activity: ActivityLevel.sedentary,
      );
      final resFemale = calculateMetrics(userFemale);

      // Verify none of them are stuck at 1200 or static
      expect(resLoss.budget, isNot(equals(1200)));
      expect(resGain.budget, isNot(equals(1200)));
      expect(resFemale.budget, isNot(equals(1200)));

      // Verify that all 3 users have completely different, personalized calorie targets
      expect(resLoss.budget, isNot(equals(resGain.budget)));
      expect(resLoss.budget, isNot(equals(resFemale.budget)));
      expect(resGain.budget, isNot(equals(resFemale.budget)));

      // Verify goal types
      expect(resLoss.isWeightLoss, isTrue);
      expect(resGain.isWeightGain, isTrue);
      expect(resFemale.isWeightLoss, isTrue);

      // Verify weight gain has a positive adjustment (surplus) and higher calories
      expect(resGain.dailyAdjustmentKcal, greaterThan(0));
      expect(resGain.budget, greaterThan(resGain.tdee));

      // Verify weight loss has a negative adjustment (deficit)
      expect(resLoss.dailyAdjustmentKcal, lessThan(0));
      expect(resLoss.budget, lessThan(resLoss.tdee));

      // Dynamic water goals based on weight
      expect(resLoss.waterGoalGlasses, greaterThan(resGain.waterGoalGlasses));
    });

    test('Changing user parameters immediately recalculates target dynamically', () {
      final user = UserProfile(
        name: 'Tajul',
        age: 26,
        gender: Gender.male,
        weight: 90.0,
        heightCm: 175.0,
        targetWeight: 80.0,
        months: 2,
        activity: ActivityLevel.sedentary,
      );
      final initialBudget = calculateMetrics(user).budget;

      // Increase activity level -> budget should increase because TDEE is higher
      user.activity = ActivityLevel.walking;
      final activeBudget = calculateMetrics(user).budget;
      expect(activeBudget, greaterThan(initialBudget));

      // Increase timeline months -> daily deficit is gentler, so budget increases
      user.months = 6;
      final gentleBudget = calculateMetrics(user).budget;
      expect(gentleBudget, greaterThan(activeBudget));
    });
  });
}
