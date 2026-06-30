enum ChallengeType { daily, weekly, monthly }

enum ChallengeDifficulty { easy, medium, hard }

enum ChallengeTargetType {
  saveAmount, // Tabung sejumlah uang tertentu
  limitExpense, // Batasi pengeluaran total
  zeroExpense, // Tidak boleh ada pengeluaran sama sekali
  categoryLimit, // Batasi pengeluaran kategori tertentu
  noTransactionType, // Tidak boleh ada transaksi tipe tertentu (misal: no online shopping)
  custom, // Tantangan kustom (misal: input semua pengeluaran)
}

enum ChallengeStatus { active, completed, failed, abandoned }

class ChallengeModel {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final ChallengeDifficulty difficulty;
  final int durationDays;
  final ChallengeTargetType targetType;
  final double? targetAmount;
  final String? targetCategory;


  final DateTime startDate;
  final DateTime endDate;
  final double currentProgress;
  final ChallengeStatus status;
  final DateTime? completedDate;


  final int points;
  final String? badgeId;


  final bool isGroupChallenge;
  final String? groupId;
  final Map<String, double>? participantProgress; // userId -> progress

  ChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.difficulty,
    required this.durationDays,
    required this.targetType,
    this.targetAmount,
    this.targetCategory,
    required this.startDate,
    required this.endDate,
    this.currentProgress = 0.0,
    this.status = ChallengeStatus.active,
    this.completedDate,
    this.points = 0,
    this.badgeId,
    this.isGroupChallenge = false,
    this.groupId,
    this.participantProgress,
  });

  factory ChallengeModel.fromJson(Map<String, dynamic> json) {
    return ChallengeModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: ChallengeType.values[json['type'] as int],
      difficulty: ChallengeDifficulty.values[json['difficulty'] as int],
      durationDays: json['durationDays'] as int,
      targetType: ChallengeTargetType.values[json['targetType'] as int],
      targetAmount: json['targetAmount'] != null
          ? (json['targetAmount'] as num).toDouble()
          : null,
      targetCategory: json['targetCategory'] as String?,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      currentProgress: (json['currentProgress'] as num?)?.toDouble() ?? 0.0,
      status: ChallengeStatus.values[json['status'] as int? ?? 0],
      completedDate: json['completedDate'] != null
          ? DateTime.parse(json['completedDate'] as String)
          : null,
      points: json['points'] as int? ?? 0,
      badgeId: json['badgeId'] as String?,
      isGroupChallenge: json['isGroupChallenge'] as bool? ?? false,
      groupId: json['groupId'] as String?,
      participantProgress: json['participantProgress'] != null
          ? Map<String, double>.from(json['participantProgress'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.index,
      'difficulty': difficulty.index,
      'durationDays': durationDays,
      'targetType': targetType.index,
      'targetAmount': targetAmount,
      'targetCategory': targetCategory,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'currentProgress': currentProgress,
      'status': status.index,
      'completedDate': completedDate?.toIso8601String(),
      'points': points,
      'badgeId': badgeId,
      'isGroupChallenge': isGroupChallenge,
      'groupId': groupId,
      'participantProgress': participantProgress,
    };
  }

  ChallengeModel copyWith({
    String? id,
    String? title,
    String? description,
    ChallengeType? type,
    ChallengeDifficulty? difficulty,
    int? durationDays,
    ChallengeTargetType? targetType,
    double? targetAmount,
    String? targetCategory,
    DateTime? startDate,
    DateTime? endDate,
    double? currentProgress,
    ChallengeStatus? status,
    DateTime? completedDate,
    int? points,
    String? badgeId,
    bool? isGroupChallenge,
    String? groupId,
    Map<String, double>? participantProgress,
  }) {
    return ChallengeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      durationDays: durationDays ?? this.durationDays,
      targetType: targetType ?? this.targetType,
      targetAmount: targetAmount ?? this.targetAmount,
      targetCategory: targetCategory ?? this.targetCategory,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      currentProgress: currentProgress ?? this.currentProgress,
      status: status ?? this.status,
      completedDate: completedDate ?? this.completedDate,
      points: points ?? this.points,
      badgeId: badgeId ?? this.badgeId,
      isGroupChallenge: isGroupChallenge ?? this.isGroupChallenge,
      groupId: groupId ?? this.groupId,
      participantProgress: participantProgress ?? this.participantProgress,
    );
  }


  double get progressPercentage {
    if (targetAmount == null || targetAmount == 0) return 0.0;
    return (currentProgress / targetAmount!) * 100;
  }

  bool get isCompleted => status == ChallengeStatus.completed;
  bool get isActive => status == ChallengeStatus.active;
  bool get isFailed => status == ChallengeStatus.failed;

  int get daysRemaining {
    if (status != ChallengeStatus.active) return 0;
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    final diff = endDate.difference(now);

    return (diff.inSeconds / 86400).ceil();
  }

  int get daysCompleted {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return durationDays;
    return now.difference(startDate).inDays;
  }
}
