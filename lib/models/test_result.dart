import 'package:hive/hive.dart';

part 'test_result.g.dart';

@HiveType(typeId: 0)
class TestResult extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String candidateName;

  @HiveField(2)
  String candidateEmail;

  @HiveField(3)
  String testCenter;

  @HiveField(4)
  DateTime testDate;

  @HiveField(5)
  String testTime;

  @HiveField(6)
  bool passed;

  @HiveField(7)
  Map<String, int> drivingFaults;

  @HiveField(8)
  List<String> seriousFaults;

  @HiveField(9)
  List<String> dangerousFaults;

  @HiveField(10)
  String? selectedManeuver;

  @HiveField(11)
  int maneuverControlFaults;

  @HiveField(12)
  int maneuverObservationFaults;

  @HiveField(13)
  bool maneuverControlSerious;

  @HiveField(14)
  bool maneuverControlDangerous;

  @HiveField(15)
  bool maneuverObservationSerious;

  @HiveField(16)
  bool maneuverObservationDangerous;

  @HiveField(17)
  bool eyesightTestFailed;

  @HiveField(18)
  bool eyesightTestCompleted;

  @HiveField(19)
  bool showMeTellMeCompleted;

  @HiveField(20)
  bool controlledStopCompleted;

  @HiveField(21)
  bool accompaniedAS;

  @HiveField(22)
  bool accompaniedNS1;

  @HiveField(23)
  bool accompaniedNS2;

  @HiveField(24)
  bool accompaniedHSDS;

  @HiveField(25)
  bool etaCompleted;

  @HiveField(26)
  bool etaPhysical;

  @HiveField(27)
  bool etaVerbal;

  @HiveField(28)
  bool ecoCompleted;

  @HiveField(29)
  bool ecoControl;

  @HiveField(30)
  bool ecoPlanning;

  @HiveField(31)
  DateTime savedAt;

  TestResult({
    required this.id,
    required this.candidateName,
    required this.candidateEmail,
    required this.testCenter,
    required this.testDate,
    required this.testTime,
    required this.passed,
    required this.drivingFaults,
    required this.seriousFaults,
    required this.dangerousFaults,
    this.selectedManeuver,
    this.maneuverControlFaults = 0,
    this.maneuverObservationFaults = 0,
    this.maneuverControlSerious = false,
    this.maneuverControlDangerous = false,
    this.maneuverObservationSerious = false,
    this.maneuverObservationDangerous = false,
    this.eyesightTestFailed = false,
    this.eyesightTestCompleted = false,
    this.showMeTellMeCompleted = false,
    this.controlledStopCompleted = false,
    this.accompaniedAS = false,
    this.accompaniedNS1 = false,
    this.accompaniedNS2 = false,
    this.accompaniedHSDS = false,
    this.etaCompleted = false,
    this.etaPhysical = false,
    this.etaVerbal = false,
    this.ecoCompleted = false,
    this.ecoControl = false,
    this.ecoPlanning = false,
    required this.savedAt,
  });

  int get totalDrivingFaults {
    int total = drivingFaults.values.fold(0, (sum, count) => sum + count);
    total += maneuverControlFaults;
    total += maneuverObservationFaults;
    return total;
  }

  int get totalSeriousFaults {
    int count = seriousFaults.length;
    if (maneuverControlSerious) count++;
    if (maneuverObservationSerious) count++;
    if (eyesightTestFailed) count++;
    return count;
  }

  int get totalDangerousFaults {
    int count = dangerousFaults.length;
    if (maneuverControlDangerous) count++;
    if (maneuverObservationDangerous) count++;
    return count;
  }
}
