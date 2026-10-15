/// Maps to the `Favorites` table.
class Favorite {
  final int favoriteId;
  final int customerId;
  final int laborId;
  final DateTime? createdAt;

  const Favorite({
    required this.favoriteId,
    required this.customerId,
    required this.laborId,
    this.createdAt,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      favoriteId: (json['favorite_id'] as num?)?.toInt() ?? 0,
      customerId: (json['customer_id'] as num?)?.toInt() ?? 0,
      laborId: (json['labor_id'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'favorite_id': favoriteId,
      'customer_id': customerId,
      'labor_id': laborId,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
