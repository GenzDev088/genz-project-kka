class ShoppingItem {
  final String id;
  final String name;
  final double estimatedPrice;
  final double quantity; // Added
  final String unit; // Added
  final bool isBought;
  final DateTime createdAt;
  final String? url;
  final String? category;
  final String? linkedTransactionId;
  final bool isOnline;
  final String? imagePath;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.estimatedPrice,
    this.quantity = 1,
    this.unit = 'unit',
    this.isBought = false,
    required this.createdAt,
    this.url,
    this.category,
    this.linkedTransactionId,
    this.isOnline = false,
    this.imagePath,
  });

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'] as String,
      name: json['name'] as String,
      estimatedPrice: (json['estimatedPrice'] as num).toDouble(),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: json['unit'] as String? ?? 'unit',
      isBought: json['isBought'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      url: json['url'] as String?,
      category: json['category'] as String?,
      linkedTransactionId: json['linkedTransactionId'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
      imagePath: json['imagePath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'estimatedPrice': estimatedPrice,
      'quantity': quantity,
      'unit': unit,
      'isBought': isBought,
      'createdAt': createdAt.toIso8601String(),
      'url': url,
      'category': category,
      'linkedTransactionId': linkedTransactionId,
      'isOnline': isOnline,
      'imagePath': imagePath,
    };
  }

  ShoppingItem copyWith({
    String? id,
    String? name,
    double? estimatedPrice,
    double? quantity,
    String? unit,
    bool? isBought,
    DateTime? createdAt,
    String? url,
    String? category,
    String? linkedTransactionId,
    bool? isOnline,
    String? imagePath,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      isBought: isBought ?? this.isBought,
      createdAt: createdAt ?? this.createdAt,
      url: url ?? this.url,
      category: category ?? this.category,
      linkedTransactionId: linkedTransactionId ?? this.linkedTransactionId,
      isOnline: isOnline ?? this.isOnline,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
