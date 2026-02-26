import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../widgets/app_drawer.dart';
import '../services/speed_limit_service.dart';
import '../services/speed_limit_cache_service.dart';
import '../services/trip_logger_service.dart';
import 'trip_map_screen.dart';

class SpeedCheckerScreen extends StatefulWidget {
  const SpeedCheckerScreen({super.key});

  @override
  State<SpeedCheckerScreen> createState() => _SpeedCheckerScreenState();
}

class _SpeedCheckerScreenState extends State<SpeedCheckerScreen> {
  StreamSubscription<Position>? _positionStreamSubscription;
  double _currentSpeedMps = 0.0; // Speed in meters per second
  double _currentSpeedMph = 0.0; // Speed in miles per hour
  int _currentSpeedRounded = 0;
  bool _isTracking = false;
  String _statusMessage = 'Tap Start to begin tracking';
  Color _statusColor = Colors.purple;
  int _maxSpeedMph = 0;
  double _averageSpeedMph = 0.0;
  int _speedReadings = 0;
  double _totalSpeedMph = 0.0;

  // Speed limit tracking
  int? _speedLimitMph;
  String _speedLimitStatus = 'Unknown';
  int _warningLevel = 0; // 0 = none, 1 = mild (up to 10%), 2 = severe (>10%)
  DateTime? _lastSpeedLimitFetch;
  Timer? _speedLimitTimer;

  // Manual speed limit selection
  bool _isManualSpeedLimit = false;

  // Speed calibration
  double _speedCalibrationOffset = 0.0;
  double _speedCalibrationMultiplier = 1.0;

  // Accelerometer for G-force detection
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  double _gForceLeft = 0.0;
  double _gForceRight = 0.0;
  double _gForceForward = 0.0;
  double _gForceBackward = 0.0;

  // G-force thresholds (in Gs) - loaded from settings
  double _mildThreshold = 0.15;
  double _moderateThreshold = 0.3;
  double _severeThreshold = 0.5;

  // Warning flash animation
  bool _showWarningFlash = false;
  Timer? _warningFlashTimer;

  // Trip logger for recording journey data
  final TripLoggerService _tripLogger = TripLoggerService();

  // Speed display colors based on speed ranges
  Color get _speedColor {
    if (_currentSpeedMph == 0) return Colors.grey;
    if (_currentSpeedMph <= 30) return Colors.green;
    if (_currentSpeedMph <= 60) return Colors.orange;
    return Colors.red;
  }

  // Get display color based on warning level
  Color get _displayColor {
    if (_warningLevel == 2) return Colors.red;
    if (_warningLevel == 1) return Colors.orange;
    return _speedColor;
  }

