import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../widgets/app_drawer.dart';
import '../services/user_image_service.dart';

class UserImageControlScreen extends StatefulWidget {
  const UserImageControlScreen({Key? key}) : super(key: key);

  @override
  State<UserImageControlScreen> createState() => _UserImageControlScreenState();
}

class _UserImageControlScreenState extends State<UserImageControlScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _newCategoryController = TextEditingController();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  String _selectedCategory = 'User Images';

  @override
  void initState() {
    super.initState();
    // Load user images and categories
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserImageService>(context, listen: false).loadUserImages();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showErrorDialog('Failed to pick image: $e');
    }
  }

  Future<void> _uploadImage() async {
    if (_titleController.text
        .trim()
        .isEmpty) {
      _showErrorDialog('Please enter a title for the image');
      return;
    }

    if (_selectedImage == null) {
      _showErrorDialog('Please select an image');
      return;
    }

    setState(() => _isUploading = true);

    try {
      final userImageService = Provider.of<UserImageService>(
          context, listen: false);

      await userImageService.addUserImage(
        title: _titleController.text.trim(),
        imageFile: _selectedImage!,
        category: _selectedCategory,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        setState(() {
          _titleController.clear();
          _selectedImage = null;
          _selectedCategory = 'User Images';
        });
      }
    } catch (e) {
      _showErrorDialog('Failed to upload image: $e');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showAddCategoryDialog() {
    _newCategoryController.clear();
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Add New Category'),
            content: TextField(
              controller: _newCategoryController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                hintText: 'e.g., My Local Areas, Test Routes',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final categoryName = _newCategoryController.text.trim();
                  if (categoryName.isEmpty) {
                    return;
                  }

                  final userImageService = Provider.of<UserImageService>(
                      context, listen: false);

                  if (userImageService.categories.contains(categoryName)) {
                    Navigator.pop(context);
                    _showErrorDialog('Category "$categoryName" already exists');
                    return;
                  }

                  await userImageService.addCategory(categoryName);

                  if (mounted) {
                    setState(() {
                      _selectedCategory = categoryName;
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Category "$categoryName" added'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[400],
                ),
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  void _showEditImageDialog(UserImageData image) {
    final TextEditingController editTitleController = TextEditingController(
        text: image.title);
    String editCategory = image.category;
    File? newImageFile;

    showDialog(
      context: context,
      builder: (context) =>
          StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Edit Image'),
                content: Consumer<UserImageService>(
                  builder: (context, service, child) {
                    return SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Image preview
                          Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.purple[300]!, width: 2),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: newImageFile != null
                                  ? Image.file(newImageFile!, fit: BoxFit.cover)
                                  : Image.file(
                                  File(image.imagePath), fit: BoxFit.cover),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                final XFile? pickedFile = await _picker
                                    .pickImage(
                                  source: ImageSource.gallery,
                                  imageQuality: 85,
                                );
                                if (pickedFile != null) {
                                  setDialogState(() {
                                    newImageFile = File(pickedFile.path);
                                  });
                                }
                              } catch (e) {
                                _showErrorDialog('Failed to pick image: $e');
                              }
                            },
                            icon: const Icon(Icons.photo_library, size: 18),
                            label: const Text('Change Image'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple[300],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: editTitleController,
                            decoration: const InputDecoration(
                              labelText: 'Title',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: editCategory,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(),
                            ),
                            items: service.categories
                                .map((cat) =>
                                DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat),
                                ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() {
                                  editCategory = value;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final newTitle = editTitleController.text.trim();
                      if (newTitle.isEmpty) {
                        return;
                      }

                      final userImageService = Provider.of<UserImageService>(
                          context, listen: false);

                      // Update using the new update method
                      await userImageService.updateUserImage(
                        id: image.id,
                        newTitle: newTitle,
                        newCategory: editCategory,
                        newImageFile: newImageFile,
                      );

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Image updated successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[400],
                    ),
                    child: const Text('Save'),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _showDeleteConfirmation(UserImageData image) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Delete Image'),
            content: Text('Are you sure you want to delete "${image
                .title}"? This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final userImageService = Provider.of<UserImageService>(
                      context, listen: false);
                  await userImageService.deleteUserImage(image.id);

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Image deleted successfully'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _showDeleteCategoryDialog(String category, int imageCount) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Delete Category'),
            content: Text(
              'Delete category "$category"?\n\n'
                  '$imageCount image(s) will be moved to "User Images" category.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final userImageService = Provider.of<UserImageService>(
                      context, listen: false);
                  await userImageService.deleteCategory(category);

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Category "$category" deleted'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Images'),
        backgroundColor: Colors.purple[400],
      ),
      drawer: const AppDrawer(currentRoute: '/upload-images'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple[50]!, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ===== UPLOAD SECTION =====
              Icon(
                Icons.upload_file,
                size: 60,
                color: Colors.purple[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Upload New Image',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[700],
                ),
              ),
              const SizedBox(height: 24),

              // Image Preview
              if (_selectedImage != null)
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple[300]!, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[400]!,
                        width: 2,
                        strokeAlign: BorderSide.strokeAlignInside),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image, size: 60, color: Colors.grey[400]),
                      const SizedBox(height: 10),
                      Text(
                        'No image selected',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Select Image Button
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _pickImage,
                icon: const Icon(Icons.photo_library),
                label: Text(
                    _selectedImage == null ? 'Select Image' : 'Change Image'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[400],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Title Input
              TextField(
                controller: _titleController,
                enabled: !_isUploading,
                decoration: InputDecoration(
                  labelText: 'Image Title',
                  hintText: 'Enter a title for your image',
                  prefixIcon: Icon(Icons.title, color: Colors.purple[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: Colors.purple[400]!, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Category Selection
              Consumer<UserImageService>(
                builder: (context, userImageService, child) {
                  return Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            prefixIcon: Icon(
                                Icons.folder, color: Colors.purple[400]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: Colors.purple[400]!, width: 2),
                            ),
                          ),
                          items: userImageService.categories
                              .map((category) =>
                              DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ))
                              .toList(),
                          onChanged: _isUploading ? null : (value) {
                            if (value != null) {
                              setState(() => _selectedCategory = value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: _isUploading ? null : _showAddCategoryDialog,
                        icon: const Icon(Icons.add_circle),
                        color: Colors.purple[400],
                        iconSize: 32,
                        tooltip: 'Add New Category',
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // Upload Button
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadImage,
                icon: _isUploading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Icon(Icons.cloud_upload),
                label: Text(_isUploading ? 'Uploading...' : 'Upload Image'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 40),
              const Divider(thickness: 2),
              const SizedBox(height: 20),

              // ===== MANAGE IMAGES SECTION =====
              Row(
                children: [
                  Icon(
                      Icons.photo_library, color: Colors.purple[700], size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Your Images',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Consumer<UserImageService>(
                builder: (context, userImageService, child) {
                  if (!userImageService.hasUserImages) {
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(Icons.photo_library_outlined, size: 64,
                                color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No images yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Upload your first image above!',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Group images by category
                  final imagesByCategory = userImageService
                      .getUserImagesByCategory();

                  return Column(
                    children: userImageService.categories.map((category) {
                      final imagesInCategory = userImageService.userImages
                          .where((img) => img.category == category)
                          .toList();

                      if (imagesInCategory.isEmpty) return const SizedBox
                          .shrink();

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ExpansionTile(
                          leading: Icon(
                              Icons.folder, color: Colors.purple[600]),
                          title: Text(
                            category,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text('${imagesInCategory.length} image(s)'),
                          trailing: category != 'User Images'
                              ? IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            color: Colors.orange[700],
                            onPressed: () =>
                                _showDeleteCategoryDialog(
                                  category,
                                  imagesInCategory.length,
                                ),
                            tooltip: 'Delete Category',
                          )
                              : null,
                          children: imagesInCategory.map((image) {
                            return ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(image.imagePath),
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey[300],
                                      child: Icon(Icons.broken_image,
                                          color: Colors.grey[600]),
                                    );
                                  },
                                ),
                              ),
                              title: Text(image.title),
                              subtitle: Text(
                                'Added: ${image.createdAt.toString().split(
                                    '.')[0]}',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600]),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    color: Colors.purple[600],
                                    onPressed: () =>
                                        _showEditImageDialog(image),
                                    tooltip: 'Edit',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20),
                                    color: Colors.red[600],
                                    onPressed: () =>
                                        _showDeleteConfirmation(image),
                                    tooltip: 'Delete',
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
