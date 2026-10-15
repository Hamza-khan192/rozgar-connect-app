/// Maps to the `LaborProfiles` table (1:1 with [User] for laborers).
class LaborProfile {
  final int laborId;
  final int userId;
  final String? skills; // free-text "about" description
  final int? experience; // years
  final double? dailyWage;
  final double? hourlyRate;
  final String availabilityStatus; // 'available' | 'busy'

  const LaborProfile({
    required this.laborId,
    required this.userId,
    this.skills,
    this.experience,
    this.dailyWage,
    this.hourlyRate,
    this.availabilityStatus = 'available',
  });

  factory LaborProfile.fromJson(Map<String, dynamic> json) {
    return LaborProfile(
      laborId: (json['labor_id'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      skills: json['skills'] as String?,
      experience: (json['experience'] as num?)?.toInt(),
      dailyWage: (json['daily_wage'] as num?)?.toDouble(),
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble(),
      availabilityStatus:
          json['availability_status'] as String? ?? 'available',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'labor_id': laborId,
      'user_id': userId,
      'skills': skills,
      'experience': experience,
      'daily_wage': dailyWage,
      'hourly_rate': hourlyRate,
      'availability_status': availabilityStatus,
    };
  }

  LaborProfile copyWith({
    int? laborId,
    int? userId,
    String? skills,
    int? experience,
    double? dailyWage,
    double? hourlyRate,
    String? availabilityStatus,
  }) {
    return LaborProfile(
      laborId: laborId ?? this.laborId,
      userId: userId ?? this.userId,
      skills: skills ?? this.skills,
      experience: experience ?? this.experience,
      dailyWage: dailyWage ?? this.dailyWage,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
    );
  }

  bool get isAvailable => availabilityStatus == 'available';

  String get wageLabel =>
      dailyWage == null ? 'Wage on request' : 'Rs ${dailyWage!.toStringAsFixed(0)}/day';
}
