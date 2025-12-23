// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_result.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TestResultAdapter extends TypeAdapter<TestResult> {
  @override
  final int typeId = 0;

  @override
  TestResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TestResult(
      id: fields[0] as String,
      candidateName: fields[1] as String,
      candidateEmail: fields[2] as String,
      testCenter: fields[3] as String,
      testDate: fields[4] as DateTime,
      testTime: fields[5] as String,
      passed: fields[6] as bool,
      drivingFaults: (fields[7] as Map).cast<String, int>(),
      seriousFaults: (fields[8] as List).cast<String>(),
      dangerousFaults: (fields[9] as List).cast<String>(),
      selectedManeuver: fields[10] as String?,
      maneuverControlFaults: fields[11] as int,
      maneuverObservationFaults: fields[12] as int,
      maneuverControlSerious: fields[13] as bool,
      maneuverControlDangerous: fields[14] as bool,
      maneuverObservationSerious: fields[15] as bool,
      maneuverObservationDangerous: fields[16] as bool,
      eyesightTestFailed: fields[17] as bool,
      eyesightTestCompleted: fields[18] as bool,
      showMeTellMeCompleted: fields[19] as bool,
      controlledStopCompleted: fields[20] as bool,
      accompaniedAS: fields[21] as bool,
      accompaniedNS1: fields[22] as bool,
      accompaniedNS2: fields[23] as bool,
      accompaniedHSDS: fields[24] as bool,
      etaCompleted: fields[25] as bool,
      etaPhysical: fields[26] as bool,
      etaVerbal: fields[27] as bool,
      ecoCompleted: fields[28] as bool,
      ecoControl: fields[29] as bool,
      ecoPlanning: fields[30] as bool,
      savedAt: fields[31] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TestResult obj) {
    writer
      ..writeByte(32)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.candidateName)
      ..writeByte(2)
      ..write(obj.candidateEmail)
      ..writeByte(3)
      ..write(obj.testCenter)
      ..writeByte(4)
      ..write(obj.testDate)
      ..writeByte(5)
      ..write(obj.testTime)
      ..writeByte(6)
      ..write(obj.passed)
      ..writeByte(7)
      ..write(obj.drivingFaults)
      ..writeByte(8)
      ..write(obj.seriousFaults)
      ..writeByte(9)
      ..write(obj.dangerousFaults)
      ..writeByte(10)
      ..write(obj.selectedManeuver)
      ..writeByte(11)
      ..write(obj.maneuverControlFaults)
      ..writeByte(12)
      ..write(obj.maneuverObservationFaults)
      ..writeByte(13)
      ..write(obj.maneuverControlSerious)
      ..writeByte(14)
      ..write(obj.maneuverControlDangerous)
      ..writeByte(15)
      ..write(obj.maneuverObservationSerious)
      ..writeByte(16)
      ..write(obj.maneuverObservationDangerous)
      ..writeByte(17)
      ..write(obj.eyesightTestFailed)
      ..writeByte(18)
      ..write(obj.eyesightTestCompleted)
      ..writeByte(19)
      ..write(obj.showMeTellMeCompleted)
      ..writeByte(20)
      ..write(obj.controlledStopCompleted)
      ..writeByte(21)
      ..write(obj.accompaniedAS)
      ..writeByte(22)
      ..write(obj.accompaniedNS1)
      ..writeByte(23)
      ..write(obj.accompaniedNS2)
      ..writeByte(24)
      ..write(obj.accompaniedHSDS)
      ..writeByte(25)
      ..write(obj.etaCompleted)
      ..writeByte(26)
      ..write(obj.etaPhysical)
      ..writeByte(27)
      ..write(obj.etaVerbal)
      ..writeByte(28)
      ..write(obj.ecoCompleted)
      ..writeByte(29)
      ..write(obj.ecoControl)
      ..writeByte(30)
      ..write(obj.ecoPlanning)
      ..writeByte(31)
      ..write(obj.savedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
