class FamilyGroupModel {
  final String id;
  final String code;
  final String name;
  final String adminName;
  final List<String> members;
  final Map<String, double> memberBalances;
  final Map<String, String> memberPhotos; // nama → URL foto profil

  FamilyGroupModel({
    required this.id,
    required this.code,
    required this.name,
    required this.adminName,
    required this.members,
    required this.memberBalances,
    this.memberPhotos = const {},
  });

  factory FamilyGroupModel.fromJson(Map<String, dynamic> json) {
    return FamilyGroupModel(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      adminName: json['adminName'] as String? ?? 'Admin',
      members:
          (json['members'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      memberBalances:
          (json['memberBalances'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
          ) ??
          {},
      memberPhotos:
          (json['memberPhotos'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as String),
          ) ??
          {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'adminName': adminName,
      'members': members,
      'memberBalances': memberBalances,
      'memberPhotos': memberPhotos,
    };
  }

  double get totalGroupSavings {
    return memberBalances.values.fold(0, (sum, balance) => sum + balance);
  }
}
