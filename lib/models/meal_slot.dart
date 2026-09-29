import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum MealSlot {
  breakfast,
  lunch,
  snack,
  dinner;

  String get label {
    switch (this) {
      case MealSlot.breakfast:
        return 'Breakfast';
      case MealSlot.lunch:
        return 'Lunch';
      case MealSlot.snack:
        return 'Evening Snack';
      case MealSlot.dinner:
        return 'Dinner';
    }
  }

  double get targetShare {
    switch (this) {
      case MealSlot.breakfast:
        return 0.25;
      case MealSlot.lunch:
        return 0.40;
      case MealSlot.snack:
        return 0.10;
      case MealSlot.dinner:
        return 0.25;
    }
  }

  IconData get icon {
    switch (this) {
      case MealSlot.breakfast:
        return LucideIcons.sunrise;
      case MealSlot.lunch:
        return LucideIcons.sun;
      case MealSlot.snack:
        return LucideIcons.coffee;
      case MealSlot.dinner:
        return LucideIcons.moon;
    }
  }

  String get timeHint {
    switch (this) {
      case MealSlot.breakfast:
        return '7:00 AM - 9:30 AM';
      case MealSlot.lunch:
        return '1:00 PM - 2:30 PM';
      case MealSlot.snack:
        return '5:00 PM - 6:30 PM';
      case MealSlot.dinner:
        return '8:00 PM - 9:30 PM';
    }
  }
}
