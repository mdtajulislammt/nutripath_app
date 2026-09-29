import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal_slot.dart';
import '../models/food_item.dart';

class ApiService {
  static final ApiService instance = ApiService._internal();
  ApiService._internal();

  String get baseUrl {
    const customUrl = String.fromEnvironment('API_URL');
    if (customUrl.isNotEmpty) return customUrl;

    if (kIsWeb) {
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : 'localhost';
      return 'http://$host:3000/api/v1';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:3000/api/v1';
      }
    } catch (_) {}
    return 'http://localhost:3000/api/v1';
  }

  String? _accessToken;
  String? _refreshToken;

  String? get accessToken => _accessToken;

  // Initialize and load saved tokens
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('api_access_token');
      _refreshToken = prefs.getString('api_refresh_token');

      
    } catch (e) {
      debugPrint('ApiService init error: $e');
    }
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  // Convert MealSlot to Backend string
  String slotToBackend(MealSlot slot) {
    switch (slot) {
      case MealSlot.breakfast:
        return 'BREAKFAST';
      case MealSlot.lunch:
        return 'LUNCH';
      case MealSlot.snack:
        return 'SNACK';
      case MealSlot.dinner:
        return 'DINNER';
    }
  }

  MealSlot backendToSlot(String slot) {
    switch (slot.toUpperCase()) {
      case 'BREAKFAST':
        return MealSlot.breakfast;
      case 'LUNCH':
        return MealSlot.lunch;
      case 'SNACK':
        return MealSlot.snack;
      case 'DINNER':
        return MealSlot.dinner;
      default:
        return MealSlot.breakfast;
    }
  }

  // --- Auth Endpoints ---

  Future<Map<String, dynamic>?> devLogin({
    String email = 'tajul.dev@gmail.com',
    String name = 'Md Tajul Islam',
  }) async {
    try {
      final url = Uri.parse('$baseUrl/auth/dev-login');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'name': name}),
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = body['data'];
        if (data != null) {
          _accessToken = data['accessToken'];
          _refreshToken = data['refreshToken'];

          final prefs = await SharedPreferences.getInstance();
          if (_accessToken != null) {
            await prefs.setString('api_access_token', _accessToken!);
          }
          if (_refreshToken != null) {
            await prefs.setString('api_refresh_token', _refreshToken!);
          }
          return data;
        }
      }
    } catch (e) {
      debugPrint('devLogin error: $e');
    }
    return null;
  }

  Future<bool> googleLogin({
    required String idToken,
    String? email,
    String? name,
    String? avatarUrl,
    String? firebaseUid,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/auth/google');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': idToken,
          if (email != null) 'email': email,
          if (name != null) 'name': name,
          if (avatarUrl != null) 'avatarUrl': avatarUrl,
          if (firebaseUid != null) 'firebaseUid': firebaseUid,
        }),
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = body['data'];
        if (data != null) {
          _accessToken = data['accessToken'];
          _refreshToken = data['refreshToken'];

          final prefs = await SharedPreferences.getInstance();
          if (_accessToken != null) {
            await prefs.setString('api_access_token', _accessToken!);
          }
          if (_refreshToken != null) {
            await prefs.setString('api_refresh_token', _refreshToken!);
          }
          return true;
        }
      }
    } catch (e) {
      debugPrint('googleLogin error: $e');
    }
    return false;
  }

  Future<void> logout() async {
    try {
      if (_refreshToken != null) {
        final url = Uri.parse('$baseUrl/auth/logout');
        await http.post(
          url,
          headers: _headers,
          body: jsonEncode({'refreshToken': _refreshToken}),
        );
      }
    } catch (_) {}
    _accessToken = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('api_access_token');
    await prefs.remove('api_refresh_token');
  }

  // --- User Profile Endpoints ---

  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final url = Uri.parse('$baseUrl/user/profile');
      final res = await http.get(url, headers: _headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return body['data'];
      }
    } catch (e) {
      debugPrint('getProfile error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> updateProfile(Map<String, dynamic> updateData) async {
    try {
      final url = Uri.parse('$baseUrl/user/profile');
      final res = await http.patch(
        url,
        headers: _headers,
        body: jsonEncode(updateData),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return body['data'];
      }
    } catch (e) {
      debugPrint('updateProfile error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> setCalorieCeiling(int? kcal) async {
    try {
      final url = Uri.parse('$baseUrl/user/calorie-ceiling');
      final res = await http.patch(
        url,
        headers: _headers,
        body: jsonEncode({'kcalOverride': kcal}),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return body['data'];
      }
    } catch (e) {
      debugPrint('setCalorieCeiling error: $e');
    }
    return null;
  }

  Future<bool> resetOnboarding() async {
    try {
      final url = Uri.parse('$baseUrl/user/reset-onboarding');
      final res = await http.post(url, headers: _headers);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('resetOnboarding error: $e');
    }
    return false;
  }

  // --- Meal Logging Endpoints ---

  Future<Map<String, dynamic>?> getTodayMeals() async {
    try {
      final url = Uri.parse('$baseUrl/meals/today');
      final res = await http.get(url, headers: _headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return body['data'];
      }
    } catch (e) {
      debugPrint('getTodayMeals error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> addMealItem({
    required MealSlot slot,
    required FoodItem item,
    String? date,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/meals/item');
      final payload = {
        'slot': slotToBackend(slot),
        'name': item.name,
        'qty': item.qty,
        'kcal': item.kcal,
        'proteinG': item.p,
        'carbsG': item.c,
        'fatG': item.f,
        if (date != null) 'date': date,
      };

      final res = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(payload),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(res.body);
        return body['data'];
      }
    } catch (e) {
      debugPrint('addMealItem error: $e');
    }
    return null;
  }

  Future<bool> deleteMealItem(String itemId) async {
    try {
      final url = Uri.parse('$baseUrl/meals/item/$itemId');
      final res = await http.delete(url, headers: _headers);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('deleteMealItem error: $e');
    }
    return false;
  }

  Future<bool> clearMealSlot(MealSlot slot, {String? date}) async {
    try {
      final slotStr = slotToBackend(slot);
      var uriStr = '$baseUrl/meals/slot/$slotStr';
      if (date != null) uriStr += '?date=$date';
      final url = Uri.parse(uriStr);
      final res = await http.delete(url, headers: _headers);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('clearMealSlot error: $e');
    }
    return false;
  }

  Future<Map<String, dynamic>?> updateHabits({
    int? waterGlassesChange,
    int? waterGlasses,
    int? walkMinutesChange,
    int? walkMinutes,
    String? date,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/meals/habits');
      final payload = <String, dynamic>{
        if (date != null) 'date': date,
        if (waterGlassesChange != null) 'waterGlassesChange': waterGlassesChange,
        if (waterGlasses != null) 'waterGlasses': waterGlasses,
        if (walkMinutesChange != null) 'walkMinutesChange': walkMinutesChange,
        if (walkMinutes != null) 'walkMinutes': walkMinutes,
      };

      final res = await http.patch(
        url,
        headers: _headers,
        body: jsonEncode(payload),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return body['data'];
      }
    } catch (e) {
      debugPrint('updateHabits error: $e');
    }
    return null;
  }

  // --- History & Diary Endpoints ---

  Future<Map<String, dynamic>?> getHistorySummary() async {
    try {
      final url = Uri.parse('$baseUrl/history/summary');
      final res = await http.get(url, headers: _headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return body['data'];
      }
    } catch (e) {
      debugPrint('getHistorySummary error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getHistoryLogs({
    String filter = 'ALL',
    int page = 1,
    int limit = 30,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/history/logs?filter=$filter&page=$page&limit=$limit');
      final res = await http.get(url, headers: _headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return body['data'];
      }
    } catch (e) {
      debugPrint('getHistoryLogs error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getHistoryDateDetail(String dateStr) async {
    try {
      final url = Uri.parse('$baseUrl/history/logs/$dateStr');
      final res = await http.get(url, headers: _headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return body['data'];
      }
    } catch (e) {
      debugPrint('getHistoryDateDetail error: $e');
    }
    return null;
  }

  // --- Analytics Endpoints ---

  Future<Map<String, dynamic>?> getWeeklyCompliance() async {
    try {
      final url = Uri.parse('$baseUrl/analytics/weekly-compliance');
      final res = await http.get(url, headers: _headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return body['data'];
      }
    } catch (e) {
      debugPrint('getWeeklyCompliance error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getWeightTrend() async {
    try {
      final url = Uri.parse('$baseUrl/analytics/weight-trend');
      final res = await http.get(url, headers: _headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return body['data'];
      }
    } catch (e) {
      debugPrint('getWeightTrend error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> logWeight(double weightKg, {String? notes}) async {
    try {
      final url = Uri.parse('$baseUrl/analytics/weight');
      final res = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'weightKg': weightKg,
          if (notes != null) 'notes': notes,
        }),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(res.body);
        return body['data'];
      }
    } catch (e) {
      debugPrint('logWeight error: $e');
    }
    return null;
  }

  // --- Food Catalog & Bangla NLP Endpoints ---

  Future<List<dynamic>?> getFoods({
    String? query,
    String? category,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final params = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (query != null && query.isNotEmpty) params['q'] = query;
      if (category != null && category.isNotEmpty && category != 'All') params['cat'] = category;

      final uri = Uri.parse('$baseUrl/foods').replace(queryParameters: params);
      final res = await http.get(uri, headers: _headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = body['data'];
        if (data != null && data['items'] is List) {
          return data['items'];
        }
      }
    } catch (e) {
      debugPrint('getFoods error: $e');
    }
    return null;
  }

  Future<List<FoodItem>?> parseBanglaMeal(String text) async {
    try {
      final url = Uri.parse('$baseUrl/foods/parse-bangla');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = body['data'] as List<dynamic>?;
        if (list != null) {
          return list.map((item) {
            return FoodItem(
              id: item['foodItemId'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
              name: item['bengaliName'] ?? item['name'] ?? 'Food',
              qty: item['qty'] ?? '1 serving',
              kcal: (item['kcal'] as num?)?.toInt() ?? 0,
              p: (item['proteinG'] as num?)?.toDouble() ?? 0.0,
              c: (item['carbsG'] as num?)?.toDouble() ?? 0.0,
              f: (item['fatG'] as num?)?.toDouble() ?? 0.0,
            );
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('parseBanglaMeal error: $e');
    }
    return null;
  }

  // --- AI Nutritionist Chat Endpoints ---

  Future<Map<String, dynamic>?> queryAiChat(
    String message, {
    Map<String, dynamic>? userContext,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/ai-chat/query');
      final payload = <String, dynamic>{
        'message': message,
        if (userContext != null) 'userContext': userContext,
      };
      final res = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(payload),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return body['data'];
      }
    } catch (e) {
      debugPrint('queryAiChat error: $e');
    }
    return null;
  }

  Future<List<dynamic>?> getAiChatHistory() async {
    try {
      final url = Uri.parse('$baseUrl/ai-chat/history');
      final res = await http.get(url, headers: _headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return body['data'];
      }
    } catch (e) {
      debugPrint('getAiChatHistory error: $e');
    }
    return null;
  }

  Future<bool> clearAiChatHistory() async {
    try {
      final url = Uri.parse('$baseUrl/ai-chat/clear');
      final res = await http.delete(url, headers: _headers);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('clearAiChatHistory error: $e');
    }
    return false;
  }
}
