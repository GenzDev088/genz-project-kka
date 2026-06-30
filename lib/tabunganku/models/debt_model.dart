enum DebtType {
  hutang, // Money I owe others
  piutang, // Money others owe me
}

class DebtModel {
  final String id;
  final String title;
  final String description;
  final double amount;
  final DebtType type;
  final DateTime? dueDate;
  final bool isPaid;
  final String contactName;
  final DateTime createdAt;

  DebtModel({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.type,
    this.dueDate,
    this.isPaid = false,
    required this.contactName,
    required this.createdAt,
  });

  factory DebtModel.fromJson(Map<String, dynamic> json) {
    return DebtModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: DebtType.values[json['type'] as int],
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      isPaid: json['isPaid'] as bool? ?? false,
      contactName: json['contactName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'amount': amount,
      'type': type.index,
      'dueDate': dueDate?.toIso8601String(),
      'isPaid': isPaid,
      'contactName': contactName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  DebtModel copyWith({
    String? id,
    String? title,
    String? description,
    double? amount,
    DebtType? type,
    DateTime? dueDate,
    bool? isPaid,
    String? contactName,
    DateTime? createdAt,
  }) {
    return DebtModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      dueDate: dueDate ?? this.dueDate,
      isPaid: isPaid ?? this.isPaid,
      contactName: contactName ?? this.contactName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
