class SavingTargetModel {
  final String id;
  final String name;
  final double targetAmount;
  final DateTime dueDate;
  final DateTime createdAt;
  final String category; // Added category

  SavingTargetModel({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.dueDate,
    required this.createdAt,
    this.category = 'Umum', // Default category
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'dueDate': dueDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'category': category,
    };
  }

  factory SavingTargetModel.fromJson(Map<String, dynamic> json) {
    return SavingTargetModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 0.0,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      category: json['category'] as String? ?? 'Umum',
    );
  }

  SavingTargetModel copyWith({
    String? id,
    String? name,
    double? targetAmount,
    DateTime? dueDate,
    DateTime? createdAt,
    String? category,
  }) {
    return SavingTargetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
    );
  }
}
