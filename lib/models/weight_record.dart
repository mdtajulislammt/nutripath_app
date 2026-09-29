class WeightRecord {
  final DateTime date;
  final double weight;
  final String? note;

  const WeightRecord({
    required this.date,
    required this.weight,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'weight': weight,
    'note': note,
  };

  factory WeightRecord.fromJson(Map<String, dynamic> json) => WeightRecord(
    date: DateTime.parse(json['date'] as String),
    weight: (json['weight'] as num).toDouble(),
    note: json['note'] as String?,
  );
}
