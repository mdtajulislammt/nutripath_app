import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'meal_slot.dart';
import 'food_item.dart';

class DietDayLog {
  final String id;
  final DateTime date;
  final Map<MealSlot, List<FoodItem>> meals;
  final int targetKcal;
  final int waterGlasses;
  final int walkMinutes;
  final String? note;

  DietDayLog({
    required this.id,
    required this.date,
    required this.meals,
    this.targetKcal = 1200,
    this.waterGlasses = 4,
    this.walkMinutes = 15,
    this.note,
  });

  int get consumedKcal {
    return meals.values.expand((list) => list).fold(0, (sum, i) => sum + i.kcal);
  }

  double get consumedProtein {
    return meals.values.expand((list) => list).fold(0.0, (sum, i) => sum + i.p);
  }

  double get consumedCarbs {
    return meals.values.expand((list) => list).fold(0.0, (sum, i) => sum + i.c);
  }

  double get consumedFat {
    return meals.values.expand((list) => list).fold(0.0, (sum, i) => sum + i.f);
  }

  bool get isWithinBudget => consumedKcal <= targetKcal;

  int get remainingKcal => (targetKcal - consumedKcal).clamp(0, targetKcal);

  int get totalFoodItemsCount => meals.values.fold(0, (sum, l) => sum + l.length);

  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final logDate = DateTime(date.year, date.month, date.day);

    final diff = today.difference(logDate).inDays;
    if (diff == 0) {
      return 'Today, ${DateFormat('d MMM').format(date)}';
    } else if (diff == 1) {
      return 'Yesterday, ${DateFormat('d MMM').format(date)}';
    } else {
      return DateFormat('EEEE, d MMM yyyy').format(date);
    }
  }

  String get shortDate => DateFormat('d MMM').format(date);
  String get weekday => DateFormat('EEE').format(date);

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'targetKcal': targetKcal,
    'waterGlasses': waterGlasses,
    'walkMinutes': walkMinutes,
    'note': note,
    'meals': meals.map((k, v) => MapEntry(k.name, v.map((item) => item.toJson()).toList())),
  };

  factory DietDayLog.fromJson(Map<String, dynamic> json) {
    final mealsMap = json['meals'] as Map<String, dynamic>?;
    final parsedMeals = <MealSlot, List<FoodItem>>{};
    for (var slot in MealSlot.values) {
      parsedMeals[slot] = [];
    }

    if (mealsMap != null) {
      mealsMap.forEach((key, val) {
        final slot = MealSlot.values.firstWhere(
          (e) => e.name == key,
          orElse: () => MealSlot.breakfast,
        );
        parsedMeals[slot] = (val as List).map((i) => FoodItem.fromJson(i as Map<String, dynamic>)).toList();
      });
    }

    return DietDayLog(
      id: json['id'] as String? ?? UniqueKey().toString(),
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      targetKcal: json['targetKcal'] as int? ?? 1200,
      waterGlasses: json['waterGlasses'] as int? ?? 4,
      walkMinutes: json['walkMinutes'] as int? ?? 15,
      note: json['note'] as String?,
      meals: parsedMeals,
    );
  }
}
