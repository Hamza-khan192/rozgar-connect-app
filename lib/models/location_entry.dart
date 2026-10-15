/// Maps to the `Locations` table (laborer location history).
class LocationEntry {
  final int locationId;
  final int laborId;
  final double? latitude;
  final double? longitude;
  final DateTime? updatedAt;

  const LocationEntry({
    required this.locationId,
    required this.laborId,
    this.latitude,
    this.longitude,
    this.updatedAt,
  });

  factory LocationEntry.fromJson(Map<String, dynamic> json) {
    return LocationEntry(
      locationId: (json['location_id'] as num?)?.toInt() ?? 0,
      laborId: (json['labor_id'] as num?)?.toInt() ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.tryParse(json['updated_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location_id': locationId,
      'labor_id': laborId,
      'latitude': latitude,
      'longitude': longitude,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get coordsLabel {
    if (latitude == null || longitude == null) return 'Not set';
    return '${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}';
  }
}
