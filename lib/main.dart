import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/image_selection_screen.dart';
import 'services/user_image_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserImageService(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Driving Tutor',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const ImageSelectionScreen(),
      ),
    );
  }
}
