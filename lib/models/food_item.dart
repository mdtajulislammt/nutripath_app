class FoodItem {
  final String id;
  final String name;
  final String qty;
  final int kcal;
  final double p; // Protein (g)
  final double c; // Carbs (g)
  final double f; // Fat (g)

  const FoodItem({
    required this.id,
    required this.name,
    required this.qty,
    required this.kcal,
    required this.p,
    required this.c,
    required this.f,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'qty': qty,
    'kcal': kcal,
    'p': p,
    'c': c,
    'f': f,
  };

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? 'Food Item',
    qty: json['qty'] as String? ?? '1 serving',
    kcal: (json['kcal'] as num?)?.toInt() ?? 0,
    p: (json['p'] as num?)?.toDouble() ?? 0.0,
    c: (json['c'] as num?)?.toDouble() ?? 0.0,
    f: (json['f'] as num?)?.toDouble() ?? 0.0,
  );

  FoodItem copyWith({
    String? id,
    String? name,
    String? qty,
    int? kcal,
    double? p,
    double? c,
    double? f,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      qty: qty ?? this.qty,
      kcal: kcal ?? this.kcal,
      p: p ?? this.p,
      c: c ?? this.c,
      f: f ?? this.f,
    );
  }

  @override
  String toString() => 'FoodItem(id: $id, name: $name, kcal: $kcal, P: ${p}g, C: ${c}g, F: ${f}g)';
}
