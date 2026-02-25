import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/speed_limit_zone.dart';

/// Service to cache and learn speed limit zones.
/// This reduces API calls to Overpass by storing known speed limit locations locally.
/// Perfect for driving instructors who operate in the same geographical area.
class SpeedLimitCacheService {
  static const String _boxName = 'speed_limit_zones';
  static const double _defaultSearchRadius = 100.0; // meters
  static const double _minDistanceBetweenZones = 150.0; // meters - don't create zones too close
  
  static Box<SpeedLimitZone>? _box;
  static final _uuid = Uuid();

  /// Initialize the cache
  static Future<void> init() async {
    _box = await Hive.openBox<SpeedLimitZone>(_boxName);
  }

  /// Get the cache box (for testing/debugging)
  static Box<SpeedLimitZone>? getBox() => _box;

  /// Check if we have a cached speed limit near the given coordinates
  /// Returns the speed limit if found within radius, null otherwise
  static Future<int?> getCachedSpeedLimit(
    double latitude,
    double longitude, {
    double radiusMeters = _defaultSearchRadius,
  }) async {
    if (_box == null) await init();

    SpeedLimitZone? closestZone;
    double closestDistance = double.infinity;

    for (final zone in _box!.values) {
      final distance = zone.distanceTo(latitude, longitude);
      
      if (distance <= radiusMeters && distance < closestDistance) {
        closestDistance = distance;
        closestZone = zone;
      }
    }

    if (closestZone != null) {
      // Update access stats
      final updatedZone = closestZone.copyWithAccess();
      await _box!.put(closestZone.id, updatedZone);
      
      return closestZone.speedLimitMph;
    }

    return null;
  }

  /// Store a new speed limit zone in the cache
  /// Returns the stored zone
  static Future<SpeedLimitZone> cacheSpeedLimit(
    double latitude,
    double longitude,
    int speedLimitMph, {
    String roadName = '',
  }) async {
    if (_box == null) await init();

    // Check if we already have a zone nearby (to avoid duplicates)
    final existingZone = await _findZoneNearby(latitude, longitude, _minDistanceBetweenZones);
    
    if (existingZone != null) {
      // Update existing zone with new data if needed
      if (existingZone.speedLimitMph != speedLimitMph) {
        // Speed limit changed at this location - create new zone
        return _createNewZone(latitude, longitude, speedLimitMph, roadName);
      }
      // Just update access stats
      final updated = existingZone.copyWithAccess();
      await _box!.put(existingZone.id, updated);
      return updated;
    }

    return _createNewZone(latitude, longitude, speedLimitMph, roadName);
  }

  /// Create a new zone with unique ID
  static Future<SpeedLimitZone> _createNewZone(
    double latitude,
    double longitude,
    int speedLimitMph,
    String roadName,
  ) async {
    final zone = SpeedLimitZone(
      id: _uuid.v4(),
      latitude: latitude,
      longitude: longitude,
      speedLimitMph: speedLimitMph,
      roadName: roadName,
      firstSeen: DateTime.now(),
      lastAccessed: DateTime.now(),
      accessCount: 1,
    );

    await _box!.put(zone.id, zone);
    return zone;
  }

  /// Find a zone near given coordinates
  static Future<SpeedLimitZone?> _findZoneNearby(
    double latitude,
    double longitude,
    double maxDistance,
  ) async {
    if (_box == null) await init();

    for (final zone in _box!.values) {
      final distance = zone.distanceTo(latitude, longitude);
      if (distance <= maxDistance) {
        return zone;
      }
    }
    return null;
  }

  /// Get all cached zones (for debugging/analytics)
  static List<SpeedLimitZone> getAllZones() {
    if (_box == null) return [];
    return _box!.values.toList();
  }

  /// Get count of cached zones
  static int getZoneCount() {
    if (_box == null) return 0;
    return _box!.length;
  }

  /// Get statistics about the cache
  static Map<String, dynamic> getCacheStats() {
    if (_box == null || _box!.isEmpty) {
      return {
        'zoneCount': 0,
        'mostAccessed': null,
        'oldestZone': null,
        'speedLimitDistribution': {},
      };
    }

    final zones = _box!.values.toList();
    
    // Most accessed zone
    zones.sort((a, b) => b.accessCount.compareTo(a.accessCount));
    final mostAccessed = zones.first;

    // Oldest zone
    zones.sort((a, b) => a.firstSeen.compareTo(b.firstSeen));
    final oldestZone = zones.first;

    // Speed limit distribution
    final distribution = <int, int>{};
    for (final zone in zones) {
      distribution[zone.speedLimitMph] = (distribution[zone.speedLimitMph] ?? 0) + 1;
    }

    return {
      'zoneCount': zones.length,
      'mostAccessed': mostAccessed,
      'oldestZone': oldestZone,
      'speedLimitDistribution': distribution,
    };
  }

  /// Clear old zones that haven't been accessed in a while
  static Future<int> cleanupOldZones({int daysThreshold = 90}) async {
    if (_box == null) await init();

    final now = DateTime.now();
    final threshold = now.subtract(Duration(days: daysThreshold));
    
    final zonesToDelete = <String>[];
    
    for (final zone in _box!.values) {
      if (zone.lastAccessed.isBefore(threshold)) {
        zonesToDelete.add(zone.id);
      }
    }

    for (final id in zonesToDelete) {
      await _box!.delete(id);
    }

    return zonesToDelete.length;
  }

  /// Clear all cached zones
  static Future<void> clearAllZones() async {
    if (_box == null) await init();
    await _box!.clear();
  }

  /// Delete a specific zone by ID
  static Future<void> deleteZone(String id) async {
    if (_box == null) await init();
    await _box!.delete(id);
  }
}
