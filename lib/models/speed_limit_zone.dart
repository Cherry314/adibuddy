import 'dart:math';
import 'package:hive/hive.dart';

part 'speed_limit_zone.g.dart';

@HiveType(typeId: 1)
class SpeedLimitZone {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double latitude;

  @HiveField(2)
  final double longitude;

  @HiveField(3)
  final int speedLimitMph;

  @HiveField(4)
  final String roadName;

  @HiveField(5)
  final DateTime firstSeen;

  @HiveField(6)
  final DateTime lastAccessed;

  @HiveField(7)
  final int accessCount;

  SpeedLimitZone({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.speedLimitMph,
    this.roadName = '',
    required this.firstSeen,
    required this.lastAccessed,
    this.accessCount = 1,
  });

  /// Create a copy with updated access stats
  SpeedLimitZone copyWithAccess() {
    return SpeedLimitZone(
      id: id,
      latitude: latitude,
      longitude: longitude,
      speedLimitMph: speedLimitMph,
      roadName: roadName,
      firstSeen: firstSeen,
      lastAccessed: DateTime.now(),
      accessCount: accessCount + 1,
    );
  }

  /// Calculate distance to given coordinates in meters using Haversine formula
  double distanceTo(double lat, double lon) {
    const earthRadius = 6371000.0; // Earth radius in meters

    final dLat = _toRadians(lat - latitude);
    final dLon = _toRadians(lon - longitude);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(latitude)) *
            cos(_toRadians(lat)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * (pi / 180.0);
}
