import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'draw_screen.dart';
import 'menu_items.dart';
import '../widgets/app_drawer.dart';
import '../services/user_image_service.dart';
import '../models/image_group.dart';


class ImageSelectionScreen extends StatefulWidget {
  const ImageSelectionScreen({Key? key}) : super(key: key);

  @override
  State<ImageSelectionScreen> createState() => _ImageSelectionScreenState();
}

class _ImageSelectionScreenState extends State<ImageSelectionScreen> {
  @override
  void initState() {
    super.initState();
    // Load user images when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserImageService>(context, listen: false).loadUserImages();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lesson Images'),
        backgroundColor: Colors.purple[400],
      ),
      drawer: const AppDrawer(currentRoute: '/lessons'),

      // ---- BACKGROUND IMAGE ADDED HERE ----
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/displayimages/MainBac.webp'),
            fit: BoxFit.cover,
          ),
        ),

        child: Consumer<UserImageService>(
          builder: (context, userImageService, child) {
            // Create a combined list with user images at the end
            final allSections = Map<String, List<ImageGroup>>.from(sections);

            // Add user image categories (only non-empty ones)
            final userImagesByCategory = userImageService
                .getUserImagesByCategory();
            allSections.addAll(userImagesByCategory);

            return ListView(
              padding: const EdgeInsets.all(12),
              children: allSections.entries.map((entry) {
                final sectionTitle = entry.key;
                final groupsInSection = entry.value;

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.purple[50]?.withValues(alpha: 0.9),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                      unselectedWidgetColor: Colors.purple[400],
                    ),
                    child: ExpansionTile(
                      iconColor: Colors.purple[700],
                      collapsedIconColor: Colors.purple[300],
                      textColor: Colors.purple[900],
                      collapsedTextColor: Colors.purple[700],
                      title: Text(
                        sectionTitle,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      children: groupsInSection.map((group) {
                        return Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Colors.grey, width: 0.3),
                            ),
                          ),
                          child: ListTile(
                            title: Text(
                              group.title,
                              style: const TextStyle(fontSize: 16),
                            ),
                            trailing: const Icon(
                                Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => DrawScreen(group: group)),
                              );
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
