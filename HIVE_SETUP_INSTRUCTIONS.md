# Hive Setup Instructions

## Important: Generate Hive Adapters

Before running the app, you need to generate the Hive adapters for the TestResult model.

### Steps:

1. Open a terminal in the project root directory
2. Run the following command:

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

This will generate the `lib/models/test_result.g.dart` file which contains the Hive type adapter.

### What this does:

- Installs all dependencies from pubspec.yaml
- Generates the Hive adapter code for the TestResult model
- The `--delete-conflicting-outputs` flag ensures clean generation

### After generation:

Once the adapter is generated, you need to uncomment the adapter registration line in
`lib/services/database_service.dart`:

Find this line (around line 11):

```dart
// Note: Hive adapter will be registered after code generation
// Hive.registerAdapter(TestResultAdapter());
```

And change it to:

```dart
Hive.registerAdapter(TestResultAdapter());
```

Then the app will be ready to run!

## Features Implemented:

1. **Save Test Dialog**: When clicking "Save Test", a dialog shows:
    - Test result (Pass/Fail)
    - Fault summary
    - Option to email the candidate
    - Saves to Hive database

2. **Past Tests Screen**: Shows all saved tests with:
    - Searchable list
    - Statistics (total, passed, failed)
    - Tap to view full test details
    - Delete option

3. **Test Detail Screen**: Full test report showing:
    - All candidate details
    - Complete fault breakdown
    - Maneuver details
    - Additional information
    - Option to re-send email or send to different address

4. **Email Service**: Generates formatted email with:
    - Complete test summary
    - All faults listed
    - Pass/Fail result
    - All test details
