# NutriPath 🥗 
### AI-Powered Diet, Calorie & Macro Tracker with Banglish Natural Language Logging

NutriPath is a mobile and cross-platform health application built with Flutter, designed to make nutrition, habit, and calorie tracking seamless, intuitive, and culturally tailored. It features natural language Banglish/Bengali meal logging, clinical Mifflin-St Jeor BMR/TDEE energy budgeting, dynamic macro targets, habit tracking (hydration & brisk walking), and interactive weight trend analytics.

---

## 📱 Features

1. **Bilingual & Banglish Natural Language Meal Logger**:
   - Parses colloquial Banglish phrases like `"2 ta dim ar 1 bati pepe sobji bhaji kheyesi"` or Bengali script `"২ টা ডিম আর ১ বাটি ডাল"`.
   - Automatically detects food items, calculates quantities, and aggregates calories, protein, carbs, and fats in real-time.
   - Slot-level budget ceiling alerts to avoid accidental overeating.
   - Quick-select categorized food catalog (Protein, Carbs, Vegetables, Fruits, Dairy, Snacks, Beverage).

2. **Accurate BMR, TDEE & Deficit Engine**:
   - Implements the **Mifflin-St Jeor** formula based on age, gender, weight, and height.
   - Calculates personalized caloric deficit based on user weight goal and target timeline (1-12 months).
   - Enforces safe metabolic calorie floors (1,200 kcal for men, 1,100 kcal for women).
   - Generates recommended macro splits: **30% Protein**, **45% Carbohydrates**, **25% Healthy Fats**.

3. **Smart Habit Tracking**:
   - **Hydration Tracker**: Target of 3.6L - 4.0L with quick increment/decrement buttons.
   - **Brisk Walk Tracker**: Adaptive daily walking goal (30-40+ mins based on user body weight) with 10-minute step quick loggers.
   - **Daily Streak Flame Counter**: Motivation system to encourage consistency.

4. **Dynamic AI Meal Advisor**:
   - Contextual recommendation banner adapting to remaining daily calories and upcoming meal slots.
   - Suggests balanced local alternatives (e.g. leafy shak, lean chicken/fish, cucumber salad, green tea).

5. **Visual Analytics & Progress Tracking**:
   - Interactive weight progression curve powered by `fl_chart`.
   - Weekly consistency score and actionable AI dietary suggestions.
   - Quick weight logging modal dialog.

6. **Material 3 Design & Dark Mode**:
   - Modern emerald green palette with high-contrast slate surfaces.
   - Fluid support for both Light and Dark themes.

---

## 📂 Project Architecture

```
nutripath_app/
├── pubspec.yaml
├── analysis_options.yaml
├── README.md
├── lib/
│   ├── main.dart                                # Application entry point & theme setup
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart                  # Curated emerald, slate & macro palettes
│   │   │   └── foods_catalog.dart               # Bangladeshi & South Asian nutritional database
│   │   ├── theme/
│   │   │   └── app_theme.dart                   # Material 3 Light & Dark themes
│   │   └── utils/
│   │       ├── bmr_calculator.dart              # Mifflin-St Jeor formula & macro distribution
│   │       └── bangla_meal_parser.dart          # Tokenizer & parser for Banglish / English text
│   ├── models/
│   │   ├── food_item.dart                       # Food item schema (calories, P, C, F, quantity)
│   │   ├── meal_slot.dart                       # Breakfast, Lunch, Snack, Dinner enums & shares
│   │   ├── user_profile.dart                    # User bio, medical checklist, activity, goals
│   │   └── weight_record.dart                   # Historical weight records
│   ├── providers/
│   │   └── app_state_provider.dart              # Global state with SharedPreferences persistence
│   ├── screens/
│   │   ├── splash_screen.dart                   # Animated brand launch screen
│   │   ├── onboarding/
│   │   │   └── onboarding_screen.dart           # 4-step wizard (Bio, Conditions, Goals, Live Plan)
│   │   ├── dashboard/
│   │   │   ├── dashboard_screen.dart            # Main dashboard integrating all cards
│   │   │   └── widgets/
│   │   │       ├── calorie_gauge.dart           # Circular budget progress indicator
│   │   │       ├── macro_cards.dart             # Protein, Carbs, Fat progress bars
│   │   │       ├── next_meal_advisor.dart       # Contextual AI advice banner
│   │   │       ├── sub_metrics_row.dart         # Water & brisk walking trackers
│   │   │       └── meal_slot_accordion.dart     # Slot cards with item deletion & quick add
│   │   ├── meal_log/
│   │   │   └── meal_logging_dialog.dart         # Dual-tab dialog: NLP parser & food catalog
│   │   ├── analytics/
│   │   │   └── analytics_screen.dart            # fl_chart weight progression & AI weekly notes
│   │   └── settings/
│   │       └── settings_screen.dart             # Profile summary, calorie override, dark mode
│   └── widgets/
│       └── custom_nav_shell.dart                # Bottom navigation shell (Dashboard, Analytics, Settings)
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (>= 3.2.0)
- Dart SDK (>= 3.2.0 < 4.0.0)
- Android Studio, VS Code, or Xcode (for iOS)

### Installation
1. Clone or navigate to the repository:
   ```bash
   cd nutripath_app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application:
   ```bash
   # On connected Android or iOS device / emulator:
   flutter run

   # Or on Web:
   flutter run -d chrome
   ```

---

## 🍲 Sample Banglish Natural Language Prompts

You can test the parser by typing any of the following into the **Log Meal** dialog:
- `"2 ta dim ar 1 bati pepe sobji bhaji"`
- `"1 cup bhat ar 100g chicken curry"`
- `"2 ruti 1 bati dal o shosha salad"`
- `"1 cup cha ar 1 cup muri"`
- `"1 ta kola ar 1 cup tok doi"`
- `"১ বাটি শাক এবং ১০০ গ্রাম মাছ"`

---

## 📜 License
MIT License. Built for health & wellness.
# nutripath_app
