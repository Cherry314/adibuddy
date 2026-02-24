import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/test_result.dart';

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/test_result.dart';

class PdfService {
  static Future<void> generateAndSharePdf(TestResult test) async {
    try {
      final pdf = pw.Document();
      final dateFormat = DateFormat('dd/MM/yyyy');

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'DVSA DRIVING TEST REPORT',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 24, vertical: 8),
                        decoration: pw.BoxDecoration(
                          color: test.passed
                              ? PdfColors.green
                              : PdfColors.red,
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Text(
                          test.passed ? 'PASS' : 'FAIL',
                          style: pw.TextStyle(
                            fontSize: 36,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Candidate Details
                _buildSectionHeader('CANDIDATE DETAILS'),
                pw.SizedBox(height: 8),
                _buildInfoRow('Name', test.candidateName),
                _buildInfoRow('Email', test.candidateEmail),
                _buildInfoRow('Test Centre', test.testCenter),
                _buildInfoRow(
                    'Test Date', dateFormat.format(test.testDate)),
                _buildInfoRow('Test Time', test.testTime),
                pw.SizedBox(height: 16),

                // Fault Summary
                _buildSectionHeader('FAULT SUMMARY'),
                pw.SizedBox(height: 8),
                _buildFaultSummaryBox(test),
                pw.SizedBox(height: 16),

                // Reasons for Failure
                if (!test.passed) ...[
                  _buildSectionHeader('REASONS FOR FAILURE'),
                  pw.SizedBox(height: 8),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (test.totalDrivingFaults > 15)
                        pw.Text(
                            '- Too many driving faults (${test.totalDrivingFaults}/15)'),
                      if (test.totalSeriousFaults > 0)
                        pw.Text(
                            '- ${test.totalSeriousFaults} serious fault(s)'),
                      if (test.totalDangerousFaults > 0)
                        pw.Text(
                            '- ${test.totalDangerousFaults} dangerous fault(s)'),
                      if (test.eyesightTestFailed)
                        pw.Text('- Failed eyesight test'),
                    ],
                  ),
                  pw.SizedBox(height: 16),
                ],

                // Detailed Faults
                if (test.drivingFaults.isNotEmpty) ...[
                  _buildSectionHeader('DRIVING FAULTS (F)'),
                  pw.SizedBox(height: 8),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: test.drivingFaults.entries
                        .where((e) => e.value > 0)
                        .map((e) => pw.Text('- ${e.key}: ${e.value}'))
                        .toList(),
                  ),
                  pw.SizedBox(height: 16),
                ],

                if (test.seriousFaults.isNotEmpty) ...[
                  _buildSectionHeader('SERIOUS FAULTS (S)'),
                  pw.SizedBox(height: 8),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: test.seriousFaults
                        .map((f) => pw.Text('- $f'))
                        .toList(),
                  ),
                  pw.SizedBox(height: 16),
                ],

