import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/test_result.dart';

class EmailService {
  static Future<bool> sendTestSummary(TestResult test,
      {String? alternativeEmail}) async {
    final String emailAddress = alternativeEmail ?? test.candidateEmail;

    // --- THIS IS THE CORRECTED SECTION ---

    // 1. Generate the raw, un-encoded body first.
    final String body = _generateEmailBody(test);

    // 2. Use the Uri constructor. It will handle all the necessary encoding
    //    for the subject and body automatically and safely.
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: emailAddress,
      queryParameters: {
        'subject': 'Driving Test Result - ${test.passed ? "PASS" : "FAIL"}',
        'body': body,
      },
    );

    // --- END OF CORRECTION ---

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        return true; // Success
      } else {
        // This will now give a more accurate reason for failure,
        // e.g., no email client is installed.
        print('Could not launch $emailUri: No email client found or configured.');
        return false;
      }
    } catch (e) {
      print('Error launching email: $e');
      return false;
    }
  }

  static String _generateEmailBody(TestResult test) {
    final StringBuffer body = StringBuffer();
    final dateFormat = DateFormat('dd/MM/yyyy');

    body.writeln('DVSA DRIVING TEST REPORT');
    body.writeln('═══════════════════════════════════════\n');

    body.writeln('CANDIDATE DETAILS');
    body.writeln('─────────────────────────────────────');
    body.writeln('Name: ${test.candidateName}');
    body.writeln('Test Centre: ${test.testCenter}');
    body.writeln('Test Date: ${dateFormat.format(test.testDate)}');
    body.writeln('Test Time: ${test.testTime}\n');

    body.writeln('TEST RESULT');
    body.writeln('─────────────────────────────────────');
    body.writeln('Result: ${test.passed ? "✓ PASS" : "✗ FAIL"}\n');

    body.writeln('FAULT SUMMARY');
    body.writeln('─────────────────────────────────────');
    body.writeln('Driving Faults: ${test.totalDrivingFaults} / 15');
    body.writeln('Serious Faults: ${test.totalSeriousFaults}');
    body.writeln('Dangerous Faults: ${test.totalDangerousFaults}\n');

    if (!test.passed) {
      body.writeln('REASONS FOR FAILURE');
      body.writeln('─────────────────────────────────────');
      if (test.totalDrivingFaults > 15) {
        body.writeln(
            '• Too many driving faults (${test.totalDrivingFaults}/15)');
      }
      if (test.totalSeriousFaults > 0) {
        body.writeln('• ${test.totalSeriousFaults} serious fault(s)');
      }
      if (test.totalDangerousFaults > 0) {
        body.writeln('• ${test.totalDangerousFaults} dangerous fault(s)');
      }
      body.writeln();
    }

    // Detailed faults
    if (test.drivingFaults.isNotEmpty) {
      body.writeln('DRIVING FAULTS (D)');
      body.writeln('─────────────────────────────────────');
      test.drivingFaults.forEach((category, count) {
        if (count > 0) {
          body.writeln('• $category: $count');
        }
      });
      body.writeln();
    }

    if (test.seriousFaults.isNotEmpty) {
      body.writeln('SERIOUS FAULTS (S)');
      body.writeln('─────────────────────────────────────');
      for (var fault in test.seriousFaults) {
        body.writeln('• $fault');
      }
      body.writeln();
    }

    if (test.dangerousFaults.isNotEmpty) {
      body.writeln('DANGEROUS FAULTS (X)');
      body.writeln('─────────────────────────────────────');
      for (var fault in test.dangerousFaults) {
        body.writeln('• $fault');
      }
      body.writeln();
    }

    // Maneuver
    if (test.selectedManeuver != null) {
      body.writeln('MANEUVER');
      body.writeln('─────────────────────────────────────');
      body.writeln('Type: ${test.selectedManeuver}');
      if (test.maneuverControlFaults > 0) {
        body.writeln('Control - Driving Faults: ${test.maneuverControlFaults}');
      }
      if (test.maneuverControlSerious) {
        body.writeln('Control - Serious Fault: Yes');
      }
      if (test.maneuverControlDangerous) {
        body.writeln('Control - Dangerous Fault: Yes');
      }
      if (test.maneuverObservationFaults > 0) {
        body.writeln(
            'Observation - Driving Faults: ${test.maneuverObservationFaults}');
      }
      if (test.maneuverObservationSerious) {
        body.writeln('Observation - Serious Fault: Yes');
      }
      if (test.maneuverObservationDangerous) {
        body.writeln('Observation - Dangerous Fault: Yes');
      }
      body.writeln();
    }

    // Additional information
    body.writeln('ADDITIONAL INFORMATION');
    body.writeln('─────────────────────────────────────');
    if (test.eyesightTestCompleted) {
      body.writeln(
          'Eyesight Test: ${test.eyesightTestFailed ? "Failed" : "Passed"}');
    }
    if (test.showMeTellMeCompleted) {
      body.writeln('Show Me / Tell Me: Completed');
    }
    if (test.controlledStopCompleted) {
      body.writeln('Controlled Stop: Completed');
    }
    if (test.etaCompleted) {
      body.write('ETA: ');
      List<String> etaTypes = [];
      if (test.etaPhysical) etaTypes.add('Physical');
      if (test.etaVerbal) etaTypes.add('Verbal');
      body.writeln(etaTypes.isNotEmpty ? etaTypes.join(', ') : 'Completed');
    }
    if (test.ecoCompleted) {
      body.write('ECO: ');
      List<String> ecoTypes = [];
      if (test.ecoControl) ecoTypes.add('Control');
      if (test.ecoPlanning) ecoTypes.add('Planning');
      body.writeln(ecoTypes.isNotEmpty ? ecoTypes.join(', ') : 'Completed');
    }

    body.writeln('\n═══════════════════════════════════════');
    body.writeln('Report generated by ADI Buddy');
    body.writeln(
        'Generated: ${DateFormat('dd/MM/yyyy HH:mm').format(test.savedAt)}');

    return body.toString();
  }
}
