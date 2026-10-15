/// Maps to the `Users` table.
class User {
  final int userId;
  final String name;
  final String phone;
  final String role; // 'customer' | 'laborer' | 'admin'
  final DateTime? createdAt;

  const User({
    required this.userId,
    required this.name,
    required this.phone,
    required this.role,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String? ?? 'customer',
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'phone': phone,
      'role': role,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  bool get isCustomer => role == 'customer';
  bool get isLaborer => role == 'laborer';
  bool get isAdmin => role == 'admin';

  String get roleLabel {
    switch (role) {
      case 'laborer':
        return 'Laborer';
      case 'admin':
        return 'Admin';
      default:
        return 'Customer';
    }
  }
}
