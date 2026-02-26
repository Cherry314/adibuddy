import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/image_selection_screen.dart';
import 'screens/past_tests_screen.dart';
import 'screens/dl25_form_screen.dart';
import 'services/user_image_service.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive database
  await DatabaseService.init();

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
        title: 'ADI Buddy',
        theme: ThemeData(primarySwatch: Colors.purple),
        home: const HomeScreen(),
        routes: {
          '/home': (context) => const HomeScreen(),
          '/lessons': (context) => const ImageSelectionScreen(),
          '/past-tests': (context) => const PastTestsScreen(),
          '/dl25-form': (context) => const DL25FormScreen(),
        },
      ),
    );
  }
}
