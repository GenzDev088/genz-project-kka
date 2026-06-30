class OverseasTravelGoalModel {
  final String id;
  final String destinationName;
  final String currencyCode; // e.g., USD, JPY, KRW
  final double targetForeignAmount;
  final double collectedIdrAmount;
  final DateTime createdAt;
  final DateTime? targetDate;
  final String countryCode; // For showing flags, e.g., US, JP, KR

  OverseasTravelGoalModel({
    required this.id,
    required this.destinationName,
    required this.currencyCode,
    required this.targetForeignAmount,
    required this.collectedIdrAmount,
    required this.createdAt,
    this.targetDate,
    required this.countryCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'destinationName': destinationName,
      'currencyCode': currencyCode,
      'targetForeignAmount': targetForeignAmount,
      'collectedIdrAmount': collectedIdrAmount,
      'createdAt': createdAt.toIso8601String(),
      'targetDate': targetDate?.toIso8601String(),
      'countryCode': countryCode,
    };
  }

  factory OverseasTravelGoalModel.fromJson(Map<String, dynamic> json) {
    return OverseasTravelGoalModel(
      id: json['id'] as String? ?? '',
      destinationName: json['destinationName'] as String? ?? '',
      currencyCode: json['currencyCode'] as String? ?? 'USD',
      targetForeignAmount:
          (json['targetForeignAmount'] as num?)?.toDouble() ?? 0.0,
      collectedIdrAmount:
          (json['collectedIdrAmount'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      targetDate: json['targetDate'] != null
          ? DateTime.parse(json['targetDate'] as String)
          : null,
      countryCode: json['countryCode'] as String? ?? 'US',
    );
  }

  OverseasTravelGoalModel copyWith({
    String? id,
    String? destinationName,
    String? currencyCode,
    double? targetForeignAmount,
    double? collectedIdrAmount,
    DateTime? createdAt,
    DateTime? targetDate,
    String? countryCode,
  }) {
    return OverseasTravelGoalModel(
      id: id ?? this.id,
      destinationName: destinationName ?? this.destinationName,
      currencyCode: currencyCode ?? this.currencyCode,
      targetForeignAmount: targetForeignAmount ?? this.targetForeignAmount,
      collectedIdrAmount: collectedIdrAmount ?? this.collectedIdrAmount,
      createdAt: createdAt ?? this.createdAt,
      targetDate: targetDate ?? this.targetDate,
      countryCode: countryCode ?? this.countryCode,
    );
  }
}
