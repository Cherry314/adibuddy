import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/app_drawer.dart';

/// Screen for calibrating GPS speed against car speedometer.
/// Records calibration points at known speeds to calculate correction factors.
class SpeedCalibrationScreen extends StatefulWidget {
  const SpeedCalibrationScreen({Key? key}) : super(key: key);

  @override
  State<SpeedCalibrationScreen> createState() => _SpeedCalibrationScreenState();
}

class _SpeedCalibrationScreenState extends State<SpeedCalibrationScreen> {
  StreamSubscription<Position>? _positionStreamSubscription;
  double _currentGpsSpeed = 0.0;
  double _currentGpsSpeedMph = 0.0;
  bool _isTracking = false;

  // Calibration points: known car speed -> measured GPS speed
  final Map<double, double> _calibrationPoints = {};
  double? _speedOffset; // Simple linear offset (mph)
  double? _speedMultiplier; // Multiplier factor

  // Target speeds for calibration
  final List<double> _targetSpeeds = [20, 30, 40, 50, 60, 70];

  @override
  void initState() {
    super.initState();
    _loadCalibrationData();
    // Show instructions dialog after screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInstructionsDialog();
    });
  }

  void _showInstructionsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.speed, color: Colors.purple[400]),
              const SizedBox(width: 12),
              Text(
                'Calibrate GPS Speed',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[700],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calibrate your GPS speed to match your car\'s speedometer for accurate readings.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              _buildInstructionStep('1', 'Drive at a steady speed shown on your car\'s speedometer'),
              const SizedBox(height: 8),
              _buildInstructionStep('2', 'Press the matching speed button to record the calibration'),
              const SizedBox(height: 8),
              _buildInstructionStep('3', 'Calibrate at 2 or more speeds for best accuracy'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[400],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.purple[400],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _loadCalibrationData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _speedOffset = prefs.getDouble('speed_calibration_offset') ?? 0.0;
      _speedMultiplier = prefs.getDouble('speed_calibration_multiplier') ?? 1.0;

      // Load saved calibration points
      for (final speed in _targetSpeeds) {
        final savedValue = prefs.getDouble('calibration_point_$speed');
        if (savedValue != null) {
          _calibrationPoints[speed] = savedValue;
        }
      }
    });
  }

  Future<void> _saveCalibrationData() async {
    final prefs = await SharedPreferences.getInstance();

    // Calculate offset and multiplier from calibration points
    if (_calibrationPoints.length >= 2) {
      final sortedPoints = _calibrationPoints.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      // Simple linear regression for offset and multiplier
      double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
      int n = sortedPoints.length;

      for (final point in sortedPoints) {
        sumX += point.key; // Car speed (known)
        sumY += point.value; // GPS speed (measured)
        sumXY += point.key * point.value;
        sumX2 += point.key * point.key;
      }

      // Calculate multiplier (slope) and offset (intercept)
      final denominator = n * sumX2 - sumX * sumX;
      if (denominator != 0) {
        final multiplier = (n * sumXY - sumX * sumY) / denominator;
        final offset = (sumY - multiplier * sumX) / n;

        setState(() {
          _speedMultiplier = multiplier;
          _speedOffset = offset;
        });

        await prefs.setDouble('speed_calibration_multiplier', multiplier);
        await prefs.setDouble('speed_calibration_offset', offset);
      }
    } else if (_calibrationPoints.length == 1) {
      // Single point: just calculate offset
      final entry = _calibrationPoints.entries.first;
      final offset = entry.value - entry.key; // GPS - Car

      setState(() {
        _speedOffset = offset;
        _speedMultiplier = 1.0;
      });

      await prefs.setDouble('speed_calibration_offset', offset);
      await prefs.setDouble('speed_calibration_multiplier', 1.0);
    }

    // Save calibration points
    for (final entry in _calibrationPoints.entries) {
      await prefs.setDouble('calibration_point_${entry.key}', entry.value);
    }
  }

  Future<void> _startTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable GPS/Location services')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions denied')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permissions permanently denied')),
      );
      return;
    }

    setState(() {
      _isTracking = true;
    });

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      ),
    ).listen(
      (Position position) {
        setState(() {
          _currentGpsSpeed = position.speed; // m/s
          _currentGpsSpeedMph = _currentGpsSpeed * 2.23694; // Convert to mph
        });
      },
      onError: (error) {
        setState(() {
          _isTracking = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('GPS Error: $error')),
        );
      },
    );
  }

  void _stopTracking() {
    _positionStreamSubscription?.cancel();
    setState(() {
      _isTracking = false;
      _currentGpsSpeed = 0.0;
      _currentGpsSpeedMph = 0.0;
    });
  }

  void _recordCalibrationPoint(double targetSpeed) {
    if (!_isTracking || _currentGpsSpeedMph < 1.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please start tracking and ensure GPS speed is available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _calibrationPoints[targetSpeed] = _currentGpsSpeedMph;
    });

    _saveCalibrationData();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calibration recorded: Car $targetSpeed MPH = GPS ${_currentGpsSpeedMph.toStringAsFixed(1)} MPH'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _clearCalibration() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Calibration?'),
          content: const Text('This will delete all calibration data and reset to default GPS speed.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('speed_calibration_offset');
                await prefs.remove('speed_calibration_multiplier');
                for (final speed in _targetSpeeds) {
                  await prefs.remove('calibration_point_$speed');
                }
                setState(() {
                  _calibrationPoints.clear();
                  _speedOffset = 0.0;
                  _speedMultiplier = 1.0;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Calibration cleared'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  /// Apply calibration correction to a GPS speed reading
  static double applyCalibration(double gpsSpeedMph) {
    // This will be called from the speed checker screen
    // For now, just return the raw GPS speed
    // The actual calibration values will be loaded from SharedPreferences there
    return gpsSpeedMph;
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speed Calibration'),
        backgroundColor: Colors.purple[400],
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearCalibration,
            tooltip: 'Clear Calibration',
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/speed-calibration'),
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
                // Current GPS Speed Display - Flexible to fill space
                Flexible(
                  flex: 4,
                  child: _buildCard(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Current GPS Speed',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: Text(
                              _currentGpsSpeedMph.toStringAsFixed(1),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _isTracking ? Colors.purple[700] : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          'MPH',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isTracking ? _stopTracking : _startTracking,
                            icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
                            label: Text(_isTracking ? 'Stop GPS' : 'Start GPS'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isTracking ? Colors.red[400] : Colors.purple[400],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Calibration Status - Shows if points exist, otherwise collapsed
                if (_calibrationPoints.isNotEmpty) ...[
                  Flexible(
                    flex: 3,
                    child: _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Calibration Status',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView(
                              shrinkWrap: true,
                              children: _calibrationPoints.entries.map((entry) {
                                final difference = entry.value - entry.key;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${entry.key.toStringAsFixed(0)} MPH',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      Text(
                                        '= ${entry.value.toStringAsFixed(1)}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.purple[600],
                                        ),
                                      ),
                                      Text(
                                        difference > 0 ? '+${difference.toStringAsFixed(1)}' : difference.toStringAsFixed(1),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: difference > 0 ? Colors.red[400] : Colors.green[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          if (_speedOffset != null && _speedMultiplier != null) ...[
                            const Divider(height: 12),
                            Text(
                              'Corrected = (GPS - ${_speedOffset!.toStringAsFixed(1)}) / ${_speedMultiplier!.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Calibration Buttons - Fixed size at bottom
                _buildCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Record Calibration Points',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[700],
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Speed limit buttons grid - 3x2 stretched horizontally
                      Row(
                        children: [
                          Expanded(child: _buildSpeedButton(20)),
                          const SizedBox(width: 6),
                          Expanded(child: _buildSpeedButton(30)),
                          const SizedBox(width: 6),
                          Expanded(child: _buildSpeedButton(40)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(child: _buildSpeedButton(50)),
                          const SizedBox(width: 6),
                          Expanded(child: _buildSpeedButton(60)),
                          const SizedBox(width: 6),
                          Expanded(child: _buildSpeedButton(70)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedButton(double speed) {
    final isCalibrated = _calibrationPoints.containsKey(speed);
    return ElevatedButton(
      onPressed: () => _recordCalibrationPoint(speed),
      style: ElevatedButton.styleFrom(
        backgroundColor: isCalibrated ? Colors.green[400] : Colors.purple[400],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${speed.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'MPH',
            style: TextStyle(
              fontSize: 9,
            ),
          ),
          if (isCalibrated)
            const Icon(
              Icons.check_circle,
              size: 12,
              color: Colors.white70,
            ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
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
      child: child,
    );
  }
}
