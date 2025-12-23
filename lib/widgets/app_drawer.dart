import 'package:flutter/material.dart';
import '../screens/image_selection_screen.dart';
import '../screens/speed_checker_screen.dart';
import '../screens/user_image_control_screen.dart';
import '../screens/dl25_form_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/past_tests_screen.dart'; // <-- 1. IMPORT THE NEW SCREEN

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({Key? key, required this.currentRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.purple[50],
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple[400]!, Colors.purple[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.drive_eta,
                    size: 48,
                    color: Colors.white,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'AdiBuddy',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Driving Instructor Tools',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.school,
              title: 'Lesson Images',
              route: '/lessons',
              isSelected: currentRoute == '/lessons',
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ImageSelectionScreen()),
                );
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.speed,
              title: 'Speed Checker',
              route: '/speed-checker',
              isSelected: currentRoute == '/speed-checker',
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => SpeedCheckerScreen()),
                );
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.photo_library,
              title: 'Manage Images',
              route: '/upload-images',
              isSelected: currentRoute == '/upload-images',
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const UserImageControlScreen()),
                );
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.description,
              title: 'DL25 Test Report',
              route: '/dl25-form',
              isSelected: currentRoute == '/dl25-form',
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const DL25FormScreen()),
                );
              },
            ),

            // 2. ADD THE NEW "PAST TESTS" ITEM HERE
            _buildDrawerItem(
              context,
              icon: Icons.history, // A history icon is suitable for past tests
              title: 'Past Tests',
              route: '/past-tests', // A new unique route name
              isSelected: currentRoute == '/past-tests',
              onTap: () {
                // Use pushReplacement if it's a main screen, or push for a sub-screen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const PastTestsScreen()),
                );
              },
            ),

            const Divider(thickness: 1, color: Colors.purple), // Use const for better performance

            _buildDrawerItem(
              context,
              icon: Icons.settings,
              title: 'Settings',
              route: '/settings',
              isSelected: currentRoute == '/settings',
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Version 1.0.0', // Example version
                style: TextStyle(
                  color: Colors.purple[300],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), // Use const
      decoration: BoxDecoration(
        color: isSelected ? Colors.purple[100] : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.purple[700] : Colors.purple[400],
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.purple[900] : Colors.purple[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        onTap: onTap,
        shape: RoundedRectangleBorder( // Adds a nice ripple effect shape
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
