enum Gender { male, female }

enum ActivityLevel {
  sedentary,
  commute,
  walking;

  String get label {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'Sedentary (Desk job)';
      case ActivityLevel.commute:
        return 'Office Commute & Light Errands';
      case ActivityLevel.walking:
        return 'Light Walking (Active)';
    }
  }

  String get description {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'Minimal movement, sitting most of the day';
      case ActivityLevel.commute:
        return 'Regular commute, light daily movement';
      case ActivityLevel.walking:
        return 'Regular brisk walks, 6000+ daily steps';
    }
  }
}

class UserProfile {
  String name;
  int age;
  Gender gender;
  double weight; // in kg
  double heightCm;
  List<String> conditions;
  double targetWeight;
  int months;
  ActivityLevel activity;
  int? kcalOverride;

  // Google Login & Diet Journey
  bool isGoogleLinked;
  String? googleEmail;
  String? googleDisplayName;
  String? googlePhotoUrl;
  DateTime dietStartDate;

  UserProfile({
    this.name = '',
    this.age = 26,
    this.gender = Gender.male,
    this.weight = 70.0,
    this.heightCm = 170.0,
    List<String>? conditions,
    this.targetWeight = 65.0,
    this.months = 2,
    this.activity = ActivityLevel.commute,
    this.kcalOverride,
    this.isGoogleLinked = false,
    this.googleEmail,
    this.googleDisplayName,
    this.googlePhotoUrl,
    DateTime? dietStartDate,
  })  : conditions = conditions ?? ['None'],
        dietStartDate = dietStartDate ?? DateTime.now();

  int get daysOnDiet {
    final diff = DateTime.now().difference(dietStartDate).inDays;
    return diff < 0 ? 1 : diff + 1;
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'age': age,
    'gender': gender.name,
    'weight': weight,
    'heightCm': heightCm,
    'conditions': conditions,
    'targetWeight': targetWeight,
    'months': months,
    'activity': activity.name,
    'kcalOverride': kcalOverride,
    'isGoogleLinked': isGoogleLinked,
    'googleEmail': googleEmail,
    'googleDisplayName': googleDisplayName,
    'googlePhotoUrl': googlePhotoUrl,
    'dietStartDate': dietStartDate.toIso8601String(),
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: json['name'] as String? ?? 'Tajul',
    age: (json['age'] as num?)?.toInt() ?? 26,
    gender: Gender.values.firstWhere(
      (e) => e.name == json['gender'],
      orElse: () => Gender.male,
    ),
    weight: (json['weight'] as num?)?.toDouble() ?? 110.0,
    heightCm: (json['heightCm'] as num?)?.toDouble() ?? 175.0,
    conditions: json['conditions'] != null
        ? List<String>.from(json['conditions'])
        : ['None'],
    targetWeight: (json['targetWeight'] as num?)?.toDouble() ?? 100.0,
    months: (json['months'] as num?)?.toInt() ?? 2,
    activity: ActivityLevel.values.firstWhere(
      (e) => e.name == json['activity'],
      orElse: () => ActivityLevel.commute,
    ),
    kcalOverride: json['kcalOverride'] as int?,
    isGoogleLinked: json['isGoogleLinked'] as bool? ?? true,
    googleEmail: json['googleEmail'] as String? ?? 'tajul.dev@gmail.com',
    googleDisplayName: json['googleDisplayName'] as String? ?? 'Md Tajul Islam',
    googlePhotoUrl: json['googlePhotoUrl'] as String?,
    dietStartDate: DateTime.tryParse(json['dietStartDate'] as String? ?? '') ??
        DateTime.now().subtract(const Duration(days: 28)),
  );

  UserProfile copyWith({
    String? name,
    int? age,
    Gender? gender,
    double? weight,
    double? heightCm,
    List<String>? conditions,
    double? targetWeight,
    int? months,
    ActivityLevel? activity,
    int? kcalOverride,
    bool? isGoogleLinked,
    String? googleEmail,
    String? googleDisplayName,
    String? googlePhotoUrl,
    DateTime? dietStartDate,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      weight: weight ?? this.weight,
      heightCm: heightCm ?? this.heightCm,
      conditions: conditions ?? List.from(this.conditions),
      targetWeight: targetWeight ?? this.targetWeight,
      months: months ?? this.months,
      activity: activity ?? this.activity,
      kcalOverride: kcalOverride ?? this.kcalOverride,
      isGoogleLinked: isGoogleLinked ?? this.isGoogleLinked,
      googleEmail: googleEmail ?? this.googleEmail,
      googleDisplayName: googleDisplayName ?? this.googleDisplayName,
      googlePhotoUrl: googlePhotoUrl ?? this.googlePhotoUrl,
      dietStartDate: dietStartDate ?? this.dietStartDate,
    );
  }
}
