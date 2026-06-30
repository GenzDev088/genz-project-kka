class InsuranceModel {
  final String id;
  final String policyName;
  final String provider;
  final double premiumAmount;
  final DateTime expiryDate;
  final bool isRenewed;

  InsuranceModel({
    required this.id,
    required this.policyName,
    required this.provider,
    required this.premiumAmount,
    required this.expiryDate,
    this.isRenewed = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'policyName': policyName,
      'provider': provider,
      'premiumAmount': premiumAmount,
      'expiryDate': expiryDate.toIso8601String(),
      'isRenewed': isRenewed,
    };
  }

  factory InsuranceModel.fromJson(Map<String, dynamic> json) {
    return InsuranceModel(
      id: json['id'] as String,
      policyName: json['policyName'] as String,
      provider: json['provider'] as String,
      premiumAmount: (json['premiumAmount'] as num).toDouble(),
      expiryDate: DateTime.parse(json['expiryDate'] as String),
      isRenewed: json['isRenewed'] as bool? ?? false,
    );
  }

  InsuranceModel copyWith({
    String? id,
    String? policyName,
    String? provider,
    double? premiumAmount,
    DateTime? expiryDate,
    bool? isRenewed,
  }) {
    return InsuranceModel(
      id: id ?? this.id,
      policyName: policyName ?? this.policyName,
      provider: provider ?? this.provider,
      premiumAmount: premiumAmount ?? this.premiumAmount,
      expiryDate: expiryDate ?? this.expiryDate,
      isRenewed: isRenewed ?? this.isRenewed,
    );
  }
}
