import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'speed_limit_cache_service.dart';

class SpeedLimitService {
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';

  /// Fetches the speed limit for the given GPS coordinates.
  /// First checks local cache, then falls back to Overpass API.
  /// Returns speed limit in MPH, or null if not found.
  static Future<int?> getSpeedLimit(
    double latitude,
    double longitude, {
    bool useCache = true,
  }) async {
    // Step 1: Check local cache first
    if (useCache) {
      try {
        final cachedLimit = await SpeedLimitCacheService.getCachedSpeedLimit(
          latitude,
          longitude,
        );
        if (cachedLimit != null) {
          print('Speed limit found in cache: $cachedLimit MPH');
          return cachedLimit;
        }
      } catch (e) {
        print('Cache lookup error: $e');
      }
    }

    // Step 2: Fetch from Overpass API
    final speedLimit = await _fetchFromOverpass(latitude, longitude);
    
    // Step 3: Store in cache for future use
    if (speedLimit != null && useCache) {
      try {
        await SpeedLimitCacheService.cacheSpeedLimit(
          latitude,
          longitude,
          speedLimit,
        );
        print('Cached speed limit: $speedLimit MPH at $latitude, $longitude');
      } catch (e) {
        print('Cache storage error: $e');
      }
    }

    return speedLimit;
  }

  /// Force refresh from Overpass API, bypassing cache
  static Future<int?> forceRefresh(double latitude, double longitude) async {
    return _fetchFromOverpass(latitude, longitude);
  }

  /// Fetches the speed limit from OpenStreetMap Overpass API
  static Future<int?> _fetchFromOverpass(double latitude, double longitude) async {
    try {
      // Overpass API query to find roads with maxspeed tag near the coordinates
      // We search within a 50-meter radius around the current position
      final query = '''
        [out:json];
        way[maxspeed](around:50.0,$latitude,$longitude);
        out tags;
      ''';

      final response = await http.post(
        Uri.parse(_overpassUrl),
        body: {'data': query},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List<dynamic>?;

        if (elements == null || elements.isEmpty) {
          return null;
        }

        // Parse speed limits from the results
        final speeds = <int>[];

        for (final element in elements) {
          final tags = element['tags'] as Map<String, dynamic>?;
          if (tags != null && tags.containsKey('maxspeed')) {
            final maxspeed = tags['maxspeed'] as String;
            final speed = _parseSpeed(maxspeed);
            if (speed != null) {
              speeds.add(speed);
            }
          }
        }

        if (speeds.isEmpty) {
          return null;
        }

        // Return the lowest speed limit found (most conservative approach)
        return speeds.reduce((a, b) => a < b ? a : b);
      } else {
        throw Exception('Failed to fetch speed limit: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching speed limit from Overpass: $e');
      return null;
    }
  }

  /// Parses a speed string from OSM (e.g., "30 mph", "50", "60 km/h") to MPH
  static int? _parseSpeed(String speedString) {
    speedString = speedString.trim().toLowerCase();

    // Handle "mph" suffix
    if (speedString.contains('mph')) {
      final numeric = speedString.replaceAll(RegExp(r'[^0-9]'), '');
      return int.tryParse(numeric);
    }

    // Handle "km/h" suffix - convert to MPH
    if (speedString.contains('km/h') || speedString.contains('kmh')) {
      final numeric = speedString.replaceAll(RegExp(r'[^0-9]'), '');
      final kmh = int.tryParse(numeric);
      if (kmh != null) {
        // Convert km/h to mph: 1 km/h = 0.621371 mph
        return (kmh * 0.621371).round();
      }
    }

    // Try plain number (assume mph by default, or could be km/h in some regions)
    // For UK/Europe we should be careful, but let's assume mph for now
    return int.tryParse(speedString);
  }

  /// Get warning level based on current speed vs speed limit
  /// Returns: 0 = no warning, 1 = mild warning (up to 10% over), 2 = severe warning (>10% over)
  static int getWarningLevel(int currentSpeedMph, int? speedLimitMph) {
    if (speedLimitMph == null || speedLimitMph <= 0) {
      return 0; // No speed limit data available
    }

    if (currentSpeedMph <= speedLimitMph) {
      return 0; // Within limit
    }

    final overSpeedPercent = ((currentSpeedMph - speedLimitMph) / speedLimitMph) * 100;

    if (overSpeedPercent <= 10) {
      return 1; // Mild warning - up to 10% over
    } else {
      return 2; // Severe warning - more than 10% over
    }
  }

  /// Get warning color based on warning level
  static Color getWarningColor(int warningLevel) {
    switch (warningLevel) {
      case 0:
        return const Color(0xFF4CAF50); // Green - OK
      case 1:
        return const Color(0xFFFF9800); // Orange - Mild warning
      case 2:
        return const Color(0xFFF44336); // Red - Severe warning
      default:
        return const Color(0xFF4CAF50);
    }
  }

  /// Get warning message based on warning level
  static String getWarningMessage(int warningLevel, int? speedLimit) {
    switch (warningLevel) {
      case 0:
        if (speedLimit != null) {
          return 'Within speed limit';
        }
        return 'Speed limit data unavailable';
      case 1:
        return 'Slightly over limit - Slow down';
      case 2:
        return '⚠️ SPEEDING! Reduce speed now!';
      default:
        return '';
    }
  }
}
