class FriendModel {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final double balance;
  final DateTime addedDate;

  FriendModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.balance,
    required this.addedDate,
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      balance: (json['balance'] as num).toDouble(),
      addedDate: DateTime.parse(json['addedDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'balance': balance,
      'addedDate': addedDate.toIso8601String(),
    };
  }
}

final List<FriendModel> dummyFriends = [
  FriendModel(
    id: '1',
    name: 'Ahmad Wijaya',
    email: 'ahmad@example.com',
    balance: 2500000,
    addedDate: DateTime.now().subtract(const Duration(days: 30)),
  ),
  FriendModel(
    id: '2',
    name: 'Siti Nurhaliza',
    email: 'siti@example.com',
    balance: 1800000,
    addedDate: DateTime.now().subtract(const Duration(days: 20)),
  ),
  FriendModel(
    id: '3',
    name: 'Budi Santoso',
    email: 'budi@example.com',
    balance: 3200000,
    addedDate: DateTime.now().subtract(const Duration(days: 15)),
  ),
  FriendModel(
    id: '4',
    name: 'Dewi Lestari',
    email: 'dewi@example.com',
    balance: 2000000,
    addedDate: DateTime.now().subtract(const Duration(days: 10)),
  ),
];
