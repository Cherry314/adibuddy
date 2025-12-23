// import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../widgets/app_drawer.dart';
import '../services/user_image_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  double _imageQuality = 80;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.purple[400],
      ),
      drawer: const AppDrawer(currentRoute: '/settings'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple[50]!, Colors.white],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            _buildSectionTitle('General'),
            _buildSettingsCard(
              children: [
                SwitchListTile(
                  title: Text('Notifications'),
                  subtitle: Text('Enable push notifications'),
                  value: _notificationsEnabled,
                  activeTrackColor: Colors.purple[400],
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                  },
                ),
                Divider(height: 1),
                SwitchListTile(
                  title: Text('Dark Mode'),
                  subtitle: Text('Use dark theme'),
                  value: _darkModeEnabled,
                  activeTrackColor: Colors.purple[400],
                  onChanged: (value) {
                    setState(() => _darkModeEnabled = value);
                  },
                ),
              ],
            ),
            SizedBox(height: 24),
            _buildSectionTitle('Image Settings'),
            _buildSettingsCard(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Image Quality: ${_imageQuality.toInt()}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Slider(
                        value: _imageQuality,
                        min: 50,
                        max: 100,
                        divisions: 10,
                        activeColor: Colors.purple[400],
                        label: '${_imageQuality.toInt()}%',
                        onChanged: (value) {
                          setState(() => _imageQuality = value);
                        },
                      ),
                      Text(
                        'Higher quality uses more storage',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            _buildSectionTitle('ackup & Restore'),
            _buildSettingsCard(
              children: [
                ListTile(
                  title: Text('Backup Data'),
                  subtitle: Text('Export your images and categories'),
                  leading: Icon(Icons.backup, color: Colors.purple[700]),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _exportBackup,
                ),
                Divider(height: 1),
                ListTile(
                  title: Text('Restore Data'),
                  subtitle: Text('Import from backup file'),
                  leading: Icon(Icons.restore, color: Colors.purple[700]),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _restoreBackup,
                ),
                Divider(height: 1),
                Consumer<UserImageService>(
                  builder: (context, service, child) {
                    final stats = service.getStatistics();
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Data',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.purple[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Images: ${stats['totalImages']}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            'Categories: ${stats['totalCategories']}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                ),
              ],
            ),
            SizedBox(height: 24),
            _buildSectionTitle('About'),
            _buildSettingsCard(
              children: [
                ListTile(
                  title: Text('Version'),
                  trailing: Text(
                    '1.0.0',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                Divider(height: 1),
                ListTile(
                  title: Text('Terms of Service'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // TODO: Navigate to Terms of Service
                  },
                ),
                Divider(height: 1),
                ListTile(
                  title: Text('Privacy Policy'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // TODO: Navigate to Privacy Policy
                  },
                ),
                Divider(height: 1),
                ListTile(
                  title: Text('Licenses'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    showLicensePage(context: context);
                  },
                ),
              ],
            ),
            SizedBox(height: 24),
            _buildSettingsCard(
              children: [
                ListTile(
                  title: Text(
                    'Clear Cache',
                    style: TextStyle(color: Colors.orange[700]),
                  ),
                  leading: Icon(
                      Icons.cleaning_services, color: Colors.orange[700]),
                  onTap: () {
                    _showClearCacheDialog();
                  },
                ),
              ],
            ),
            SizedBox(height: 40),
            Center(
              child: Text(
                'Made with ❤️ for Driving Instructors',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.purple[700],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Future<void> _exportBackup() async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.purple[400]),
                      SizedBox(height: 16),
                      Text('Creating backup...'),
                    ],
                  ),
                ),
              ),
            ),
      );

      final userImageService = Provider.of<UserImageService>(
          context, listen: false);
      final String backupPath = await userImageService.exportBackup();

      Navigator.pop(context); // Close loading dialog

      // Share the backup file
      await Share.shareXFiles(
        [XFile(backupPath)],
        subject: 'AdiBuddy Backup',
        text: 'My AdiBuddy backup file - ${DateTime.now().toString().split(
            '.')[0]}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup created and ready to share'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading if still open
      _showErrorDialog('Backup failed', 'Error: $e');
    }
  }

  Future<void> _restoreBackup() async {
    // Show restore options
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text('Restore Backup'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Choose how to restore:'),
                SizedBox(height: 16),
                Text(
                  'Merge: Keep existing data and add backup data',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                SizedBox(height: 8),
                Text(
                  'Replace: Delete existing data and use only backup',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _pickAndRestoreBackup(merge: true);
                },
                child: Text('Merge'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showReplaceConfirmation();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                ),
                child: Text('Replace'),
              ),
            ],
          ),
    );
  }

  void _showReplaceConfirmation() {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text('⚠️ Warning'),
            content: Text(
              'This will DELETE all your existing images and categories, and replace them with the backup. This cannot be undone.\n\nAre you sure?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _pickAndRestoreBackup(merge: false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                ),
                child: Text('Yes, Replace All'),
              ),
            ],
          ),
    );
  }

  Future<void> _pickAndRestoreBackup({required bool merge}) async {
    try {
      // Pick backup file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result == null) return;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.purple[400]),
                      SizedBox(height: 16),
                      Text('Restoring backup...'),
                    ],
                  ),
                ),
              ),
            ),
      );

      final userImageService = Provider.of<UserImageService>(
          context, listen: false);
      final bool success = await userImageService.restoreBackup(
        result.files.single.path!,
        mergeDuplicates: merge,
      );

      Navigator.pop(context); // Close loading dialog

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Backup restored successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          _showErrorDialog(
              'Restore failed', 'The backup file may be corrupted or invalid.');
        }
      }
    } catch (e) {
      Navigator.pop(context); // Close loading if still open
      _showErrorDialog('Restore failed', 'Error: $e');
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text('Clear Cache'),
            content: Text(
                'Are you sure you want to clear the cache? This will free up storage space.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Cache cleared successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[400],
                ),
                child: Text('Clear'),
              ),
            ],
          ),
    );
  }
}
