import 'package:latlong2/latlong.dart';

/// A single data point recorded during a trip
/// Contains GPS position, speed, G-forces, and event flags
class TripDataPoint {
  final DateTime timestamp;
  final LatLng position;
  final double speedMph;
  final double gForceLateral;
  final double gForceLongitudinal;

  // Event flags (computed in real-time)
  final bool exceededSpeedLimit;
  final bool harshBraking;
  final bool harshAcceleration;
  final bool sharpTurn;

  // Optional: store the speed limit at this point
  final int? speedLimitMph;

  TripDataPoint({
    required this.timestamp,
    required this.position,
    required this.speedMph,
    required this.gForceLateral,
    required this.gForceLongitudinal,
    this.exceededSpeedLimit = false,
    this.harshBraking = false,
    this.harshAcceleration = false,
    this.sharpTurn = false,
    this.speedLimitMph,
  });

  /// Get the total G-force magnitude
  double get totalGForce {
    return (gForceLateral * gForceLateral + gForceLongitudinal * gForceLongitudinal);
  }

  /// Check if any event occurred at this point
  bool get hasEvent {
    return exceededSpeedLimit || harshBraking || harshAcceleration || sharpTurn;
  }

  /// Get a description of the event for display
  String get eventDescription {
    if (harshBraking) return 'Harsh Braking';
    if (harshAcceleration) return 'Harsh Acceleration';
    if (sharpTurn) return 'Sharp Turn';
    if (exceededSpeedLimit) return 'Speed Limit Exceeded';
    return 'Normal';
  }

  /// Get color for map marker based on event type
  String get eventColor {
    if (harshBraking) return 'red';
    if (harshAcceleration) return 'orange';
    if (sharpTurn) return 'purple';
    if (exceededSpeedLimit) return 'blue';
    return 'green';
  }
}
