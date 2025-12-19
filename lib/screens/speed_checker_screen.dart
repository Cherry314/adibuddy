import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class SpeedCheckerScreen extends StatefulWidget {
  const SpeedCheckerScreen({Key? key}) : super(key: key);

  @override
  State<SpeedCheckerScreen> createState() => _SpeedCheckerScreenState();
}

class _SpeedCheckerScreenState extends State<SpeedCheckerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speed Checker'),
        backgroundColor: Colors.purple[400],
      ),
      drawer: const AppDrawer(currentRoute: '/speed-checker'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple[50]!, Colors.white],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.speed,
                  size: 100,
                  color: Colors.purple[300],
                ),
                SizedBox(height: 30),
                Text(
                  'Speed Checker',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[700],
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Coming Soon',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.purple[400],
                  ),
                ),
                SizedBox(height: 40),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    'This feature will help learner drivers practice\nspeed awareness and speedometer reading.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
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
}
