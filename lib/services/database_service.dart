import 'package:hive_flutter/hive_flutter.dart';
import '../models/test_result.dart';

class DatabaseService {
  static const String _testResultsBox = 'test_results';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TestResultAdapter());
    await Hive.openBox<TestResult>(_testResultsBox);
  }

  static Box<TestResult> getTestResultsBox() {
    return Hive.box<TestResult>(_testResultsBox);
  }

  static Future<void> saveTestResult(TestResult test) async {
    final box = getTestResultsBox();
    await box.put(test.id, test);
  }

  static TestResult? getTestResult(String id) {
    final box = getTestResultsBox();
    return box.get(id);
  }

  static List<TestResult> getAllTestResults() {
    final box = getTestResultsBox();
    return box.values.toList();
  }

  static List<TestResult> getTestResultsSortedByDate() {
    final tests = getAllTestResults();
    tests.sort((a, b) => b.testDate.compareTo(a.testDate));
    return tests;
  }

  static Future<void> deleteTestResult(String id) async {
    final box = getTestResultsBox();
    await box.delete(id);
  }

  static Future<void> updateTestResult(TestResult test) async {
    await saveTestResult(test);
  }
}
