import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/test_result.dart';
import '../services/email_service.dart';

class TestDetailScreen extends StatelessWidget {
  final TestResult testResult;

  const TestDetailScreen({super.key, required this.testResult});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Report'),
        backgroundColor: testResult.passed ? Colors.green : Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.email),
            onPressed: () => _showEmailDialog(context),
            tooltip: 'Email report',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Result header
            Card(
              elevation: 4,
              color: testResult.passed ? Colors.green[50] : Colors.red[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: testResult.passed ? Colors.green : Colors.red,
                  width: 3,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      testResult.passed ? Icons.check_circle : Icons.cancel,
                      size: 64,
                      color: testResult.passed ? Colors.green : Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      testResult.passed ? 'PASS' : 'FAIL',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: testResult.passed ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Candidate details
            _buildSectionCard(
              'Candidate Details',
              Icons.person,
              [
                _buildInfoRow('Name', testResult.candidateName),
                _buildInfoRow('Email', testResult.candidateEmail),
                _buildInfoRow('Test Centre', testResult.testCenter),
                _buildInfoRow('Date', dateFormat.format(testResult.testDate)),
                _buildInfoRow('Time', testResult.testTime),
              ],
            ),

            // Fault Summary
            _buildSectionCard(
              'Fault Summary',
              Icons.summarize,
              [
                _buildFaultSummaryRow(
                  'Driving Faults (D)',
                  testResult.totalDrivingFaults,
                  '/ 15',
                  Colors.blue,
                ),
                _buildFaultSummaryRow(
                  'Serious Faults (S)',
                  testResult.totalSeriousFaults,
                  '',
                  Colors.orange,
                ),
                _buildFaultSummaryRow(
                  'Dangerous Faults (X)',
                  testResult.totalDangerousFaults,
                  '',
                  Colors.red,
                ),
              ],
            ),

            // Driving Faults Detail
            if (testResult.drivingFaults.isNotEmpty)
              _buildSectionCard(
                'Driving Faults',
                Icons.drive_eta,
                testResult.drivingFaults.entries
                    .where((e) => e.value > 0)
                    .map((e) => _buildFaultRow(e.key, e.value, Colors.blue))
                    .toList(),
              ),

            // Serious Faults Detail
            if (testResult.seriousFaults.isNotEmpty)
              _buildSectionCard(
                'Serious Faults',
                Icons.warning,
                testResult.seriousFaults
                    .map((f) => _buildFaultRow(f, null, Colors.orange))
                    .toList(),
              ),

            // Dangerous Faults Detail
            if (testResult.dangerousFaults.isNotEmpty)
              _buildSectionCard(
                'Dangerous Faults',
                Icons.dangerous,
                testResult.dangerousFaults
                    .map((f) => _buildFaultRow(f, null, Colors.red))
                    .toList(),
              ),

            // Maneuver
            if (testResult.selectedManeuver != null)
              _buildSectionCard(
                'Maneuver',
                Icons.compare_arrows,
                [
                  _buildInfoRow('Type', testResult.selectedManeuver!),
                  if (testResult.maneuverControlFaults > 0)
                    _buildInfoRow('Control - Driving',
                        '${testResult.maneuverControlFaults}'),
                  if (testResult.maneuverControlSerious)
                    _buildInfoRow('Control - Serious', 'Yes',
                        color: Colors.orange),
                  if (testResult.maneuverControlDangerous)
                    _buildInfoRow('Control - Dangerous', 'Yes',
                        color: Colors.red),
                  if (testResult.maneuverObservationFaults > 0)
                    _buildInfoRow('Observation - Driving',
                        '${testResult.maneuverObservationFaults}'),
                  if (testResult.maneuverObservationSerious)
                    _buildInfoRow('Observation - Serious', 'Yes',
                        color: Colors.orange),
                  if (testResult.maneuverObservationDangerous)
                    _buildInfoRow('Observation - Dangerous', 'Yes',
                        color: Colors.red),
                ],
              ),

            // Additional Information
            _buildSectionCard(
              'Additional Information',
              Icons.info_outline,
              [
                if (testResult.eyesightTestCompleted)
                  _buildInfoRow(
                    'Eyesight Test',
                    testResult.eyesightTestFailed ? 'Failed' : 'Passed',
                    color: testResult.eyesightTestFailed
                        ? Colors.red
                        : Colors.green,
                  ),
                if (testResult.showMeTellMeCompleted)
                  _buildInfoRow('Show Me / Tell Me', 'Completed'),
                if (testResult.controlledStopCompleted)
                  _buildInfoRow('Controlled Stop', 'Completed'),
                if (testResult.etaCompleted) ...[
                  _buildInfoRow('ETA', _getETADetails()),
                ],
                if (testResult.ecoCompleted) ...[
                  _buildInfoRow('ECO', _getECODetails()),
                ],
                if (testResult.accompaniedAS)
                  _buildInfoRow('Accompanied', 'AS'),
                if (testResult.accompaniedNS1 || testResult.accompaniedNS2)
                  _buildInfoRow('Accompanied', 'NS'),
                if (testResult.accompaniedHSDS)
                  _buildInfoRow('Accompanied', 'HS/DS'),
              ],
            ),

            const SizedBox(height: 16),

            // Saved timestamp
            Text(
              'Saved: ${DateFormat('dd/MM/yyyy HH:mm').format(
                  testResult.savedAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _getETADetails() {
    List<String> details = [];
    if (testResult.etaPhysical) details.add('Physical');
    if (testResult.etaVerbal) details.add('Verbal');
    return details.isEmpty ? 'Completed' : details.join(', ');
  }

  String _getECODetails() {
    List<String> details = [];
    if (testResult.ecoControl) details.add('Control');
    if (testResult.ecoPlanning) details.add('Planning');
    return details.isEmpty ? 'Completed' : details.join(', ');
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.purple[600], size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: color ?? Colors.black87,
                fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaultSummaryRow(String label, int count, String suffix,
      Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '$count$suffix',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaultRow(String fault, int? count, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              fault,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          if (count != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showEmailDialog(BuildContext context) async {
    final TextEditingController emailController =
    TextEditingController(text: testResult.candidateEmail);

    await showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Email Test Report'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Send test report to:'),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  final email = emailController.text.trim();
                  if (email.isNotEmpty) {
                    final success = await EmailService.sendTestSummary(
                      testResult,
                      alternativeEmail: email != testResult.candidateEmail
                          ? email
                          : null,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Email sent successfully!'
                                : 'Could not send email',
                          ),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.send),
                label: const Text('Send'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
    );
  }
}
