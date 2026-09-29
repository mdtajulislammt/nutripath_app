import 'package:uuid/uuid.dart';
import '../../models/food_item.dart';
import '../constants/foods_catalog.dart';

class BanglaMealParser {
  static const List<FoodTemplate> catalog = defaultFoodsCatalog;

  static const Map<String, double> numberWords = {
    'ek': 1.0,
    'one': 1.0,
    'ta': 1.0,
    'ti': 1.0,
    'ekta': 1.0,
    '১': 1.0,
    'dui': 2.0,
    'two': 2.0,
    'duita': 2.0,
    '২': 2.0,
    'tin': 3.0,
    'three': 3.0,
    'tinta': 3.0,
    '৩': 3.0,
    'char': 4.0,
    'four': 4.0,
    'charta': 4.0,
    '৪': 4.0,
    'pach': 5.0,
    'five': 5.0,
    '৫': 5.0,
    'choy': 6.0,
    'six': 6.0,
    '৬': 6.0,
    'half': 0.5,
    'adha': 0.5,
    'adhek': 0.5,
    'dedh': 1.5,
    'arai': 2.5,
  };

  static List<FoodItem> parse(String text) {
    if (text.trim().isEmpty) return [];

    // Normalize text: replace punctuation, lower case
    final cleaned = text.toLowerCase().replaceAll(RegExp(r'[,.+!?;:/\\]'), ' ');
    final tokens = cleaned.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    final List<FoodItem> items = [];
    double pendingQty = 1.0;
    const uuid = Uuid();

    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];

      // Check if token has digit combined with unit/suffix, e.g. "2ta", "1cup", "100g"
      final matchCombined = RegExp(r'^(\d+(\.\d+)?)(ta|ti|cup|bati|bowl|plate|g|pc)?$').firstMatch(token);
      if (matchCombined != null && matchCombined.group(1) != null) {
        final val = double.tryParse(matchCombined.group(1)!);
        if (val != null && val > 0) {
          pendingQty = val;
          continue;
        }
      }

      // Check numeric literal
      final numVal = double.tryParse(token);
      if (numVal != null && numVal > 0) {
        pendingQty = numVal;
        continue;
      }

      // Check dictionary numbers
      if (numberWords.containsKey(token)) {
        pendingQty = numberWords[token]!;
        continue;
      }

      // Skip common filler words
      if (['ar', 'o', 'ebong', 'and', 'with', 'kheyechi', 'kheyesi', 'khailam', 'kheye', 'khawa', 'shesh'].contains(token)) {
        continue;
      }

      // Match against food templates
      final matched = catalog.firstWhere(
        (f) => f.keys.any((k) => token.startsWith(k) || token == k),
        orElse: () => const FoodTemplate(
          name: '',
          keys: [],
          unit: '',
          kcal: 0,
          p: 0,
          c: 0,
          f: 0,
        ),
      );

      if (matched.name.isNotEmpty && !items.any((x) => x.name == matched.name)) {
        final formattedQty = pendingQty == pendingQty.toInt()
            ? '${pendingQty.toInt()} ${matched.unit}'
            : '${pendingQty.toStringAsFixed(1)} ${matched.unit}';

        items.add(FoodItem(
          id: uuid.v4(),
          name: matched.name,
          qty: formattedQty,
          kcal: (matched.kcal * pendingQty).round(),
          p: double.parse((matched.p * pendingQty).toStringAsFixed(1)),
          c: double.parse((matched.c * pendingQty).toStringAsFixed(1)),
          f: double.parse((matched.f * pendingQty).toStringAsFixed(1)),
        ));

        // Reset pendingQty for next item
        pendingQty = 1.0;
      }
    }

    return items;
  }
}
