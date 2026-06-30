enum BadgeCategory {
  streak, // Badge untuk streak achievement
  challenge, // Badge untuk complete challenge tertentu
  saving, // Badge untuk milestone tabungan
  special, // Badge special event
}

class BadgeModel {
  final String id;
  final String name;
  final String description;
  final String iconPath; // Path ke asset icon
  final BadgeCategory category;
  final int requiredPoints; // Points needed to unlock (0 = no requirement)
  final String?
  requiredChallengeId; // Specific challenge yang harus diselesaikan
  final int? requiredStreak; // Streak days yang dibutuhkan


  final bool isEarned;
  final DateTime? earnedDate;

  BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.category,
    this.requiredPoints = 0,
    this.requiredChallengeId,
    this.requiredStreak,
    this.isEarned = false,
    this.earnedDate,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconPath: json['iconPath'] as String,
      category: BadgeCategory.values[json['category'] as int],
      requiredPoints: json['requiredPoints'] as int? ?? 0,
      requiredChallengeId: json['requiredChallengeId'] as String?,
      requiredStreak: json['requiredStreak'] as int?,
      isEarned: json['isEarned'] as bool? ?? false,
      earnedDate: json['earnedDate'] != null
          ? DateTime.parse(json['earnedDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconPath': iconPath,
      'category': category.index,
      'requiredPoints': requiredPoints,
      'requiredChallengeId': requiredChallengeId,
      'requiredStreak': requiredStreak,
      'isEarned': isEarned,
      'earnedDate': earnedDate?.toIso8601String(),
    };
  }

  BadgeModel copyWith({
    String? id,
    String? name,
    String? description,
    String? iconPath,
    BadgeCategory? category,
    int? requiredPoints,
    String? requiredChallengeId,
    int? requiredStreak,
    bool? isEarned,
    DateTime? earnedDate,
  }) {
    return BadgeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconPath: iconPath ?? this.iconPath,
      category: category ?? this.category,
      requiredPoints: requiredPoints ?? this.requiredPoints,
      requiredChallengeId: requiredChallengeId ?? this.requiredChallengeId,
      requiredStreak: requiredStreak ?? this.requiredStreak,
      isEarned: isEarned ?? this.isEarned,
      earnedDate: earnedDate ?? this.earnedDate,
    );
  }


  String get categoryName {
    switch (category) {
      case BadgeCategory.streak:
        return 'Streak';
      case BadgeCategory.challenge:
        return 'Challenge';
      case BadgeCategory.saving:
        return 'Saving';
      case BadgeCategory.special:
        return 'Special';
    }
  }
}
