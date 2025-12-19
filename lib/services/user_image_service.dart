import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import '../models/image_group.dart';

class UserImageData {
  final String id;
  final String title;
  final String imagePath;
  final String category;
  final DateTime createdAt;

  UserImageData({
    required this.id,
    required this.title,
    required this.imagePath,
    required this.category,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() =>
      {
        'id': id,
        'title': title,
        'imagePath': imagePath,
        'category': category,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserImageData.fromJson(Map<String, dynamic> json) =>
      UserImageData(
        id: json['id'],
        title: json['title'],
        imagePath: json['imagePath'],
        category: json['category'] ?? 'User Images',
        // Default for old data
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class UserImageService extends ChangeNotifier {
  static const String _storageKey = 'user_images';
  static const String _categoriesKey = 'user_categories';

  List<UserImageData> _userImages = [];
  List<String> _customCategories = ['User Images']; // Default category

  List<UserImageData> get userImages => _userImages;

  List<String> get categories => _customCategories;

  Future<void> loadUserImages() async {
    final prefs = await SharedPreferences.getInstance();

    // Load images
    final String? imagesJson = prefs.getString(_storageKey);
    if (imagesJson != null) {
      final List<dynamic> decoded = json.decode(imagesJson);
      _userImages =
          decoded.map((item) => UserImageData.fromJson(item)).toList();
    }

    // Load custom categories
    final String? categoriesJson = prefs.getString(_categoriesKey);
    if (categoriesJson != null) {
      final List<dynamic> decoded = json.decode(categoriesJson);
      _customCategories = decoded.cast<String>();

      // Ensure 'User Images' is always present
      if (!_customCategories.contains('User Images')) {
        _customCategories.insert(0, 'User Images');
      }
    }

    notifyListeners();
  }

  Future<void> _saveUserImages() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(
        _userImages.map((img) => img.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
    notifyListeners();
  }

  Future<void> _saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(_customCategories);
    await prefs.setString(_categoriesKey, encoded);
    notifyListeners();
  }

  Future<String> _saveImageToAppDirectory(File imageFile) async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String userImagesDir = '${appDir.path}/user_images';

    // Create user_images directory if it doesn't exist
    final Directory dir = Directory(userImagesDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final String fileName = '${DateTime
        .now()
        .millisecondsSinceEpoch}.jpg';
    final String newPath = '$userImagesDir/$fileName';

    // Copy the file to app directory
    await imageFile.copy(newPath);

    return newPath;
  }

  Future<void> addCategory(String categoryName) async {
    final trimmedName = categoryName.trim();
    if (trimmedName.isEmpty || _customCategories.contains(trimmedName)) {
      return; // Don't add empty or duplicate categories
    }

    _customCategories.add(trimmedName);
    await _saveCategories();
  }

  Future<void> deleteCategory(String categoryName) async {
    if (categoryName == 'User Images') {
      return; // Cannot delete the default category
    }

    _customCategories.remove(categoryName);

    // Move images from deleted category to 'User Images'
    for (var image in _userImages) {
      if (image.category == categoryName) {
        final updatedImage = UserImageData(
          id: image.id,
          title: image.title,
          imagePath: image.imagePath,
          category: 'User Images',
          createdAt: image.createdAt,
        );

        final index = _userImages.indexWhere((img) => img.id == image.id);
        if (index != -1) {
          _userImages[index] = updatedImage;
        }
      }
    }

    await _saveCategories();
    await _saveUserImages();
  }

  Future<void> addUserImage({
    required String title,
    required File imageFile,
    required String category,
  }) async {
    // Save the image to permanent storage
    final String savedPath = await _saveImageToAppDirectory(imageFile);

    final newImage = UserImageData(
      id: DateTime
          .now()
          .millisecondsSinceEpoch
          .toString(),
      title: title,
      imagePath: savedPath,
      category: category,
      createdAt: DateTime.now(),
    );

    _userImages.add(newImage);
    await _saveUserImages();
  }

  Future<void> updateUserImage({
    required String id,
    String? newTitle,
    String? newCategory,
    File? newImageFile,
  }) async {
    final index = _userImages.indexWhere((img) => img.id == id);
    if (index == -1) return;

    final oldImage = _userImages[index];
    String imagePath = oldImage.imagePath;

    // If new image file provided, save it and delete old one
    if (newImageFile != null) {
      imagePath = await _saveImageToAppDirectory(newImageFile);

      // Delete old image file
      final oldFile = File(oldImage.imagePath);
      if (await oldFile.exists()) {
        await oldFile.delete();
      }
    }

    // Create updated image data
    final updatedImage = UserImageData(
      id: oldImage.id,
      title: newTitle ?? oldImage.title,
      imagePath: imagePath,
      category: newCategory ?? oldImage.category,
      createdAt: oldImage.createdAt,
    );

    _userImages[index] = updatedImage;
    await _saveUserImages();
  }

  Future<void> deleteUserImage(String id) async {
    final imageToDelete = _userImages.firstWhere((img) => img.id == id);

    // Delete the physical file
    final file = File(imageToDelete.imagePath);
    if (await file.exists()) {
      await file.delete();
    }

    _userImages.removeWhere((img) => img.id == id);
    await _saveUserImages();
  }

  // Get images grouped by category
  Map<String, List<ImageGroup>> getUserImagesByCategory() {
    final Map<String, List<ImageGroup>> groupedImages = {};

    for (var category in _customCategories) {
      final imagesInCategory = _userImages
          .where((img) => img.category == category)
          .map((userImage) =>
          ImageGroup(
            title: userImage.title,
            baseImage: userImage.imagePath,
            overlays: [],
          ))
          .toList();

      if (imagesInCategory.isNotEmpty) {
        groupedImages[category] = imagesInCategory;
      }
    }

    return groupedImages;
  }

  bool get hasUserImages => _userImages.isNotEmpty;

  int getImageCountForCategory(String category) {
    return _userImages
        .where((img) => img.category == category)
        .length;
  }

  /// Export all user images and metadata to a ZIP file
  /// Returns the path to the created backup file
  Future<String> exportBackup() async {
    final Directory tempDir = await getTemporaryDirectory();
    final String timestamp = DateTime
        .now()
        .millisecondsSinceEpoch
        .toString();
    final String backupDir = '${tempDir.path}/adibuddy_backup_$timestamp';
    final Directory backupDirectory = Directory(backupDir);

    // Create backup directory
    await backupDirectory.create(recursive: true);

    // Create metadata JSON file
    final Map<String, dynamic> metadata = {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'categories': _customCategories,
      'images': _userImages.map((img) => img.toJson()).toList(),
    };

    final File metadataFile = File('$backupDir/metadata.json');
    await metadataFile.writeAsString(json.encode(metadata));

    // Copy all image files to backup directory
    final Directory imagesDir = Directory('$backupDir/images');
    await imagesDir.create();

    for (var image in _userImages) {
      final File sourceFile = File(image.imagePath);
      if (await sourceFile.exists()) {
        final String fileName = image.id + '.jpg';
        await sourceFile.copy('${imagesDir.path}/$fileName');
      }
    }

    // Create ZIP file
    final String zipPath = '${tempDir.path}/AdiBuddy_Backup_$timestamp.zip';
    final encoder = ZipFileEncoder();
    encoder.create(zipPath);
    encoder.addDirectory(backupDirectory);
    encoder.close();

    // Clean up temporary directory
    await backupDirectory.delete(recursive: true);

    return zipPath;
  }

  /// Restore from a backup ZIP file
  /// mergeDuplicates: if true, keeps existing data and adds new; if false, replaces all
  Future<bool> restoreBackup(String zipFilePath,
      {bool mergeDuplicates = true}) async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String restoreDir = '${tempDir.path}/adibuddy_restore_${DateTime
          .now()
          .millisecondsSinceEpoch}';
      final Directory restoreDirectory = Directory(restoreDir);

      // Extract ZIP file
      final bytes = File(zipFilePath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        final filename = '$restoreDir/${file.name}';
        if (file.isFile) {
          final data = file.content as List<int>;
          File(filename)
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        } else {
          Directory(filename).createSync(recursive: true);
        }
      }

      // Read metadata
      final metadataFile = File('$restoreDir/metadata.json');
      if (!await metadataFile.exists()) {
        throw Exception('Invalid backup file: metadata.json not found');
      }

      final String metadataContent = await metadataFile.readAsString();
      final Map<String, dynamic> metadata = json.decode(metadataContent);

      // Get app's permanent storage directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String userImagesDir = '${appDir.path}/user_images';
      final Directory permanentImagesDir = Directory(userImagesDir);
      if (!await permanentImagesDir.exists()) {
        await permanentImagesDir.create(recursive: true);
      }

      if (!mergeDuplicates) {
        // Clear existing data
        _userImages.clear();
        _customCategories = ['User Images'];
      }

      // Restore categories
      final List<String> restoredCategories = (metadata['categories'] as List)
          .cast<String>();
      for (var category in restoredCategories) {
        if (!_customCategories.contains(category)) {
          _customCategories.add(category);
        }
      }

      // Restore images
      final List<dynamic> imagesData = metadata['images'];
      final Directory extractedImagesDir = Directory('$restoreDir/images');

      for (var imageData in imagesData) {
        final String imageId = imageData['id'];
        final String oldImagePath = '$restoreDir/images/$imageId.jpg';
        final File oldImageFile = File(oldImagePath);

        if (await oldImageFile.exists()) {
          // Check for duplicates if merging
          if (mergeDuplicates && _userImages.any((img) => img.id == imageId)) {
            continue; // Skip duplicate
          }

          // Copy to permanent storage
          final String newImagePath = '$userImagesDir/${DateTime
              .now()
              .millisecondsSinceEpoch}_$imageId.jpg';
          await oldImageFile.copy(newImagePath);

          // Create UserImageData with new path
          final restoredImage = UserImageData(
            id: imageData['id'],
            title: imageData['title'],
            imagePath: newImagePath,
            category: imageData['category'] ?? 'User Images',
            createdAt: DateTime.parse(imageData['createdAt']),
          );

          _userImages.add(restoredImage);
        }
      }

      // Save to SharedPreferences
      await _saveCategories();
      await _saveUserImages();

      // Clean up
      await restoreDirectory.delete(recursive: true);

      return true;
    } catch (e) {
      debugPrint('Restore failed: $e');
      return false;
    }
  }

  /// Get statistics about current data
  Map<String, dynamic> getStatistics() {
    return {
      'totalImages': _userImages.length,
      'totalCategories': _customCategories.length,
      'categoriesBreakdown': {
        for (var category in _customCategories)
          category: getImageCountForCategory(category)
      },
    };
  }
}
