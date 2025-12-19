import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class MockTestScreen extends StatefulWidget {
  const MockTestScreen({Key? key}) : super(key: key);

  @override
  State<MockTestScreen> createState() => _MockTestScreenState();
}

class _MockTestScreenState extends State<MockTestScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mock Test'),
        backgroundColor: Colors.purple[400],
      ),
      drawer: const AppDrawer(currentRoute: '/mock-test'),
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
                  Icons.quiz,
                  size: 100,
                  color: Colors.purple[300],
                ),
                SizedBox(height: 30),
                Text(
                  'Mock Test',
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
                  child: Column(
                    children: [
                      Text(
                        'Practice Makes Perfect!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[700],
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Take mock theory tests to prepare your\nlearner drivers for their actual test.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        children: [
                          Chip(
                            label: Text('Theory Questions'),
                            backgroundColor: Colors.purple[100],
                          ),
                          Chip(
                            label: Text('Hazard Perception'),
                            backgroundColor: Colors.purple[100],
                          ),
                          Chip(
                            label: Text('Mock Exams'),
                            backgroundColor: Colors.purple[100],
                          ),
                        ],
                      ),
                    ],
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
