class BillModel {
  final String id;
  final String name;
  final double amount;
  final int dueDay; // 1-31
  final bool isPaid;
  final DateTime? lastPaidDate;

  BillModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDay,
    this.isPaid = false,
    this.lastPaidDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'dueDay': dueDay,
      'isPaid': isPaid,
      'lastPaidDate': lastPaidDate?.toIso8601String(),
    };
  }

  factory BillModel.fromJson(Map<String, dynamic> json) {
    return BillModel(
      id: json['id'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      dueDay: json['dueDay'] as int,
      isPaid: json['isPaid'] as bool? ?? false,
      lastPaidDate: json['lastPaidDate'] != null
          ? DateTime.parse(json['lastPaidDate'] as String)
          : null,
    );
  }

  BillModel copyWith({
    String? id,
    String? name,
    double? amount,
    int? dueDay,
    bool? isPaid,
    DateTime? lastPaidDate,
  }) {
    return BillModel(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      dueDay: dueDay ?? this.dueDay,
      isPaid: isPaid ?? this.isPaid,
      lastPaidDate: lastPaidDate ?? this.lastPaidDate,
    );
  }
}
