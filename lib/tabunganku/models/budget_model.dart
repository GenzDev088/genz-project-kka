class BudgetModel {
  final String id;
  final String category;
  final double limitAmount;
  final int month;
  final int year;

  BudgetModel({
    required this.id,
    required this.category,
    required this.limitAmount,
    required this.month,
    required this.year,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] as String,
      category: json['category'] as String,
      limitAmount: (json['limitAmount'] as num).toDouble(),
      month: json['month'] as int,
      year: json['year'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'limitAmount': limitAmount,
      'month': month,
      'year': year,
    };
  }

  BudgetModel copyWith({
    String? id,
    String? category,
    double? limitAmount,
    int? month,
    int? year,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      category: category ?? this.category,
      limitAmount: limitAmount ?? this.limitAmount,
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }
}
