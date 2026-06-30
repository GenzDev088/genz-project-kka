import 'package:otax/tabunganku/models/transaction_model.dart';

enum RecurringFrequency { daily, weekly, monthly }

class RecurringTransactionModel {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String category;
  final RecurringFrequency frequency;
  final DateTime startDate;
  final DateTime lastProcessedDate;
  final bool isActive;

  RecurringTransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.frequency,
    required this.startDate,
    required this.lastProcessedDate,
    this.isActive = true,
  });

  factory RecurringTransactionModel.fromJson(Map<String, dynamic> json) {
    return RecurringTransactionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values[json['type'] as int],
      category: json['category'] as String,
      frequency: RecurringFrequency.values[json['frequency'] as int],
      startDate: DateTime.parse(json['startDate'] as String),
      lastProcessedDate: DateTime.parse(json['lastProcessedDate'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.index,
      'category': category,
      'frequency': frequency.index,
      'startDate': startDate.toIso8601String(),
      'lastProcessedDate': lastProcessedDate.toIso8601String(),
      'isActive': isActive,
    };
  }

  RecurringTransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    String? category,
    RecurringFrequency? frequency,
    DateTime? startDate,
    DateTime? lastProcessedDate,
    bool? isActive,
  }) {
    return RecurringTransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      lastProcessedDate: lastProcessedDate ?? this.lastProcessedDate,
      isActive: isActive ?? this.isActive,
    );
  }
}
