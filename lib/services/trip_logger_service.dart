import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/trip_data_point.dart';

/// Service for logging trip data with 1-second sampling
/// Stores data in-memory only - cleared when app closes or new trip starts
class TripLoggerService {
  // In-memory storage
  final List<TripDataPoint> _tripData = [];
  Timer? _loggingTimer;
  
  // Current state for next data point
  DateTime? _tripStartTime;
  LatLng? _currentPosition;
  double _currentSpeedMph = 0.0;
  double _currentGForceLateral = 0.0;
  double _currentGForceLongitudinal = 0.0;
  int? _currentSpeedLimit;
  
  // Thresholds for event detection
  double _harshBrakingThreshold = 0.5;
  double _harshAccelerationThreshold = 0.4;
  double _sharpTurnThreshold = 0.4;
  
  // Stream controller for real-time updates
  final _dataController = StreamController<TripDataPoint>.broadcast();
  Stream<TripDataPoint> get dataStream => _dataController.stream;
  
  /// Check if logging is active
  bool get isLogging => _loggingTimer != null && _loggingTimer!.isActive;
  
  /// Get all recorded data points
  List<TripDataPoint> get tripData => List.unmodifiable(_tripData);
  
  /// Get trip duration
  Duration? get tripDuration {
    if (_tripStartTime == null) return null;
    return DateTime.now().difference(_tripStartTime!);
  }
  
  /// Get count of data points
  int get dataPointCount => _tripData.length;
  
  /// Get count of events
  int get eventCount => _tripData.where((p) => p.hasEvent).length;
  
  /// Start logging with 1-second intervals
  void startLogging() {
    if (isLogging) return;
    
    _tripData.clear();
    _tripStartTime = DateTime.now();
    
    // Log first point immediately
    _logDataPoint();
    
    // Then every second
    _loggingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _logDataPoint();
    });
    
    debugPrint('TripLogger: Started logging at ${_tripStartTime!.toIso8601String()}');
  }
  
  /// Stop logging
  void stopLogging() {
    _loggingTimer?.cancel();
    _loggingTimer = null;
    
    debugPrint('TripLogger: Stopped logging. ${_tripData.length} points recorded, $eventCount events');
  }
  
  /// Clear all data (called when starting new trip)
  void clearData() {
    _tripData.clear();
    _tripStartTime = null;
    debugPrint('TripLogger: Data cleared');
  }
  
  /// Update current GPS position
  void updatePosition(double latitude, double longitude) {
    _currentPosition = LatLng(latitude, longitude);
  }
  
  /// Update current speed
  void updateSpeed(double speedMph) {
    _currentSpeedMph = speedMph;
  }
  
  /// Update G-forces
  void updateGForces(double lateral, double longitudinal) {
    _currentGForceLateral = lateral;
    _currentGForceLongitudinal = longitudinal;
  }
  
  /// Update speed limit
  void updateSpeedLimit(int? speedLimit) {
    _currentSpeedLimit = speedLimit;
  }
  
  /// Update thresholds (optional - can load from settings)
  void updateThresholds({
    double? harshBraking,
    double? harshAcceleration,
    double? sharpTurn,
  }) {
    _harshBrakingThreshold = harshBraking ?? _harshBrakingThreshold;
    _harshAccelerationThreshold = harshAcceleration ?? _harshAccelerationThreshold;
    _sharpTurnThreshold = sharpTurn ?? _sharpTurnThreshold;
  }
  
  /// Log a single data point with current state
  void _logDataPoint() {
    // Skip if we don't have position yet
    if (_currentPosition == null) {
      debugPrint('TripLogger: Skipping point - no position available');
      return;
    }
    
    // Detect events
    final bool harshBraking = _currentGForceLongitudinal > _harshBrakingThreshold;
    final bool harshAcceleration = _currentGForceLongitudinal < -_harshAccelerationThreshold;
    final bool sharpTurn = _currentGForceLateral.abs() > _sharpTurnThreshold;
    final bool exceededSpeedLimit = _currentSpeedLimit != null && 
                                    _currentSpeedMph > _currentSpeedLimit! * 1.1; // 10% over
    
    final dataPoint = TripDataPoint(
      timestamp: DateTime.now(),
      position: _currentPosition!,
      speedMph: _currentSpeedMph,
      gForceLateral: _currentGForceLateral,
      gForceLongitudinal: _currentGForceLongitudinal,
      harshBraking: harshBraking,
      harshAcceleration: harshAcceleration,
      sharpTurn: sharpTurn,
      exceededSpeedLimit: exceededSpeedLimit,
      speedLimitMph: _currentSpeedLimit,
    );
    
    _tripData.add(dataPoint);
    _dataController.add(dataPoint);
    
    // Debug output for events
    if (dataPoint.hasEvent) {
      debugPrint('TripLogger: EVENT at ${dataPoint.timestamp} - ${dataPoint.eventDescription} '
          '(G: ${_currentGForceLongitudinal.toStringAsFixed(2)}, ${_currentGForceLateral.toStringAsFixed(2)})');
    }
  }
  
  /// Get summary statistics
  Map<String, dynamic> getTripSummary() {
    if (_tripData.isEmpty) {
      return {'message': 'No data recorded'};
    }
    
    final maxSpeed = _tripData.map((p) => p.speedMph).reduce((a, b) => a > b ? a : b);
    final avgSpeed = _tripData.map((p) => p.speedMph).reduce((a, b) => a + b) / _tripData.length;
    final maxLateralG = _tripData.map((p) => p.gForceLateral).reduce((a, b) => a.abs() > b.abs() ? a : b);
    final maxLongitudinalG = _tripData.map((p) => p.gForceLongitudinal).reduce((a, b) => a.abs() > b.abs() ? a : b);
    
    return {
      'duration': tripDuration?.inMinutes ?? 0,
      'dataPoints': _tripData.length,
      'events': eventCount,
      'maxSpeed': maxSpeed.toStringAsFixed(1),
      'avgSpeed': avgSpeed.toStringAsFixed(1),
      'maxLateralG': maxLateralG.toStringAsFixed(2),
      'maxLongitudinalG': maxLongitudinalG.toStringAsFixed(2),
      'harshBrakingEvents': _tripData.where((p) => p.harshBraking).length,
      'harshAccelerationEvents': _tripData.where((p) => p.harshAcceleration).length,
      'sharpTurnEvents': _tripData.where((p) => p.sharpTurn).length,
      'speedLimitExceedances': _tripData.where((p) => p.exceededSpeedLimit).length,
    };
  }
  
  /// Get data points with events only (for map display)
  List<TripDataPoint> getEventPoints() {
    return _tripData.where((p) => p.hasEvent).toList();
  }
  
  /// Dispose resources
  void dispose() {
    stopLogging();
    _dataController.close();
  }
}
