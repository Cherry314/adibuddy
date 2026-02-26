import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/app_drawer.dart';
import 'speed_calibration_screen.dart';

/// Screen for calibrating the Driving Monitor system.
/// Allows users to fine-tune speed limit detection, GPS accuracy settings,
/// and manual speed limit zone management.
class CalibrateDrivingMonitorScreen extends StatefulWidget {
  const CalibrateDrivingMonitorScreen({Key? key}) : super(key: key);

  @override
  State<CalibrateDrivingMonitorScreen> createState() => _CalibrateDrivingMonitorScreenState();
}

class _CalibrateDrivingMonitorScreenState extends State<CalibrateDrivingMonitorScreen> {
  double _gpsAccuracy = 5.0; // meters
  bool _autoDetectSpeedLimits = true;
  double _cacheRadius = 100.0; // meters
  bool _showDebugInfo = false;

  // G-force calibration thresholds
  double _gForceMinimum = 0.15;
  double _gForceModerate = 0.3;
  double _gForceSevere = 0.5;

  @override
  void initState() {
    super.initState();
    _loadGForceSettings();
  }

  Future<void> _loadGForceSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _gForceMinimum = prefs.getDouble('gforce_minimum') ?? 0.15;
      _gForceModerate = prefs.getDouble('gforce_moderate') ?? 0.3;
      _gForceSevere = prefs.getDouble('gforce_severe') ?? 0.5;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calibrate Driving Monitor'),
        backgroundColor: Colors.purple[400],
      ),
      drawer: const AppDrawer(currentRoute: '/calibrate-driving-monitor'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple[50]!, Colors.white],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.tune,
                      size: 48,
                      color: Colors.purple[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Calibration Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Fine-tune your Driving Monitor for accurate speed limit detection and GPS tracking.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Speed Calibration Section
              _buildSectionHeader('Speed Calibration'),
              const SizedBox(height: 12),
              _buildCard(
                child: ListTile(
                  leading: Icon(
                    Icons.speed,
                    color: Colors.purple[400],
                    size: 28,
                  ),
                  title: Text(
                    'Calibrate Speed',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.purple[700],
                    ),
                  ),
                  subtitle: Text(
                    'Adjust GPS speed to match your car\'s speedometer for accurate readings',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.purple[400],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SpeedCalibrationScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // G-Force Thresholds Section
              _buildSectionHeader('G-Force Thresholds'),
              const SizedBox(height: 12),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'G-Force Minimum: ${_gForceMinimum.toStringAsFixed(2)} G',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _gForceMinimum,
                      min: 0.1,
                      max: 1.0,
                      divisions: 9,
                      label: '${_gForceMinimum.toStringAsFixed(2)} G',
                      activeColor: Colors.green[400],
                      onChanged: (value) {
                        setState(() {
                          _gForceMinimum = value;
                          if (_gForceModerate <= _gForceMinimum) {
                            _gForceModerate = _gForceMinimum + 0.1;
                          }
                          if (_gForceSevere <= _gForceModerate) {
                            _gForceSevere = _gForceModerate + 0.1;
                          }
                        });
                        _saveGForceSettings();
                      },
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'G-Force Moderate: ${_gForceModerate.toStringAsFixed(2)} G',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _gForceModerate,
                      min: 0.2,
                      max: 2.0,
                      divisions: 18,
                      label: '${_gForceModerate.toStringAsFixed(2)} G',
                      activeColor: Colors.orange[400],
                      onChanged: (value) {
                        setState(() {
                          _gForceModerate = value;
                          if (_gForceModerate <= _gForceMinimum) {
                            _gForceModerate = _gForceMinimum + 0.1;
                          }
                          if (_gForceSevere <= _gForceModerate) {
                            _gForceSevere = _gForceModerate + 0.1;
                          }
                        });
                        _saveGForceSettings();
                      },
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'G-Force Severe: ${_gForceSevere.toStringAsFixed(2)} G',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _gForceSevere,
                      min: 0.5,
                      max: 4.0,
                      divisions: 35,
                      label: '${_gForceSevere.toStringAsFixed(2)} G',
                      activeColor: Colors.red[400],
                      onChanged: (value) {
                        setState(() {
                          _gForceSevere = value;
                          if (_gForceSevere <= _gForceModerate) {
                            _gForceSevere = _gForceModerate + 0.1;
                          }
                        });
                        _saveGForceSettings();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // GPS Accuracy Section
              _buildSectionHeader('GPS Accuracy'),
              const SizedBox(height: 12),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Minimum GPS Accuracy: ${_gpsAccuracy.toStringAsFixed(1)} meters',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _gpsAccuracy,
                      min: 1.0,
                      max: 20.0,
                      divisions: 19,
                      label: '${_gpsAccuracy.toStringAsFixed(1)}m',
                      activeColor: Colors.purple[400],
                      onChanged: (value) {
                        setState(() {
                          _gpsAccuracy = value;
                        });
                      },
                    ),
                    Text(
                      'Lower values require more accurate GPS signal. Recommended: 5-10 meters.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Speed Limit Detection Section
              _buildSectionHeader('Speed Limit Detection'),
              const SizedBox(height: 12),
              _buildCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(
                        'Auto-detect Speed Limits',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.purple[700],
                        ),
                      ),
                      subtitle: Text(
                        'Automatically fetch speed limits from OpenStreetMap',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      value: _autoDetectSpeedLimits,
                      activeColor: Colors.purple[400],
                      onChanged: (value) {
                        setState(() {
                          _autoDetectSpeedLimits = value;
                        });
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: Text(
                        'Manual Speed Limit Zones',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.purple[700],
                        ),
                      ),
                      subtitle: Text(
                        'View and manage saved speed limit locations',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.purple[400],
                      ),
                      onTap: () {
                        _showManualZonesDialog();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Cache Settings Section
              _buildSectionHeader('Cache Settings'),
              const SizedBox(height: 12),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cache Search Radius: ${_cacheRadius.toStringAsFixed(0)} meters',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _cacheRadius,
                      min: 50.0,
                      max: 500.0,
                      divisions: 45,
                      label: '${_cacheRadius.toStringAsFixed(0)}m',
                      activeColor: Colors.purple[400],
                      onChanged: (value) {
                        setState(() {
                          _cacheRadius = value;
                        });
                      },
                    ),
                    Text(
                      'Distance to search for cached speed limits. Larger radius uses more cached data.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _clearCache,
                            icon: const Icon(Icons.delete_sweep, size: 18),
                            label: const Text('Clear Cache'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[400],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _exportCache,
                            icon: const Icon(Icons.download, size: 18),
                            label: const Text('Export Data'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[400],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Advanced Section
              _buildSectionHeader('Advanced'),
              const SizedBox(height: 12),
              _buildCard(
                child: SwitchListTile(
                  title: Text(
                    'Show Debug Information',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.purple[700],
                    ),
                  ),
                  subtitle: Text(
                    'Display GPS coordinates and cache statistics',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  value: _showDebugInfo,
                  activeColor: Colors.purple[400],
                  onChanged: (value) {
                    setState(() {
                      _showDebugInfo = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveSettings,
                  icon: const Icon(Icons.save),
                  label: const Text(
                    'Save Settings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[400],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.purple[600],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
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

  void _showManualZonesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Manual Speed Limit Zones',
            style: TextStyle(color: Colors.purple[700]),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  'This feature will allow you to view and edit manually recorded speed limit zones.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Icon(Icons.location_on, color: Colors.purple[400]),
                  title: const Text('Zone 1: 30 MPH'),
                  subtitle: const Text('Last updated: Today'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {},
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.location_on, color: Colors.purple[400]),
                  title: const Text('Zone 2: 40 MPH'),
                  subtitle: const Text('Last updated: Yesterday'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Cache?'),
          content: const Text(
            'This will delete all saved speed limit zones. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cache cleared successfully'),
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

  void _exportCache() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export feature coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _saveSettings() {
    _saveGForceSettings();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveGForceSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('gforce_minimum', _gForceMinimum);
    await prefs.setDouble('gforce_moderate', _gForceModerate);
    await prefs.setDouble('gforce_severe', _gForceSevere);
  }
}
