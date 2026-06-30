enum TransactionType { expense, income }

class TransactionModel {
  final String id;
  final String title;
  final String description;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String category;
  final String? imageUrl;
  final String? groupId;
  final String? creatorName;

  TransactionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.type,
    required this.date,
    required this.category,
    this.imageUrl,
    this.groupId,
    this.creatorName,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    final dateVal = json['date'];
    if (dateVal is String) {
      parsedDate = DateTime.parse(dateVal);
    } else if (dateVal is dynamic &&
        dateVal.runtimeType.toString() == 'Timestamp') {


      parsedDate = dateVal.toDate();
    } else {
      parsedDate = DateTime.now();
    }

    return TransactionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values[json['type'] as int],
      date: parsedDate,
      category: json['category'] as String,
      imageUrl: json['imageUrl'] as String?,
      groupId: json['groupId'] as String?,
      creatorName: json['creatorName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'amount': amount,
      'type': type.index,
      'date': date.toIso8601String(),
      'category': category,
      'imageUrl': imageUrl,
      'groupId': groupId,
      'creatorName': creatorName,
    };
  }

  TransactionModel copyWith({
    String? id,
    String? title,
    String? description,
    double? amount,
    TransactionType? type,
    DateTime? date,
    String? category,
    String? imageUrl,
    String? groupId,
    String? creatorName,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      groupId: groupId ?? this.groupId,
      creatorName: creatorName ?? this.creatorName,
    );
  }
}

final List<TransactionModel> dummyTransactions = [];