  Future<void> _startTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Load calibration data first
    await _loadCalibrationData();
    await _loadGForceSettings();

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _statusMessage = 'Please enable GPS/Location services';
        _statusColor = Colors.red;
      });
      return;
    }

    // Check location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _statusMessage = 'Location permissions denied';
          _statusColor = Colors.red;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _statusMessage = 'Location permissions permanently denied. Please enable in settings.';
        _statusColor = Colors.red;
      });
      return;
    }

    // Start listening to position updates
    setState(() {
      _isTracking = true;
      _statusMessage = 'Tracking active - GPS speed in MPH';
      _statusColor = Colors.green;
      _maxSpeedMph = 0;
      _averageSpeedMph = 0.0;
      _speedReadings = 0;
      _totalSpeedMph = 0.0;
      _speedLimitMph = null;
      _speedLimitStatus = 'Fetching...';
      _warningLevel = 0;
    });

    // Start trip logger
    _tripLogger.clearData();
    _tripLogger.startLogging();

    // Start speed limit timer (fetch every 10 seconds)
    _speedLimitTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchSpeedLimit();
    });

    // Initial fetch
    _fetchSpeedLimit();

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0, // Update on every position change
      ),
    ).listen(
      (Position position) {
        setState(() {
          _currentSpeedMps = position.speed; // Speed in m/s
          // Convert to MPH: 1 m/s = 2.23694 mph
          final rawSpeedMph = _currentSpeedMps * 2.23694;
          // Apply calibration: Corrected = (GPS - offset) / multiplier
          _currentSpeedMph = (rawSpeedMph - _speedCalibrationOffset) / _speedCalibrationMultiplier;
          _currentSpeedRounded = _currentSpeedMph.round();

          // Update trip logger with position and speed
          _tripLogger.updatePosition(position.latitude, position.longitude);
          _tripLogger.updateSpeed(_currentSpeedMph);

          // Update statistics (only count when moving)
          if (_currentSpeedMph > 0.5) {
            _speedReadings++;
            _totalSpeedMph += _currentSpeedMph;
            _averageSpeedMph = _totalSpeedMph / _speedReadings;

            if (_currentSpeedRounded > _maxSpeedMph) {
              _maxSpeedMph = _currentSpeedRounded;
            }
          }

          // Check warning level
          _updateWarningLevel();
        });
      },
      onError: (error) {
        setState(() {
          _statusMessage = 'GPS Error: $error';
          _statusColor = Colors.red;
          _isTracking = false;
        });
      },
    );

    // Start accelerometer for G-force detection
    _startAccelerometer();
  }

  void _startAccelerometer() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        // Phone is VERTICAL and facing driver/passenger
        // X: left/right (positive = left turn, negative = right turn)
        // Y: up/down (gravity when vertical, ~9.81 m/s²)
        // Z: forward/backward (positive = braking, negative = acceleration)
        
        const double g = 9.81;
        
        // Left/Right G-force (X axis) - lateral movement
        final lateralG = event.x / g;
        
        // Forward/Backward G-force (Z axis) - subtract small gravity component if any
        // When phone is vertical, Z is perpendicular to gravity
        final longitudinalG = event.z / g;
        
        setState(() {
          _gForceLeft = lateralG > 0.05 ? lateralG.abs() : 0;
          _gForceRight = lateralG < -0.05 ? lateralG.abs() : 0;
          _gForceForward = longitudinalG < -0.05 ? longitudinalG.abs() : 0; // Acceleration (negative Z)
          _gForceBackward = longitudinalG > 0.05 ? longitudinalG.abs() : 0; // Braking (positive Z)
        });
        
        // Update trip logger with G-forces
        _tripLogger.updateGForces(lateralG, longitudinalG);
        
        // Debug output
        debugPrint('Accel: x=${event.x.toStringAsFixed(2)}, y=${event.y.toStringAsFixed(2)}, z=${event.z.toStringAsFixed(2)} | G: L=${_gForceLeft.toStringAsFixed(2)} R=${_gForceRight.toStringAsFixed(2)} F=${_gForceForward.toStringAsFixed(2)} B=${_gForceBackward.toStringAsFixed(2)}');
      },
      onError: (error) {
        debugPrint('Accelerometer error: $error');
      },
    );
  }

  Future<void> _fetchSpeedLimit() async {
    if (!_isTracking) return;

    try {
      final position = await Geolocator.getCurrentPosition();
      final speedLimit = await SpeedLimitService.getSpeedLimit(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        setState(() {
          // Only update if we don't have a manual override, or if API returns a different value
          if (_isManualSpeedLimit && speedLimit != null && speedLimit != _speedLimitMph) {
            // API found a different speed limit than manual - update to API value
            _speedLimitMph = speedLimit;
            _speedLimitStatus = '$speedLimit MPH';
            _isManualSpeedLimit = false;
          } else if (!_isManualSpeedLimit) {
            // No manual override, use API/cache value
            _speedLimitMph = speedLimit;
            if (speedLimit != null) {
              _speedLimitStatus = '$speedLimit MPH';
            } else {
              _speedLimitStatus = 'Unknown';
            }
          }
          // Update trip logger with speed limit
          _tripLogger.updateSpeedLimit(_speedLimitMph);
          _lastSpeedLimitFetch = DateTime.now();
          _updateWarningLevel();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (!_isManualSpeedLimit) {
            _speedLimitStatus = 'Error';
          }
        });
      }
    }
  }

  void _updateWarningLevel() {
    final newWarningLevel = SpeedLimitService.getWarningLevel(
      _currentSpeedRounded,
      _speedLimitMph,
    );

    // If warning level increased, trigger flash
    if (newWarningLevel > _warningLevel && newWarningLevel > 0) {
      _triggerWarningFlash();
    }

    _warningLevel = newWarningLevel;
  }

  void _triggerWarningFlash() {
    _warningFlashTimer?.cancel();
    _showWarningFlash = true;

    // Flash warning 3 times
    int flashCount = 0;
    _warningFlashTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      flashCount++;
      if (mounted) {
        setState(() {
          _showWarningFlash = flashCount % 2 == 1;
        });
      }
      if (flashCount >= 6) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _showWarningFlash = false;
          });
        }
      }
    });
  }

  /// Load speed calibration data from SharedPreferences
  Future<void> _loadCalibrationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _speedCalibrationOffset = prefs.getDouble('speed_calibration_offset') ?? 0.0;
        _speedCalibrationMultiplier = prefs.getDouble('speed_calibration_multiplier') ?? 1.0;
      });
    } catch (e) {
      // If loading fails, use default values (no calibration)
      _speedCalibrationOffset = 0.0;
      _speedCalibrationMultiplier = 1.0;
    }
  }

  /// Load G-force settings from SharedPreferences
  Future<void> _loadGForceSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _mildThreshold = prefs.getDouble('gforce_minimum') ?? 0.15;
        _moderateThreshold = prefs.getDouble('gforce_moderate') ?? 0.3;
        _severeThreshold = prefs.getDouble('gforce_severe') ?? 0.5;
      });
    } catch (e) {
      _mildThreshold = 0.15;
      _moderateThreshold = 0.3;
      _severeThreshold = 0.5;
    }
  }

  void _stopTracking() {
    _positionStreamSubscription?.cancel();
    _speedLimitTimer?.cancel();
    _warningFlashTimer?.cancel();
    _accelerometerSubscription?.cancel();
    
    // Stop trip logging
    _tripLogger.stopLogging();
    
    setState(() {
      _isTracking = false;
      _statusMessage = 'Tracking stopped. Tap Start to resume.';
      _statusColor = Colors.orange;
      _currentSpeedMps = 0.0;
      _currentSpeedMph = 0.0;
      _currentSpeedRounded = 0;
      _speedLimitMph = null;
      _speedLimitStatus = 'Unknown';
      _warningLevel = 0;
      _showWarningFlash = false;
      _isManualSpeedLimit = false;
      _gForceLeft = 0.0;
      _gForceRight = 0.0;
      _gForceForward = 0.0;
      _gForceBackward = 0.0;
    });
  }

  /// Manually set the speed limit when user taps a speed limit button
  Future<void> _setManualSpeedLimit(int speedLimit) async {
    if (!_isTracking) return;

    try {
      final position = await Geolocator.getCurrentPosition();

      // Cache this speed limit at the current location
      await SpeedLimitCacheService.cacheSpeedLimit(
        position.latitude,
        position.longitude,
        speedLimit,
        roadName: 'Manual',
      );

      if (mounted) {
        setState(() {
          _speedLimitMph = speedLimit;
          _speedLimitStatus = '$speedLimit MPH (Manual)';
          _isManualSpeedLimit = true;
          _tripLogger.updateSpeedLimit(speedLimit);
          _lastSpeedLimitFetch = DateTime.now();
          _updateWarningLevel();
        });

        // Show brief confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Speed limit set to $speedLimit MPH'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green[600],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set speed limit: $e'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _speedLimitTimer?.cancel();
    _warningFlashTimer?.cancel();
    _accelerometerSubscription?.cancel();
    _tripLogger.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speed Monitor'),
        backgroundColor: Colors.purple[400],
      ),
      drawer: const AppDrawer(currentRoute: '/speed-checker'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple[50]!, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                // Speed Limit Display - Always visible
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: _speedLimitMph != null && _isTracking
                        ? (_isManualSpeedLimit
                            ? Colors.orange.withOpacity(0.15)
                            : const Color(0xFF4CAF50).withOpacity(0.1))
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _speedLimitMph != null && _isTracking
                          ? (_isManualSpeedLimit
                              ? Colors.orange.withOpacity(0.5)
                              : const Color(0xFF4CAF50).withOpacity(0.3))
                          : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isTracking && _isManualSpeedLimit ? Icons.edit_road : Icons.speed,
                        color: _speedLimitMph != null && _isTracking
                            ? (_isManualSpeedLimit ? Colors.orange : const Color(0xFF4CAF50))
                            : Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isTracking ? 'Speed Limit: $_speedLimitStatus' : 'Speed Limit: Waiting',
                        style: TextStyle(
                          color: _speedLimitMph != null && _isTracking
                              ? (_isManualSpeedLimit ? Colors.orange[800] : const Color(0xFF2E7D32))
                              : Colors.grey[600],
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Main Speed Display with G-Force Arc Brackets
                SizedBox(
                  width: 320,
                  height: 320,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Main Speed Circle (drawn first, at bottom)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _showWarningFlash
                                  ? (_warningLevel == 2 ? Colors.red[100]! : Colors.orange[100]!)
                                  : Colors.white,
                              _showWarningFlash
                                  ? (_warningLevel == 2 ? Colors.red[200]! : Colors.orange[200]!)
                                  : Colors.grey[100]!,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _displayColor.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          border: _warningLevel > 0
                              ? Border.all(
                                  color: _displayColor.withOpacity(0.5),
                                  width: 4,
                                )
                              : null,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Warning icon for severe warning
                              if (_warningLevel == 2 && !_showWarningFlash)
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.red,
                                  size: 28,
                                ),
                              if (_warningLevel == 2 && !_showWarningFlash)
                                const SizedBox(height: 6),

                              // Speed value
                              Text(
                                _currentSpeedRounded.toString(),
                                style: TextStyle(
                                  fontSize: 80,
                                  fontWeight: FontWeight.bold,
                                  color: _displayColor,
                                  height: 1,
                                ),
                              ),
                              // Unit label
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _displayColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  'MPH',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: _displayColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Arcs drawn ON TOP of circle (after circle in Stack)
                      // Left arc bracket (for right turn G-force) - positioned outside the circle
                      Positioned(
                        left: 10,
                        top: 80,
                        bottom: 80,
                        child: _buildGForceArc(
                          gForce: _gForceRight,
                          position: ArcPosition.left,
                        ),
                      ),
                      // Right arc bracket (for left turn G-force) - positioned outside the circle
                      Positioned(
                        right: 10,
                        top: 80,
                        bottom: 80,
                        child: _buildGForceArc(
                          gForce: _gForceLeft,
                          position: ArcPosition.right,
                        ),
                      ),
                      // Top arc bracket (for deceleration/braking) - positioned outside the circle
                      Positioned(
                        top: 10,
                        left: 80,
                        right: 80,
                        child: _buildGForceArc(
                          gForce: _gForceBackward,
                          position: ArcPosition.top,
                        ),
                      ),
                      // Bottom arc bracket (for acceleration) - positioned outside the circle
                      Positioned(
                        bottom: 10,
                        left: 80,
                        right: 80,
                        child: _buildGForceArc(
                          gForce: _gForceForward,
                          position: ArcPosition.bottom,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                const Spacer(),

                // Manual Speed Limit Buttons Grid (only shown when tracking) - Above Start/Stop button
                if (_isTracking) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.edit_road,
                              size: 16,
                              color: Colors.purple[600],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Set Speed Limit',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Speed limit buttons grid - 3x2 stretched horizontally
                        Row(
                          children: [
                            Expanded(child: _buildSpeedLimitButton(20)),
                            const SizedBox(width: 6),
                            Expanded(child: _buildSpeedLimitButton(30)),
                            const SizedBox(width: 6),
                            Expanded(child: _buildSpeedLimitButton(40)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(child: _buildSpeedLimitButton(50)),
                            const SizedBox(width: 6),
                            Expanded(child: _buildSpeedLimitButton(60)),
                            const SizedBox(width: 6),
                            Expanded(child: _buildSpeedLimitButton(70)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Start/Stop button and Map button row
                Row(
                  children: [
                    // Start/Stop button (2/3 width - approximately 67%)
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 36,
                        child: ElevatedButton.icon(
                          onPressed: _isTracking ? _stopTracking : _startTracking,
                          icon: Icon(
                            _isTracking ? Icons.stop : Icons.play_arrow,
                            size: 22,
                          ),
                          label: Text(
                            _isTracking ? 'Stop Tracking' : 'Start Tracking',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isTracking ? Colors.red[400] : Colors.purple[400],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Map button (1/3 width - approximately 33%)
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          onPressed: _tripLogger.dataPointCount > 0
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TripMapScreen(tripLogger: _tripLogger),
                                    ),
                                  );
                                }
                              : null,
                          child: const Text(
                            'Map',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[400],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            disabledBackgroundColor: Colors.grey[300],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build a speed limit button with the given speed value
  Widget _buildSpeedLimitButton(int speedLimit) {
    final isSelected = _speedLimitMph == speedLimit && _isManualSpeedLimit;

    return GestureDetector(
      onTap: () => _setManualSpeedLimit(speedLimit),
      child: Container(
        width: 78,
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? [Colors.orange[400]!, Colors.orange[600]!]
                : [Colors.purple[300]!, Colors.purple[500]!],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: (isSelected ? Colors.orange : Colors.purple).withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
          border: isSelected
              ? Border.all(color: Colors.orange[800]!, width: 3)
              : null,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$speedLimit',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                'MPH',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a G-force arc indicator with color-coded thresholds
  Widget _buildGForceArc({
    required double gForce,
    required ArcPosition position,
  }) {
    // Determine color based on G-force magnitude
    Color arcColor;
    double opacity;
    double strokeWidth;
    
    if (gForce >= _severeThreshold) {
      arcColor = Colors.red;
      opacity = 0.9;
      strokeWidth = 10;
    } else if (gForce >= _moderateThreshold) {
      arcColor = Colors.orange;
      opacity = 0.8;
      strokeWidth = 10;
    } else if (gForce >= _mildThreshold) {
      arcColor = Colors.white;
      opacity = 0.7;
      strokeWidth = 10;
    } else {
      // No movement detected - show green
      arcColor = Colors.green;
      opacity = 0.5;
      strokeWidth = 10;
    }

    // Calculate size based on G-force intensity
    final double sizeMultiplier = 1.0 + (gForce * 0.3).clamp(0.0, 0.3);

    double width;
    double height;
    
    switch (position) {
      case ArcPosition.left:
      case ArcPosition.right:
        width = 20 * sizeMultiplier;
        height = 100 * sizeMultiplier;
        break;
      case ArcPosition.top:
      case ArcPosition.bottom:
        width = 100 * sizeMultiplier;
        height = 20 * sizeMultiplier;
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      width: width,
      height: height,
      child: CustomPaint(
        size: Size(width, height),
        painter: ArcPainter(
          color: arcColor.withOpacity(opacity),
          strokeWidth: strokeWidth,
          position: position,
        ),
      ),
    );
  }
}

/// Enum for arc positions
enum ArcPosition { left, right, top, bottom }

/// Painter for G-force arc brackets
class ArcPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final ArcPosition position;

  ArcPainter({
    required this.color,
    required this.strokeWidth,
    required this.position,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    switch (position) {
      case ArcPosition.left:
        // Left side arc - curves outward to the left
        path.moveTo(size.width, size.height * 0.2);
        path.quadraticBezierTo(
          0, size.height * 0.5,
          size.width, size.height * 0.8,
        );
        break;
      case ArcPosition.right:
        // Right side arc - curves outward to the right
        path.moveTo(0, size.height * 0.2);
        path.quadraticBezierTo(
          size.width, size.height * 0.5,
          0, size.height * 0.8,
        );
        break;
      case ArcPosition.top:
        // Top arc - curves upward (toward y=0)
        path.moveTo(size.width * 0.2, size.height);
        path.quadraticBezierTo(
          size.width * 0.5, 0,
          size.width * 0.8, size.height,
        );
        break;
      case ArcPosition.bottom:
        // Bottom arc - curves downward (toward y=size.height)
        path.moveTo(size.width * 0.2, 0);
        path.quadraticBezierTo(
          size.width * 0.5, size.height,
          size.width * 0.8, 0,
        );
        break;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
