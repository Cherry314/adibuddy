import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import '../widgets/app_drawer.dart';

/// DL25 Digital Test Report Form
/// Programmatic recreation of the DVSA DL25 driving test report
class DL25FormScreen extends StatefulWidget {
  const DL25FormScreen({super.key});

  @override
  State<DL25FormScreen> createState() => _DL25FormScreenState();
}

class _DL25FormScreenState extends State<DL25FormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Expansion state for sections
  bool _candidateDetailsExpanded = false;
  bool _drivingFaultsExpanded = true; // Start with this one open
  bool _testResultExpanded = false;

  // Candidate Details
  final TextEditingController _candidateNameController = TextEditingController();
  final TextEditingController _candidateEmailController = TextEditingController();
  final TextEditingController _testCenterController = TextEditingController();
  DateTime? _testDate;
  TimeOfDay? _testTime;

  // Test Result
  String _testResult = 'Pass';

  // Driving Faults (up to 15 allowed)
  final Map<String, int> _drivingFaults = {};

  // Serious Faults
  final Set<String> _seriousFaults = {};

  // Dangerous Faults
  final Set<String> _dangerousFaults = {};

  // Maneuvers
  String? _selectedManeuver;
  int _maneuverControlFaults = 0;
  int _maneuverObservationFaults = 0;
  bool _maneuverControlSerious = false;
  bool _maneuverControlDangerous = false;
  bool _maneuverObservationSerious = false;
  bool _maneuverObservationDangerous = false;

  // Eyesight Test
  bool _eyesightTestFailed = false;

  // Accompanied Status tickboxes
  bool _accompaniedAS = false; // AS
  bool _accompaniedNS1 = false; // NS (first)
  bool _accompaniedNS2 = false; // NS (second)
  bool _accompaniedHSDS = false; // HS/DS

  // ETA (Extended Test Activities) checkboxes
  bool _etaCompleted = false;
  bool _etaPhysical = false;
  bool _etaVerbal = false;

  // ECO (Economy) checkboxes
  bool _ecoCompleted = false;
  bool _ecoControl = false;
  bool _ecoPlanning = false;

  // Additional checkboxes for database tracking
  bool _eyesightTestCompleted = false;
  bool _showMeTellMeCompleted = false;
  bool _controlledStopCompleted = false;

  // Categories from DL25 form - organized in columns
  final List<List<String>> _faultCategoriesColumns = [
    [
      // Column 1
      '###Show me / Tell me',
      'Show me / Tell me',
      '###Controlled stop',
      'Controlled Stop',
      '###Control',
      'Accelerator',
      'Clutch',
      'Gears',
      'Footbrake',
      'Parking Brake',
      'Steering',
      '---LINE---',
      'Precautions',
      'Ancillary Controls',
    ],
    [
      // Column 2
      '###Move Off',
      'Safety',
      'Control',
      '###Use of mirrors',
      'Signalling',
      'Change direction',
      'Change speed',
      '###Signals',
      'Necessary',
      'Correctly',
      'Timed',
      '###Junctions',
      'Approach Speed',
      'Observation',
      'Turning right',
      'Turning left',
      'Cutting corners',
      '###Judgement',
      'Overtaking',
      'Meeting',
      'Crossing',
    ],
    [
      // Column 3
      '###Positioning',
      'Normal driving',
      'Lane discipline',
      '---LINE---',
      'Pedestrian crossings',
      '---LINE---',
      'Position / Normal Stop',
      '---LINE---',
      'Awareness/Planning',
      '---LINE---',
      'Clearance',
      '---LINE---',
      'Following distance',
      '---LINE---',
      'Use of speed',
      '###Progress',
      'Appropriate speed',
      'Undue hesitation',
      '###Response to signs / signals',
      'Traffic signs',
      'Road markings',
      'Traffic Lights',
      'Traffic controllers',
      'Other road users',
    ],
  ];

  final List<String> _maneuverOptions = [
    'Parallel park (road)',
    'Park in bay (car park)',
    'Pull up on right',
    'Forward park (car park)',
  ];

  @override
  void dispose() {
    _candidateNameController.dispose();
    _candidateEmailController.dispose();
    _testCenterController.dispose();
    super.dispose();
  }

  int get totalDrivingFaults {
    int total = _drivingFaults.values.fold(0, (sum, count) => sum + count);
    total += _maneuverControlFaults;
    total += _maneuverObservationFaults;
    return total;
  }

  int get totalSeriousFaults {
    int count = _seriousFaults.length;
    if (_maneuverControlSerious) count++;
    if (_maneuverObservationSerious) count++;
    return count;
  }

  int get totalDangerousFaults {
    int count = _dangerousFaults.length;
    if (_maneuverControlDangerous) count++;
    if (_maneuverObservationDangerous) count++;
    return count;
  }

  bool get _isTablet {
    if (kIsWeb) return true;
    try {
      final data = MediaQueryData.fromView(
          WidgetsBinding.instance.platformDispatcher.views.first);
      final shortestSide = data.size.shortestSide;
      return shortestSide >= 600;
    } catch (e) {
      return false;
    }
  }

  void _incrementFault(String category) {
    setState(() {
      _drivingFaults[category] = (_drivingFaults[category] ?? 0) + 1;
    });
  }

  void _decrementFault(String category) {
    setState(() {
      if ((_drivingFaults[category] ?? 0) > 0) {
        _drivingFaults[category] = _drivingFaults[category]! - 1;
      }
    });
  }

  void _toggleSeriousFault(String category) {
    setState(() {
      if (_seriousFaults.contains(category)) {
        _seriousFaults.remove(category);
      } else {
        _seriousFaults.add(category);
        _dangerousFaults.remove(category);
      }
    });
  }

  void _toggleDangerousFault(String category) {
    setState(() {
      if (_dangerousFaults.contains(category)) {
        _dangerousFaults.remove(category);
      } else {
        _dangerousFaults.add(category);
        _seriousFaults.remove(category);
      }
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _testDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _testDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _testTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _testTime = picked);
    }
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('DL25 form saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _clearForm() {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Clear Form'),
            content: const Text(
                'Are you sure you want to clear all data? This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _candidateNameController.clear();
                    _candidateEmailController.clear();
                    _testCenterController.clear();
                    _testDate = null;
                    _testTime = null;
                    _testResult = 'Pass';
                    _drivingFaults.clear();
                    _seriousFaults.clear();
                    _dangerousFaults.clear();
                    _selectedManeuver = null;
                    _maneuverControlFaults = 0;
                    _maneuverObservationFaults = 0;
                    _maneuverControlSerious = false;
                    _maneuverControlDangerous = false;
                    _maneuverObservationSerious = false;
                    _maneuverObservationDangerous = false;
                    _eyesightTestFailed = false;
                    _accompaniedAS = false;
                    _accompaniedNS1 = false;
                    _accompaniedNS2 = false;
                    _accompaniedHSDS = false;
                    _etaCompleted = false;
                    _etaPhysical = false;
                    _etaVerbal = false;
                    _ecoCompleted = false;
                    _ecoControl = false;
                    _ecoPlanning = false;
                    _eyesightTestCompleted = false;
                    _showMeTellMeCompleted = false;
                    _controlledStopCompleted = false;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Form cleared')),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Clear'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = _isTablet;

    return Scaffold(
      appBar: AppBar(
        title: const Text('DL25 Test Report'),
        backgroundColor: Colors.purple[400],
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveForm,
            tooltip: 'Save Form',
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearForm,
            tooltip: 'Clear Form',
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/dl25-form'),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.purple[50]!, Colors.white],
            ),
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildExpandableSection(
                  title: 'Candidate Details',
                  icon: Icons.person,
                  isExpanded: _candidateDetailsExpanded,
                  onExpansionChanged: (expanded) {
                    setState(() => _candidateDetailsExpanded = expanded);
                  },
                  children: [
                    _buildTextField(
                        'Name', _candidateNameController, required: true),
                    const SizedBox(height: 12),
                    _buildEmailField(
                        'Candidates Email', _candidateEmailController,
                        required: true),
                    const SizedBox(height: 12),
                    _buildTextField(
                        'Test Centre', _testCenterController, required: true),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildDateSelector()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTimeSelector()),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                _buildExpandableFaultsSection(isTablet),

                const SizedBox(height: 12),

              _buildExpandableSection(
                  title: 'Test Result',
                  icon: Icons.assessment,
                  isExpanded: _testResultExpanded,
                  onExpansionChanged: (expanded) {
                    setState(() => _testResultExpanded = expanded);
                  },
                  children: [
                    _buildFaultsSummary(),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    _buildRadioGroup(
                      'Result',
                      ['Pass', 'Fail'],
                      _testResult,
                          (value) => setState(() => _testResult = value!),
                    ),
                    const SizedBox(height: 16),
                    _buildResultSummary(),
                  ],
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saveForm,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Test'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _clearForm,
                      icon: const Icon(Icons.clear),
                      label: const Text('Reset Test'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required Function(bool) onExpansionChanged,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          onExpansionChanged: onExpansionChanged,
          iconColor: Colors.purple[700],
          collapsedIconColor: Colors.purple[400],
          backgroundColor: Colors.white,
          collapsedBackgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          leading: Icon(icon, color: Colors.purple[600], size: 24),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.purple[700],
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableFaultsSection(bool isTablet) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: _drivingFaultsExpanded,
          onExpansionChanged: (expanded) {
            setState(() => _drivingFaultsExpanded = expanded);
          },
          iconColor: Colors.purple[700],
          collapsedIconColor: Colors.purple[400],
          backgroundColor: Colors.white,
          collapsedBackgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          leading: Icon(Icons.assignment, color: Colors.purple[600], size: 24),
          title: Text(
            'Driving Test Faults',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.purple[700],
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tap to mark faults:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'D = Driving (1-3 taps) | S = Serious | X = Dangerous',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  isTablet ? _buildTabletLayout() : _buildMobileLayout(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildFaultsSummary() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: totalDrivingFaults > 15 ? Colors.red[50] : Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: totalDrivingFaults > 15 ? Colors.red : Colors.blue,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Driving Faults:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '$totalDrivingFaults / 15',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: totalDrivingFaults > 15 ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: totalSeriousFaults > 0 ? Colors.orange[50] : Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Serious Faults:', style: TextStyle(fontSize: 16)),
              Text(
                '$totalSeriousFaults',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: totalSeriousFaults > 0 ? Colors.orange : Colors.grey,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: totalDangerousFaults > 0 ? Colors.red[50] : Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Dangerous Faults:', style: TextStyle(fontSize: 16)),
              Text(
                '$totalDangerousFaults',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: totalDangerousFaults > 0 ? Colors.red : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              _buildEyesightTestSection(),
              const SizedBox(height: 8),
              _buildAccompaniedStatusSection(),
              const SizedBox(height: 8),
              _buildManeuverSection(),
              const SizedBox(height: 8),
              ..._faultCategoriesColumns[0].map((category) =>
                  _buildFaultRow(category)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            children: [
              ..._faultCategoriesColumns[1].map((category) =>
                  _buildFaultRow(category)),
              const SizedBox(height: 8),
              _buildETASection(),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            children: [
              ..._faultCategoriesColumns[2].map((category) =>
                  _buildFaultRow(category)),
              const SizedBox(height: 8),
              _buildECOSection(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildManeuverSection(),
        const SizedBox(height: 8),
        ..._faultCategoriesColumns.expand((column) => column).map((category) =>
            _buildFaultRow(category)),
      ],
    );
  }

  Widget _buildEyesightTestSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[300]!, width: 2),
      ),
      child: Row(
        children: [
          Checkbox(
            value: _eyesightTestCompleted,
            onChanged: (val) =>
                setState(() => _eyesightTestCompleted = val ?? false),
            activeColor: Colors.blue[600],
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 4),
          Text(
            'EYESIGHT TEST',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue[900],
            ),
          ),
          const Spacer(),
          _AnimatedToggleButton(
            isActive: _eyesightTestFailed,
            onTap: () =>
                setState(() => _eyesightTestFailed = !_eyesightTestFailed),
            label: 'S',
            activeColor: Colors.orange[700]!,
            activeBgColor: Colors.orange[100],
          ),
        ],
      ),
    );
  }

  Widget _buildAccompaniedStatusSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[400]!, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _buildCheckboxItem('AS', _accompaniedAS, (value) {
              setState(() => _accompaniedAS = value);
            }),
          ),
          Expanded(
            child: _buildCheckboxItem('NS', _accompaniedNS1, (value) {
              setState(() => _accompaniedNS1 = value);
            }),
          ),
          Expanded(
            child: _buildCheckboxItem('NS', _accompaniedNS2, (value) {
              setState(() => _accompaniedNS2 = value);
            }),
          ),
          Expanded(
            child: _buildCheckboxItem('HS/DS', _accompaniedHSDS, (value) {
              setState(() => _accompaniedHSDS = value);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxItem(String label, bool value,
      Function(bool) onChanged) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: value,
            onChanged: (val) => onChanged(val ?? false),
            activeColor: Colors.purple[600],
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildETASection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[300]!, width: 2),
      ),
      child: Row(
        children: [
          // Main ETA checkbox
          Checkbox(
            value: _etaCompleted,
            onChanged: (val) => setState(() => _etaCompleted = val ?? false),
            activeColor: Colors.green[600],
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          Text(
            'ETA',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.green[900],
            ),
          ),
          const SizedBox(width: 16),
          // Physical checkbox
          Text(
            'Physical',
            style: TextStyle(fontSize: 11, color: Colors.grey[700]),
          ),
          Checkbox(
            value: _etaPhysical,
            onChanged: (val) => setState(() => _etaPhysical = val ?? false),
            activeColor: Colors.green[600],
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 8),
          // Verbal checkbox
          Text(
            'Verbal',
            style: TextStyle(fontSize: 11, color: Colors.grey[700]),
          ),
          Checkbox(
            value: _etaVerbal,
            onChanged: (val) => setState(() => _etaVerbal = val ?? false),
            activeColor: Colors.green[600],
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildECOSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal[300]!, width: 2),
      ),
      child: Row(
        children: [
          // Main ECO checkbox
          Checkbox(
            value: _ecoCompleted,
            onChanged: (val) => setState(() => _ecoCompleted = val ?? false),
            activeColor: Colors.teal[600],
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          Text(
            'ECO',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.teal[900],
            ),
          ),
          const SizedBox(width: 16),
          // Control checkbox
          Text(
            'Control',
            style: TextStyle(fontSize: 11, color: Colors.grey[700]),
          ),
          Checkbox(
            value: _ecoControl,
            onChanged: (val) => setState(() => _ecoControl = val ?? false),
            activeColor: Colors.teal[600],
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 8),
          // Planning checkbox
          Text(
            'Planning',
            style: TextStyle(fontSize: 11, color: Colors.grey[700]),
          ),
          Checkbox(
            value: _ecoPlanning,
            onChanged: (val) => setState(() => _ecoPlanning = val ?? false),
            activeColor: Colors.teal[600],
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildManeuverSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber[300]!, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.compare_arrows, color: Colors.amber[800], size: 20),
              const SizedBox(width: 8),
              Text(
                'Manoeuvres',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedManeuver,
            decoration: InputDecoration(
              labelText: 'Manoeuvre',
              labelStyle: const TextStyle(fontSize: 11),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 6),
            ),
            style: const TextStyle(fontSize: 11, color: Colors.black),
            items: _maneuverOptions.map((maneuver) {
              return DropdownMenuItem(
                value: maneuver,
                child: Text(
                  maneuver,
                  style: const TextStyle(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedManeuver = value),
          ),
          const SizedBox(height: 12),

          _buildManeuverFaultRow(
            'Control',
            _maneuverControlFaults,
            _maneuverControlSerious,
            _maneuverControlDangerous,
            onDrivingTap: () {
              setState(() {
                _maneuverControlFaults++;
              });
            },
            onDrivingLongPress: () {
              setState(() {
                if (_maneuverControlFaults > 0) _maneuverControlFaults--;
              });
            },
            onSeriousTap: () {
              setState(() {
                _maneuverControlSerious = !_maneuverControlSerious;
                if (_maneuverControlSerious) _maneuverControlDangerous = false;
              });
            },
            onDangerousTap: () {
              setState(() {
                _maneuverControlDangerous = !_maneuverControlDangerous;
                if (_maneuverControlDangerous) _maneuverControlSerious = false;
              });
            },
          ),

          const SizedBox(height: 8),

          _buildManeuverFaultRow(
            'Observation',
            _maneuverObservationFaults,
            _maneuverObservationSerious,
            _maneuverObservationDangerous,
            onDrivingTap: () {
              setState(() {
                _maneuverObservationFaults++;
              });
            },
            onDrivingLongPress: () {
              setState(() {
                if (_maneuverObservationFaults > 0) _maneuverObservationFaults--;
              });
            },
            onSeriousTap: () {
              setState(() {
                _maneuverObservationSerious = !_maneuverObservationSerious;
                if (_maneuverObservationSerious) {
                  _maneuverObservationDangerous = false;
                }
              });
            },
            onDangerousTap: () {
              setState(() {
                _maneuverObservationDangerous = !_maneuverObservationDangerous;
                if (_maneuverObservationDangerous) {
                  _maneuverObservationSerious = false;
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildManeuverFaultRow(String label,
      int count,
      bool hasSerious,
      bool hasDangerous, {
        required VoidCallback onDrivingTap,
        required VoidCallback onDrivingLongPress,
        required VoidCallback onSeriousTap,
        required VoidCallback onDangerousTap,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        title: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AnimatedFaultButton(
              count: count,
              onTap: onDrivingTap,
              onLongPress: onDrivingLongPress,
            ),
            const SizedBox(width: 4),
            _AnimatedToggleButton(
              isActive: hasSerious,
              onTap: onSeriousTap,
              label: 'S',
              activeColor: Colors.orange[700]!,
              activeBgColor: Colors.orange[100],
            ),
            const SizedBox(width: 4),
            _AnimatedToggleButton(
              isActive: hasDangerous,
              onTap: onDangerousTap,
              label: 'X',
              activeColor: Colors.red[700]!,
              activeBgColor: Colors.red[100],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label,
      TextEditingController controller, {
        bool required = false,
      }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: required
          ? (value) => value?.isEmpty ?? true ? 'This field is required' : null
          : null,
    );
  }

  Widget _buildEmailField(String label,
      TextEditingController controller, {
        bool required = false,
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: const Icon(Icons.email),
      ),
      validator: required
          ? (value) {
        if (value?.isEmpty ?? true) {
          return 'This field is required';
        }
        // Basic email validation
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
          return 'Please enter a valid email';
        }
        return null;
      }
          : null,
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Test Date',
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _testDate != null
                  ? DateFormat('dd/MM/yyyy').format(_testDate!)
                  : 'Select Date',
              style: TextStyle(
                color: _testDate != null ? Colors.black : Colors.grey,
              ),
            ),
            const Icon(Icons.calendar_today, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return InkWell(
      onTap: _selectTime,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Test Time',
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _testTime != null ? _testTime!.format(context) : 'Select Time',
              style: TextStyle(
                color: _testTime != null ? Colors.black : Colors.grey,
              ),
            ),
            const Icon(Icons.access_time, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioGroup(String label,
      List<String> options,
      String currentValue,
      Function(String?) onChanged,) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          children: options.map((option) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radio<String>(
                  value: option,
                  groupValue: currentValue,
                  onChanged: onChanged,
                  activeColor: Colors.purple[400],
                ),
                Text(option),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFaultRow(String category) {
    // Check if this is a subheading
    if (category.startsWith('###')) {
      final headingText = category.replaceFirst('###', '');

      // Check if this heading needs a checkbox
      bool? checkboxValue;
      Function(bool)? onCheckboxChanged;

      if (headingText == 'Show me / Tell me') {
        checkboxValue = _showMeTellMeCompleted;
        onCheckboxChanged =
            (val) => setState(() => _showMeTellMeCompleted = val);
      } else if (headingText == 'Controlled stop') {
        checkboxValue = _controlledStopCompleted;
        onCheckboxChanged =
            (val) => setState(() => _controlledStopCompleted = val);
      }

      return Container(
        margin: const EdgeInsets.only(top: 8, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            if (checkboxValue != null && onCheckboxChanged != null) ...[
              Checkbox(
                value: checkboxValue,
                onChanged: (val) => onCheckboxChanged?.call(val ?? false),
                activeColor: Colors.purple[600],
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              headingText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.purple[700],
              ),
            ),
          ],
        ),
      );
    }

    // Check if this is a divider line
    if (category == '---LINE---') {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        height: 1,
        color: Colors.grey[300],
      );
    }

    final drivingCount = _drivingFaults[category] ?? 0;
    final hasSerious = _seriousFaults.contains(category);
    final hasDangerous = _dangerousFaults.contains(category);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        title: Text(
          category,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AnimatedFaultButton(
              count: drivingCount,
              onTap: () => _incrementFault(category),
              onLongPress: () => _decrementFault(category),
            ),
            const SizedBox(width: 4),
            _AnimatedToggleButton(
              isActive: hasSerious,
              onTap: () => _toggleSeriousFault(category),
              label: 'S',
              activeColor: Colors.orange[700]!,
              activeBgColor: Colors.orange[100],
            ),
            const SizedBox(width: 4),
            _AnimatedToggleButton(
              isActive: hasDangerous,
              onTap: () => _toggleDangerousFault(category),
              label: 'X',
              activeColor: Colors.red[700]!,
              activeBgColor: Colors.red[100],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSummary() {
    final bool hasFailed = totalDrivingFaults > 15 ||
        totalSeriousFaults > 0 ||
        totalDangerousFaults > 0 ||
        _eyesightTestFailed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasFailed ? Colors.red[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasFailed ? Colors.red : Colors.green,
          width: 3,
        ),
      ),
      child: Column(
        children: [
          Icon(
            hasFailed ? Icons.cancel : Icons.check_circle,
            size: 64,
            color: hasFailed ? Colors.red : Colors.green,
          ),
          const SizedBox(height: 12),
          Text(
            hasFailed ? 'FAIL' : 'PASS',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: hasFailed ? Colors.red : Colors.green,
            ),
          ),
          const SizedBox(height: 12),
          if (hasFailed) ...[
            const Text(
              'Reasons for failure:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (totalDrivingFaults > 15)
              Text('• Too many driving faults ($totalDrivingFaults/15)'),
            if (totalSeriousFaults > 0)
              Text('• $totalSeriousFaults serious fault(s)'),
            if (totalDangerousFaults > 0)
              Text('• $totalDangerousFaults dangerous fault(s)'),
            if (_eyesightTestFailed)
              const Text('• Failed eyesight test'),
          ],
        ],
      ),
    );
  }
}

/// Animated fault button with +1/-1 feedback
class _AnimatedFaultButton extends StatefulWidget {
  final int count;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _AnimatedFaultButton({
    required this.count,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<_AnimatedFaultButton> createState() => _AnimatedFaultButtonState();
}

class _AnimatedFaultButtonState extends State<_AnimatedFaultButton>
    with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;
  bool _isIncrement = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1.5),
    ).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeOut),
    );
  }

  void _showAnimation(bool isIncrement) {
    setState(() {
      _isIncrement = isIncrement;
    });
    _animationController!.forward(from: 0);
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () {
            widget.onTap();
            _showAnimation(true);
          },
          onLongPress: () {
            if (widget.count > 0) {
              widget.onLongPress();
              _showAnimation(false);
            }
          },
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: widget.count > 0 ? Colors.blue[100] : Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: widget.count > 0 ? Colors.blue : Colors.grey[300]!,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                widget.count > 0 ? widget.count.toString() : 'D',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: widget.count > 0 ? Colors.blue[700] : Colors.grey[600],
                ),
              ),
            ),
          ),
        ),
        if (_animationController != null &&
            (_animationController!.isAnimating ||
                _animationController!.value > 0))
          Positioned(
            left: 0,
            right: 0,
            top: -25,
            child: AnimatedBuilder(
              animation: _animationController!,
              builder: (context, child) {
                return SlideTransition(
                  position: _slideAnimation!,
                  child: FadeTransition(
                    opacity: _fadeAnimation!,
                    child: Center(
                      child: Text(
                        _isIncrement ? '+1' : '-1',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _isIncrement ? Colors.blue[700] : Colors
                              .green[700],
                          shadows: [
                            Shadow(
                              color: Colors.white,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Animated toggle button for Serious/Dangerous faults
class _AnimatedToggleButton extends StatefulWidget {
  final bool isActive;
  final VoidCallback onTap;
  final String label;
  final Color activeColor;
  final Color? activeBgColor;

  const _AnimatedToggleButton({
    required this.isActive,
    required this.onTap,
    required this.label,
    required this.activeColor,
    this.activeBgColor,
  });

  @override
  State<_AnimatedToggleButton> createState() => _AnimatedToggleButtonState();
}

class _AnimatedToggleButtonState extends State<_AnimatedToggleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _showLabel = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1.5),
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(_AnimatedToggleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _showAnimation(widget.isActive);
    }
  }

  void _showAnimation(bool isActive) {
    setState(() {
      _showLabel = true;
    });
    _animationController.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _showLabel = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () {
            widget.onTap();
          },
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: widget.isActive ? widget.activeBgColor : Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: widget.isActive ? widget.activeColor : Colors.grey[300]!,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                widget.label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: widget.isActive ? widget.activeColor : Colors
                      .grey[600],
                ),
              ),
            ),
          ),
        ),
        if (_showLabel)
          Positioned(
            left: 0,
            right: 0,
            top: -25,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Center(
                      child: Text(
                        widget.isActive ? '+1' : '-1',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: widget.isActive ? widget.activeColor : Colors.green[700],
                          shadows: [
                            Shadow(
                              color: Colors.white,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