                if (test.dangerousFaults.isNotEmpty) ...[
                  _buildSectionHeader('DANGEROUS FAULTS (D)'),
                  pw.SizedBox(height: 8),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: test.dangerousFaults
                        .map((f) => pw.Text('- $f'))
                        .toList(),
                  ),
                  pw.SizedBox(height: 16),
                ],

                // Maneuver Details
                if (test.selectedManeuver != null) ...[
                  _buildSectionHeader('MANEUVER'),
                  pw.SizedBox(height: 8),
                  _buildInfoRow('Type', test.selectedManeuver!),
                  if (test.maneuverControlFaults > 0)
                    _buildInfoRow('Control - Faults',
                        test.maneuverControlFaults.toString()),
                  if (test.maneuverControlSerious)
                    _buildInfoRow('Control - Serious', 'Yes'),
                  if (test.maneuverControlDangerous)
                    _buildInfoRow('Control - Dangerous', 'Yes'),
                  if (test.maneuverObservationFaults > 0)
                    _buildInfoRow('Observation - Faults',
                        test.maneuverObservationFaults.toString()),
                  if (test.maneuverObservationSerious)
                    _buildInfoRow('Observation - Serious', 'Yes'),
                  if (test.maneuverObservationDangerous)
                    _buildInfoRow('Observation - Dangerous', 'Yes'),
                  pw.SizedBox(height: 16),
                ],

                // Additional Information
                if (test.eyesightTestCompleted ||
                    test.showMeTellMeCompleted ||
                    test.controlledStopCompleted ||
                    test.etaCompleted ||
                    test.ecoCompleted) ...[
                  _buildSectionHeader('ADDITIONAL INFORMATION'),
                  pw.SizedBox(height: 8),
                  if (test.eyesightTestCompleted)
                    _buildInfoRow(
                        'Eyesight Test',
                        test.eyesightTestFailed ? 'Failed' : 'Passed'),
                  if (test.showMeTellMeCompleted)
                    _buildInfoRow('Show Me / Tell Me', 'Completed'),
                  if (test.controlledStopCompleted)
                    _buildInfoRow('Controlled Stop', 'Completed'),
                  if (test.etaCompleted) ...[
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('ETA: ',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(() {
                          final types = <String>[];
                          if (test.etaPhysical) types.add('Physical');
                          if (test.etaVerbal) types.add('Verbal');
                          return types.isNotEmpty ? types.join(', ') : 'Completed';
                        }()),
                      ],
                    ),
                  ],
                  if (test.ecoCompleted) ...[
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('ECO: ',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(() {
                          final types = <String>[];
                          if (test.ecoControl) types.add('Control');
                          if (test.ecoPlanning) types.add('Planning');
                          return types.isNotEmpty ? types.join(', ') : 'Completed';
                        }()),
                      ],
                    ),
                  ],
                  pw.SizedBox(height: 16),
                ],

                // Footer
                pw.Divider(),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text(
                    'Report generated by ADI Buddy on ${dateFormat.format(test.savedAt)}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Get appropriate directory for the platform
      Directory outputDir;
      if (Platform.isAndroid) {
        outputDir = Directory('/storage/emulated/0/Download');
        // Fallback if external storage is not available
        if (!await outputDir.exists()) {
          outputDir = await getApplicationDocumentsDirectory();
        }
      } else if (Platform.isIOS) {
        outputDir = await getApplicationDocumentsDirectory();
      } else {
        // Windows, macOS, Linux
        outputDir = await getApplicationDocumentsDirectory();
      }

      debugPrint('Output directory: ${outputDir.path}');
      
      // Ensure the directory exists
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }
      
      // Create a safe filename
      final safeCandidateName = test.candidateName.isEmpty 
          ? 'Unknown' 
          : test.candidateName
              .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
              .replaceAll(RegExp(r'_+'), '_')
              .trim();
      final safeDate = dateFormat.format(test.testDate).replaceAll('/', '-');
      final fileName = 'Driving_Test_Report_${safeCandidateName}_$safeDate.pdf';
      final filePath = '${outputDir.path}${Platform.pathSeparator}$fileName';
      
      debugPrint('File path: $filePath');
      
      final file = File(filePath);
      
      // Write the PDF bytes
      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes, flush: true);
      
      debugPrint('PDF saved successfully to: ${file.path}');

      // Share the PDF using the system share dialog
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Driving Test Report - ${test.candidateName}',
        text: test.passed
            ? 'Congratulations! Here is your Driving Test Report.'
            : 'Here is your Driving Test Report.',
      );
    } catch (e, stackTrace) {
      debugPrint('PDF Error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static pw.Widget _buildSectionHeader(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.purple, width: 2),
        ),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.purple,
        ),
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '$label: ',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  static pw.Widget _buildFaultSummaryBox(TestResult test) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        children: [
          _buildFaultCount('Faults (F)', test.totalDrivingFaults,
              test.totalDrivingFaults > 15 ? PdfColors.red : PdfColors.green),
          pw.VerticalDivider(),
          _buildFaultCount('Serious (S)', test.totalSeriousFaults,
              test.totalSeriousFaults > 0 ? PdfColors.orange : PdfColors.grey),
          pw.VerticalDivider(),
          _buildFaultCount('Dangerous (D)', test.totalDangerousFaults,
              test.totalDangerousFaults > 0 ? PdfColors.red : PdfColors.grey),
        ],
      ),
    );
  }

  static pw.Widget _buildFaultCount(String label, int count, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          count.toString(),
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
