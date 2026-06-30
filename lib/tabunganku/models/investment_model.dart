class InvestmentModel {
  final String id;
  final String assetName;
  final double totalInvested;
  final double currentValuation;
  final DateTime lastUpdated;

  InvestmentModel({
    required this.id,
    required this.assetName,
    required this.totalInvested,
    required this.currentValuation,
    required this.lastUpdated,
  });

  double get profitLoss => currentValuation - totalInvested;
  double get profitLossPercentage =>
      totalInvested > 0 ? (profitLoss / totalInvested) * 100 : 0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assetName': assetName,
      'totalInvested': totalInvested,
      'currentValuation': currentValuation,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory InvestmentModel.fromJson(Map<String, dynamic> json) {
    return InvestmentModel(
      id: json['id'] as String,
      assetName: json['assetName'] as String,
      totalInvested: (json['totalInvested'] as num).toDouble(),
      currentValuation: (json['currentValuation'] as num).toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  InvestmentModel copyWith({
    String? id,
    String? assetName,
    double? totalInvested,
    double? currentValuation,
    DateTime? lastUpdated,
  }) {
    return InvestmentModel(
      id: id ?? this.id,
      assetName: assetName ?? this.assetName,
      totalInvested: totalInvested ?? this.totalInvested,
      currentValuation: currentValuation ?? this.currentValuation,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
