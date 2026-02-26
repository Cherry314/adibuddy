import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/app_drawer.dart';
import '../services/speed_limit_service.dart';
import '../services/speed_limit_cache_service.dart';

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

  // Warning flash animation
  bool _showWarningFlash = false;
  Timer? _warningFlashTimer;

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
          _currentSpeedMph = _currentSpeedMps * 2.23694;
          _currentSpeedRounded = _currentSpeedMph.round();
          
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

  void _stopTracking() {
    _positionStreamSubscription?.cancel();
    _speedLimitTimer?.cancel();
    _warningFlashTimer?.cancel();
    
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

  void _showStatsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Speed Statistics',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          content: Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(
                  'Max Speed',
                  '$_maxSpeedMph',
                  'MPH',
                  Icons.trending_up,
                  Colors.purple,
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: Colors.grey[300],
                ),
                _buildStatItem(
                  'Average',
                  '${_averageSpeedMph.round()}',
                  'MPH',
                  Icons.speed,
                  Colors.blue,
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: Colors.grey[300],
                ),
                _buildStatItem(
                  'Readings',
                  '$_speedReadings',
                  'updates',
                  Icons.update,
                  Colors.teal,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _speedLimitTimer?.cancel();
    _warningFlashTimer?.cancel();
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
                
                // Main Speed Display with Warning
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

                // Start/Stop button and Stats button row
                Row(
                  children: [
                    // Start/Stop button (3/4 width)
                    Expanded(
                      flex: 3,
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
                    // Stats button (1/4 width)
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 36,
                        child: ElevatedButton.icon(
                          onPressed: _showStatsDialog,
                          icon: const Icon(
                            Icons.bar_chart,
                            size: 20,
                          ),
                          label: const Text(
                            '',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[400],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
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

  Widget _buildStatItem(String label, String value, String unit, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
}
