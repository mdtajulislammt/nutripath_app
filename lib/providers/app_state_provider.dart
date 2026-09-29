import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/meal_slot.dart';
import '../models/food_item.dart';
import '../models/weight_record.dart';
import '../models/diet_day_log.dart';
import '../core/utils/bmr_calculator.dart';
import '../services/api_service.dart';
import '../services/ai_diet_plan_service.dart';

class AppStateProvider extends ChangeNotifier {
  UserProfile _profile = UserProfile();
  Map<MealSlot, List<FoodItem>> _meals = {
    MealSlot.breakfast: [],
    MealSlot.lunch: [],
    MealSlot.snack: [],
    MealSlot.dinner: [],
  };

  int _waterGlasses = 0;
  int _walkMinutes = 0;
  int _streakDays = 0;
  bool _isDark = false;
  bool _isOnboarded = false;
  bool _isLoading = false;

  List<WeightRecord> _weightHistory = [];
  List<DietDayLog> _pastDayLogs = [];

  // Analytics & Summary from Backend
  List<Map<String, dynamic>> _weeklyCompliance = [];
  int _weeklyAverageKcal = 0;
  int _compliancePercentage = 100;
  double _startWeight = 110.0;
  double _currentWeight = 110.0;
  double _changeKg = 0.0;
  int _successfulDays = 0;

  // Getters
  UserProfile get profile => _profile;
  Map<MealSlot, List<FoodItem>> get meals => _meals;
  int get waterGlasses => _waterGlasses;
  int get walkMinutes => _walkMinutes;
  int get streakDays => _streakDays;
  bool get isDark => _isDark;
  bool get isOnboarded => _isOnboarded;
  bool get isLoading => _isLoading;
  bool get isAuthenticated {
    // 1. Firebase Google user actively signed in
    if (FirebaseAuth.instance.currentUser != null) return true;

    // 2. Profile has an authenticated Google/Demo account email linked
    if (_profile.isGoogleLinked && (_profile.googleEmail?.isNotEmpty ?? false)) {
      return true;
    }

    return false;
  }
  List<WeightRecord> get weightHistory => _weightHistory;
  List<DietDayLog> get pastDayLogs => _pastDayLogs;

  List<Map<String, dynamic>> get weeklyCompliance => _weeklyCompliance;
  int get weeklyAverageKcal => _weeklyAverageKcal;
  int get compliancePercentage => _compliancePercentage;
  double get startWeight => _startWeight;
  double get currentWeight => _currentWeight;
  double get changeKg => _changeKg;
  int get successfulDays => _successfulDays;

  CalculationResult get metrics => calculateMetrics(_profile);
  AiDietPlan get aiPlan => AiDietPlanService.generatePlan(_profile);

  int get consumedKcal => _meals.values.expand((list) => list).fold(0, (sum, item) => sum + item.kcal);
  double get consumedProtein => _meals.values.expand((list) => list).fold(0.0, (sum, item) => sum + item.p);
  double get consumedCarbs => _meals.values.expand((list) => list).fold(0.0, (sum, item) => sum + item.c);
  double get consumedFat => _meals.values.expand((list) => list).fold(0.0, (sum, item) => sum + item.f);

  int slotKcal(MealSlot slot) => (_meals[slot] ?? []).fold(0, (sum, item) => sum + item.kcal);

  int get dailyBudget => metrics.budget;
  bool get isOverBudget => consumedKcal > metrics.budget;
  int get excessKcal => isOverBudget ? (consumedKcal - metrics.budget) : 0;
  int get remainingKcal => (metrics.budget - consumedKcal).clamp(0, metrics.budget);
  double get calorieProgress => (consumedKcal / (metrics.budget > 0 ? metrics.budget : 1)).clamp(0.0, 1.0);

