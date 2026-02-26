import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import 'image_selection_screen.dart';
import 'speed_checker_screen.dart';
import 'user_image_control_screen.dart';
import 'dl25_form_screen.dart';
import 'past_tests_screen.dart';
import 'settings_screen.dart';
import 'calibrate_driving_monitor_screen.dart';
import 'speed_calibration_screen.dart';

/// Home screen with ADI BUDDY header and menu tiles
/// Serves as the main landing page for the app
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Colors.purple[400],
      ),
      drawer: const AppDrawer(currentRoute: '/home'),
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
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ADI BUDDY Header Box
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple[400]!, Colors.purple[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.drive_eta,
                        size: 64,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'ADI BUDDY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Driving Instructor Tools',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Main Menu Tiles Section
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main Features Section
                        _buildSectionTitle('Main Features'),
                        const SizedBox(height: 12),
                        _buildTileRow([
                          _buildMenuTile(
                            context: context,
                            icon: Icons.school,
                            title: 'Lesson\nImages',
                            color: Colors.blue,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ImageSelectionScreen()),
                            ),
                          ),
                          _buildMenuTile(
                            context: context,
                            icon: Icons.speed,
                            title: 'Driving\nMonitor',
                            color: Colors.green,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => SpeedCheckerScreen()),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 12),
                        _buildTileRow([
                          _buildMenuTile(
                            context: context,
                            icon: Icons.photo_library,
                            title: 'Manage\nImages',
                            color: Colors.orange,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const UserImageControlScreen()),
                            ),
                          ),
                          _buildMenuTile(
                            context: context,
                            icon: Icons.description,
                            title: 'DL25\nTest Report',
                            color: Colors.purple,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const DL25FormScreen()),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 12),
                        _buildTileRow([
                          _buildMenuTile(
                            context: context,
                            icon: Icons.history,
                            title: 'Past\nTests',
                            color: Colors.teal,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PastTestsScreen()),
                            ),
                          ),
                          _buildMenuTile(
                            context: context,
                            icon: Icons.settings,
                            title: 'Settings',
                            color: Colors.grey[700]!,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SettingsScreen()),
                            ),
                          ),
                        ]),

                        const SizedBox(height: 24),

                        // Divider with text
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.purple[200], thickness: 1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'CALIBRATION',
                                style: TextStyle(
                                  color: Colors.purple[400],
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.purple[200], thickness: 1)),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Calibration Section
                        _buildTileRow([
                          _buildMenuTile(
                            context: context,
                            icon: Icons.tune,
                            title: 'Calibrate\nDriving Monitor',
                            color: Colors.indigo,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CalibrateDrivingMonitorScreen()),
                            ),
                          ),
                          _buildMenuTile(
                            context: context,
                            icon: Icons.speed,
                            title: 'Calibrate\nSpeed',
                            color: Colors.deepOrange,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SpeedCalibrationScreen()),
                            ),
                          ),
                        ]),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.purple[600],
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildTileRow(List<Widget> children) {
    return Row(
      children: [
        Expanded(child: children[0]),
        const SizedBox(width: 12),
        Expanded(child: children[1]),
      ],
    );
  }

  Widget _buildMenuTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