  int slotBudget(MealSlot slot) =>
      aiPlan.slotBudgets[slot] ?? (metrics.budget * slot.targetShare).round();
  int slotDifference(MealSlot slot) => slotKcal(slot) - slotBudget(slot);
  bool isSlotOverBudget(MealSlot slot) => slotDifference(slot) > 30;
  bool isSlotUnderBudget(MealSlot slot) =>
      slotKcal(slot) > 0 && slotDifference(slot) < -30;
  bool isSlotOnBudget(MealSlot slot) =>
      slotKcal(slot) > 0 && slotDifference(slot).abs() <= 30;
  bool isSlotEmpty(MealSlot slot) => (_meals[slot] ?? []).isEmpty;

  int get totalDaysOnDiet => _profile.daysOnDiet;

  /// Combined diet history including Today's live log at the top, followed by past days
  List<DietDayLog> get allDayLogs {
    final todayLog = DietDayLog(
      id: 'today',
      date: DateTime.now(),
      targetKcal: metrics.budget,
      waterGlasses: _waterGlasses,
      walkMinutes: _walkMinutes,
      meals: Map.from(_meals),
      note: 'Active tracking today',
    );

    return [todayLog, ..._pastDayLogs];
  }

  Future<void>? _initFuture;

  AppStateProvider() {
    _profile.kcalOverride = null;
    ensureInitialized();
  }

  Future<void> ensureInitialized() {
    _initFuture ??= _initialize();
    return _initFuture!;
  }

  Future<void> _initialize() async {
    _isLoading = true;
    try {
      await ApiService.instance.init();

      final fbUser = FirebaseAuth.instance.currentUser;
      final prefs = await SharedPreferences.getInstance();
      final lastEmail = prefs.getString('nutri_last_user_email') ?? fbUser?.email;

      if (fbUser != null) {
        // Active Firebase Google User!
        final email = fbUser.email ?? lastEmail ?? '';
        final name = fbUser.displayName ?? (email.isNotEmpty ? email.split('@').first : 'NutriPath User');

        // Exchange Firebase ID token with backend to establish valid JWT session
        try {
          final idToken = await fbUser.getIdToken();
          if (idToken != null) {
            await ApiService.instance.googleLogin(
              idToken: idToken,
              email: email,
              name: name,
              avatarUrl: fbUser.photoURL,
              firebaseUid: fbUser.uid,
            );
          }
        } catch (e) {
          debugPrint('Backend token exchange error: $e');
        }

        if (email.isNotEmpty) {
          await loadFromPrefs(forEmail: email);
        }

        _profile = _profile.copyWith(
          isGoogleLinked: true,
          googleEmail: email,
          googleDisplayName: name,
          googlePhotoUrl: fbUser.photoURL,
          name: name,
        );

        // Fetch live profile with fresh JWT
        await refreshProfile();
        await refreshTodayMeals();
        await refreshHistory();
        await refreshAnalytics();
      } else if (lastEmail != null && lastEmail.isNotEmpty && ApiService.instance.accessToken != null && ApiService.instance.accessToken!.isNotEmpty) {
        // Demo account with saved token
        await loadFromPrefs(forEmail: lastEmail);
        await refreshProfile();
        await refreshTodayMeals();
        await refreshHistory();
        await refreshAnalytics();
      } else {
        // Fresh start: unauthenticated
        _profile = UserProfile();
        _isOnboarded = false;
        await prefs.remove('api_access_token');
        await prefs.remove('api_refresh_token');
        await prefs.remove('nutri_last_user_email');
      }
    } catch (e) {
      debugPrint('Initialization error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Synchronize with NestJS Backend
  Future<void> initBackendSync() async {
    if (!isAuthenticated || ApiService.instance.accessToken == null || ApiService.instance.accessToken!.isEmpty) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await refreshProfile();
      await refreshTodayMeals();
      await refreshHistory();
      await refreshAnalytics();
    } catch (e) {
      debugPrint('Error syncing with backend: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshProfile() async {
    if (ApiService.instance.accessToken == null || ApiService.instance.accessToken!.isEmpty) {
      return;
    }
    try {
      final user = await ApiService.instance.getProfile();
      if (user != null) {
        final rawKcal = user['kcalOverride'] as int?;
        final dynamicKcalOverride = (rawKcal == 1200) ? null : rawKcal;
        _profile = UserProfile(
          name: user['name'] ?? _profile.name,
          age: (user['age'] as num?)?.toInt() ?? _profile.age,
          gender: user['gender'] == 'FEMALE' ? Gender.female : Gender.male,
          weight: (user['currentWeight'] as num?)?.toDouble() ?? _profile.weight,
          heightCm: (user['heightCm'] as num?)?.toDouble() ?? _profile.heightCm,
          conditions: user['healthConditions'] != null ? List<String>.from(user['healthConditions']) : _profile.conditions,
          targetWeight: (user['targetWeight'] as num?)?.toDouble() ?? _profile.targetWeight,
          months: (user['targetMonths'] as num?)?.toInt() ?? _profile.months,
          activity: _mapActivity(user['activityLevel']),
          kcalOverride: dynamicKcalOverride,
          isGoogleLinked: user['isGoogleLinked'] as bool? ?? _profile.isGoogleLinked,
          googleEmail: user['email'] as String? ?? _profile.googleEmail,
          googleDisplayName: user['name'] as String? ?? _profile.googleDisplayName,
          googlePhotoUrl: user['avatarUrl'] as String? ?? _profile.googlePhotoUrl,
          dietStartDate: DateTime.tryParse(user['dietStartDate'] as String? ?? '') ?? _profile.dietStartDate,
        );
        final hasTarget = (user['targetWeight'] as num?) != null && (user['targetWeight'] as num) > 0;
        final isDbOnboarded = user['isOnboarded'] as bool? ?? false;
        _isOnboarded = isDbOnboarded || hasTarget || _isOnboarded;
        _isDark = user['isDarkTheme'] as bool? ?? _isDark;
        saveToPrefs();
      }
    } catch (e) {
      debugPrint('refreshProfile error: $e');
    }
  }

  ActivityLevel _mapActivity(String? act) {
    switch (act) {
      case 'SEDENTARY':
        return ActivityLevel.sedentary;
      case 'WALKING':
        return ActivityLevel.walking;
      case 'COMMUTE':
      default:
        return ActivityLevel.commute;
    }
  }

  String _mapActivityToBackend(ActivityLevel act) {
    switch (act) {
      case ActivityLevel.sedentary:
        return 'SEDENTARY';
      case ActivityLevel.walking:
        return 'WALKING';
      case ActivityLevel.commute:
        return 'COMMUTE';
    }
  }

  Future<void> refreshTodayMeals() async {
    if (ApiService.instance.accessToken == null || ApiService.instance.accessToken!.isEmpty) {
      return;
    }
    try {
      final todayData = await ApiService.instance.getTodayMeals();
      if (todayData != null) {
        final habits = todayData['habits'] as Map<String, dynamic>?;
        if (habits != null) {
          _waterGlasses = (habits['waterGlasses'] as num?)?.toInt() ?? 0;
          _walkMinutes = (habits['walkMinutes'] as num?)?.toInt() ?? 0;
        }

        final slots = todayData['slots'] as Map<String, dynamic>?;
        if (slots != null) {
          final newMeals = <MealSlot, List<FoodItem>>{
            MealSlot.breakfast: [],
            MealSlot.lunch: [],
            MealSlot.snack: [],
            MealSlot.dinner: [],
          };

          slots.forEach((key, val) {
            final slot = ApiService.instance.backendToSlot(key);
            final itemsList = val['items'] as List<dynamic>? ?? [];
            newMeals[slot] = itemsList.map((item) {
              return FoodItem(
                id: item['id'] ?? '',
                name: item['name'] ?? '',
                qty: item['qty'] ?? '1 serving',
                kcal: (item['kcal'] as num?)?.toInt() ?? 0,
                p: (item['proteinG'] as num?)?.toDouble() ?? 0.0,
                c: (item['carbsG'] as num?)?.toDouble() ?? 0.0,
                f: (item['fatG'] as num?)?.toDouble() ?? 0.0,
              );
            }).toList();
          });

          _meals = newMeals;
        }
        saveToPrefs();
      }
    } catch (e) {
      debugPrint('refreshTodayMeals error: $e');
    }
  }

  Future<void> refreshHistory() async {
    if (ApiService.instance.accessToken == null || ApiService.instance.accessToken!.isEmpty) {
      return;
    }
    try {
      // 1. Summary
      final summary = await ApiService.instance.getHistorySummary();
      if (summary != null) {
        _streakDays = (summary['daysOnDiet'] as num?)?.toInt() ?? _streakDays;
        _successfulDays = (summary['successfulDays'] as num?)?.toInt() ?? 0;
      }

      // 2. Logs
      final logsData = await ApiService.instance.getHistoryLogs();
      if (logsData != null && logsData['items'] is List) {
        final items = logsData['items'] as List<dynamic>;
        final nowStr = DateTime.now().toIso8601String().split('T')[0];

        final logs = <DietDayLog>[];
        for (var item in items) {
          final dateStr = item['date'] as String;
          // Skip today's log from pastDayLogs as it's displayed separately
          if (dateStr == nowStr) continue;

          logs.add(
            DietDayLog(
              id: item['id'] ?? UniqueKey().toString(),
              date: DateTime.tryParse(dateStr) ?? DateTime.now(),
              targetKcal: (item['targetKcal'] as num?)?.toInt() ?? 1200,
              waterGlasses: (item['waterGlasses'] as num?)?.toInt() ?? 0,
              walkMinutes: (item['walkMinutes'] as num?)?.toInt() ?? 0,
              meals: {
                MealSlot.breakfast: [],
                MealSlot.lunch: [],
                MealSlot.snack: [],
                MealSlot.dinner: [],
              },
              note: (item['isWithinBudget'] as bool? ?? false)
                  ? 'Maintained within calorie budget'
                  : 'Slightly above calorie budget',
            ),
          );
        }
        _pastDayLogs = logs;
      }
    } catch (e) {
      debugPrint('refreshHistory error: $e');
    }
  }

  Future<void> refreshAnalytics() async {
    if (ApiService.instance.accessToken == null || ApiService.instance.accessToken!.isEmpty) {
      return;
    }
    try {
      // 1. Weekly compliance
      final compliance = await ApiService.instance.getWeeklyCompliance();
      if (compliance != null) {
        if (compliance['dailyStats'] is List) {
          _weeklyCompliance = List<Map<String, dynamic>>.from(compliance['dailyStats']);
        }
        _weeklyAverageKcal = (compliance['weeklyAverageKcal'] as num?)?.toInt() ?? 0;
        _compliancePercentage = (compliance['compliancePercentage'] as num?)?.toInt() ?? 100;
      }

      // 2. Weight trend
      final trend = await ApiService.instance.getWeightTrend();
      if (trend != null) {
        _startWeight = (trend['startWeight'] as num?)?.toDouble() ?? _profile.weight;
        _currentWeight = (trend['currentWeight'] as num?)?.toDouble() ?? _profile.weight;
        _changeKg = (trend['changeKg'] as num?)?.toDouble() ?? 0.0;

        if (trend['records'] is List) {
          final list = trend['records'] as List<dynamic>;
          _weightHistory = list.map((w) {
            return WeightRecord(
              date: DateTime.tryParse(w['date'] as String? ?? '') ?? DateTime.now(),
              weight: (w['weightKg'] as num?)?.toDouble() ?? _currentWeight,
              note: w['notes'] as String?,
            );
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('refreshAnalytics error: $e');
    }
  }

  // --- Meal Actions connected to Backend ---

  Future<void> addMealItem(MealSlot slot, FoodItem item) async {
    final currentList = _meals[slot] ?? [];
    _meals[slot] = [...currentList, item];
    notifyListeners();
    saveToPrefs();

    // Sync to backend
    try {
      final res = await ApiService.instance.addMealItem(slot: slot, item: item);
      if (res != null && res['item'] != null) {
        // Update local item with backend id if available
        final serverItem = res['item'];
        final updatedList = _meals[slot]!.map((it) {
          if (it.id == item.id) {
            return it.copyWith(id: serverItem['id']);
          }
          return it;
        }).toList();
        _meals[slot] = updatedList;
        notifyListeners();
        saveToPrefs();
      }
      refreshAnalytics();
    } catch (e) {
      debugPrint('Error syncing addMealItem: $e');
    }
  }

  Future<void> removeMealItem(MealSlot slot, String id) async {
    _meals[slot]?.removeWhere((item) => item.id == id);
    notifyListeners();
    saveToPrefs();

    try {
      await ApiService.instance.deleteMealItem(id);
      refreshAnalytics();
    } catch (e) {
      debugPrint('Error syncing removeMealItem: $e');
    }
  }

  Future<void> clearMealSlot(MealSlot slot) async {
    _meals[slot] = [];
    notifyListeners();
    saveToPrefs();

    try {
      await ApiService.instance.clearMealSlot(slot);
      refreshAnalytics();
    } catch (e) {
      debugPrint('Error syncing clearMealSlot: $e');
    }
  }

  Future<void> incrementWater() async {
    if (_waterGlasses < 20) {
      _waterGlasses++;
      notifyListeners();
      saveToPrefs();

      try {
        await ApiService.instance.updateHabits(waterGlassesChange: 1);
      } catch (e) {
        debugPrint('Error syncing incrementWater: $e');
      }
    }
  }

  Future<void> decrementWater() async {
    if (_waterGlasses > 0) {
      _waterGlasses--;
      notifyListeners();
      saveToPrefs();

      try {
        await ApiService.instance.updateHabits(waterGlassesChange: -1);
      } catch (e) {
        debugPrint('Error syncing decrementWater: $e');
      }
    }
  }

  Future<void> addWalkMinutes(int minutes) async {
    _walkMinutes = (_walkMinutes + minutes).clamp(0, 300);
    notifyListeners();
    saveToPrefs();

    try {
      await ApiService.instance.updateHabits(walkMinutesChange: minutes);
    } catch (e) {
      debugPrint('Error syncing addWalkMinutes: $e');
    }
  }

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
    saveToPrefs();
  }

  Future<void> updateProfile(UserProfile newProfile) async {
    _profile = newProfile;
    _isOnboarded = true;
    notifyListeners();
    saveToPrefs();

    try {
      await ApiService.instance.updateProfile({
        'name': newProfile.name,
        'age': newProfile.age,
        'gender': newProfile.gender == Gender.female ? 'FEMALE' : 'MALE',
        'currentWeight': newProfile.weight,
        'heightCm': newProfile.heightCm,
        'targetWeight': newProfile.targetWeight,
        'targetMonths': newProfile.months,
        'activityLevel': _mapActivityToBackend(newProfile.activity),
        'healthConditions': newProfile.conditions,
        'isOnboarded': true,
        if (newProfile.kcalOverride != null) 'kcalOverride': newProfile.kcalOverride,
      });
      refreshAnalytics();
    } catch (e) {
      debugPrint('Error syncing updateProfile: $e');
    }
  }

  /// AI Calculation Engine: calculates and automatically populates meals and habits for onboarding
  Future<void> completeOnboardingWithAiPlan(UserProfile newProfile) async {
    newProfile.kcalOverride = null;
    _profile = newProfile;
    _isOnboarded = true;

    // 1. Calculate & Generate complete AI Diet Plan (Breakfast, Lunch, Snack, Dinner, Water, Walk)
    final aiPlan = AiDietPlanService.generatePlan(_profile);

    // 2. Populate meals and habits directly into the app
    _meals = Map.from(aiPlan.meals);
    _waterGlasses = 0;
    _walkMinutes = 0;

    notifyListeners();
    saveToPrefs();

    // 3. Sync to backend (Update profile with isOnboarded: true, add meal items, refresh analytics)
    try {
      await ApiService.instance.updateProfile({
        'name': newProfile.name,
        'age': newProfile.age,
        'gender': newProfile.gender == Gender.female ? 'FEMALE' : 'MALE',
        'currentWeight': newProfile.weight,
        'heightCm': newProfile.heightCm,
        'targetWeight': newProfile.targetWeight,
        'targetMonths': newProfile.months,
        'activityLevel': _mapActivityToBackend(newProfile.activity),
        'healthConditions': newProfile.conditions,
        'isOnboarded': true,
        'kcalOverride': null,
      });

      try {
        await ApiService.instance.setCalorieCeiling(null);
      } catch (_) {}

      // Synchronize AI meals to backend day log
      for (final slot in MealSlot.values) {
        final items = _meals[slot] ?? [];
        for (final item in items) {
          try {
            await ApiService.instance.addMealItem(slot: slot, item: item);
          } catch (_) {}
        }
      }

      await refreshAnalytics();
      await refreshTodayMeals();
    } catch (e) {
      debugPrint('Error syncing completeOnboardingWithAiPlan: $e');
    }
  }

  Future<void> setKcalOverride(int? kcal) async {
    _profile.kcalOverride = kcal;
    notifyListeners();
    saveToPrefs();

    try {
      await ApiService.instance.setCalorieCeiling(kcal);
      refreshAnalytics();
    } catch (e) {
      debugPrint('Error syncing setKcalOverride: $e');
    }
  }

  Future<void> addWeightRecord(double weight, {String? note}) async {
    _profile.weight = weight;
    _currentWeight = weight;
    _weightHistory.add(WeightRecord(date: DateTime.now(), weight: weight, note: note));
    notifyListeners();
    saveToPrefs();

    try {
      await ApiService.instance.logWeight(weight, notes: note);
      refreshAnalytics();
    } catch (e) {
      debugPrint('Error syncing logWeight: $e');
    }
  }

  Future<void> resetOnboarding() async {
    _isOnboarded = false;
    notifyListeners();
    saveToPrefs();

    try {
      await ApiService.instance.resetOnboarding();
    } catch (e) {
      debugPrint('Error syncing resetOnboarding: $e');
    }
  }


  void _resetState() {
    _meals = {
      MealSlot.breakfast: [],
      MealSlot.lunch: [],
      MealSlot.snack: [],
      MealSlot.dinner: [],
    };
    _waterGlasses = 0;
    _walkMinutes = 0;
    _streakDays = 0;
    _isOnboarded = false;
    _weightHistory = [];
    _pastDayLogs = [];
    _weeklyCompliance = [];
    _weeklyAverageKcal = 0;
    _compliancePercentage = 100;
    _startWeight = 110.0;
    _currentWeight = 110.0;
    _changeKg = 0.0;
    _successfulDays = 0;
    _profile = UserProfile();
  }

  /// Add all AI-suggested items for a slot into the user's logged meals
  Future<void> addAiSuggestedMeal(MealSlot slot) async {
    final items = aiPlan.meals[slot] ?? [];
    for (final item in items) {
      await addMealItem(slot, item);
    }
  }

  String _getPrefsKey([String? email]) {
    final targetEmail = email ?? _profile.googleEmail;
    if (targetEmail != null && targetEmail.isNotEmpty) {
      final sanitized = targetEmail.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
      return 'nutri_state_$sanitized';
    }
    return 'nutri_state_guest';
  }
  // Google Login Integration with Firebase & Multi-User Isolation
  Future<bool> signInWithGoogle({
    required String email,
    required String name,
    String? idToken,
    String? avatarUrl,
    String? firebaseUid,
    bool isNewUser = false,
  }) async {
    // 1. Wipe out any previous user data in memory
    _resetState();
    notifyListeners();

    try {
      final success = await ApiService.instance.googleLogin(
        idToken: idToken ?? "mock_google_${DateTime.now().millisecondsSinceEpoch}",
        email: email,
        name: name,
        avatarUrl: avatarUrl,
        firebaseUid: firebaseUid,
      );

      if (!success) {
        await ApiService.instance.devLogin(
          email: email,
          name: name,
        );
      }
    } catch (e) {
      debugPrint('Backend sync error during Google login: $e');
    }

    _profile = _profile.copyWith(
      isGoogleLinked: true,
      googleEmail: email,
      googleDisplayName: name,
      googlePhotoUrl: avatarUrl,
      name: name,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nutri_last_user_email', email);
    } catch (_) {}

    // Load user-specific local cache if exists
    await loadFromPrefs(forEmail: email);

    // Live verification from database whether this user has already completed onboarding
    try {
      final liveUser = await ApiService.instance.getProfile();
      if (liveUser != null) {
        if (liveUser['isOnboarded'] != null) {
          _isOnboarded = liveUser['isOnboarded'] as bool;
        } else if ((liveUser['targetWeight'] as num?) != null && (liveUser['targetWeight'] as num) > 0) {
          _isOnboarded = true;
        }
      }
    } catch (_) {}

    if (isNewUser) {
      _isOnboarded = false;
    }

    // Synchronize with PostgreSQL database in background if reachable
    initBackendSync();
    notifyListeners();
    return true;
  }

  Future<void> signOutGoogle() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('FirebaseAuth signOut error: $e');
    }
    if (!kIsWeb) {
      try {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
      } catch (e) {
        debugPrint('GoogleSignIn signOut error: $e');
      }
    }
    await ApiService.instance.logout();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('nutri_last_user_email');
    } catch (_) {}
    _resetState();
    _isOnboarded = false;
    notifyListeners();
  }

  Future<void> saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'profile': _profile.toJson(),
        'water': _waterGlasses,
        'walk': _walkMinutes,
        'streak': _streakDays,
        'dark': _isDark,
        'onboarded': _isOnboarded,
        'meals': _meals.map((k, v) => MapEntry(k.name, v.map((item) => item.toJson()).toList())),
        'weightHistory': _weightHistory.map((w) => w.toJson()).toList(),
        'pastDayLogs': _pastDayLogs.map((l) => l.toJson()).toList(),
      };
      final key = _getPrefsKey();
      await prefs.setString(key, jsonEncode(data));
      if (_profile.googleEmail != null && _profile.googleEmail!.isNotEmpty) {
        await prefs.setString('nutri_last_user_email', _profile.googleEmail!);
      }
    } catch (e) {
      debugPrint('Error saving state: $e');
    }
  }

  Future<void> loadFromPrefs({String? forEmail}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final emailToLoad = forEmail ?? prefs.getString('nutri_last_user_email');
      if (emailToLoad == null || emailToLoad.isEmpty) {
        _profile = UserProfile();
        _isOnboarded = false;
        notifyListeners();
        return;
      }
      final key = _getPrefsKey(emailToLoad);
      final raw = prefs.getString(key);
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;

        if (data['profile'] != null) {
          _profile = UserProfile.fromJson(data['profile']);
          if (_profile.kcalOverride == 1200) {
            _profile.kcalOverride = null;
          }
        }
        _waterGlasses = data['water'] as int? ?? 0;
        _walkMinutes = data['walk'] as int? ?? 0;
        _streakDays = data['streak'] as int? ?? 0;
        _isDark = data['dark'] as bool? ?? false;
        _isOnboarded = data['onboarded'] as bool? ?? false;

        final mealsMap = data['meals'] as Map<String, dynamic>?;
        if (mealsMap != null) {
          _meals = mealsMap.map((k, val) {
            final slot = MealSlot.values.firstWhere(
              (e) => e.name == k,
              orElse: () => MealSlot.breakfast,
            );
            final items = (val as List).map((i) => FoodItem.fromJson(i as Map<String, dynamic>)).toList();
            return MapEntry(slot, items);
          });
        }

        final weightList = data['weightHistory'] as List<dynamic>?;
        if (weightList != null && weightList.isNotEmpty) {
          _weightHistory = weightList.map((w) => WeightRecord.fromJson(w as Map<String, dynamic>)).toList();
        }

        final pastLogsList = data['pastDayLogs'] as List<dynamic>?;
        if (pastLogsList != null && pastLogsList.isNotEmpty) {
          _pastDayLogs = pastLogsList.map((l) => DietDayLog.fromJson(l as Map<String, dynamic>)).toList();
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load state from SharedPreferences: $e');
    }
  }
}
