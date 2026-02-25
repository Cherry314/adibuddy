// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'speed_limit_zone.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SpeedLimitZoneAdapter extends TypeAdapter<SpeedLimitZone> {
  @override
  final int typeId = 1;

  @override
  SpeedLimitZone read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SpeedLimitZone(
      id: fields[0] as String,
      latitude: fields[1] as double,
      longitude: fields[2] as double,
      speedLimitMph: fields[3] as int,
      roadName: fields[4] as String,
      firstSeen: fields[5] as DateTime,
      lastAccessed: fields[6] as DateTime,
      accessCount: fields[7] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SpeedLimitZone obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.latitude)
      ..writeByte(2)
      ..write(obj.longitude)
      ..writeByte(3)
      ..write(obj.speedLimitMph)
      ..writeByte(4)
      ..write(obj.roadName)
      ..writeByte(5)
      ..write(obj.firstSeen)
      ..writeByte(6)
      ..write(obj.lastAccessed)
      ..writeByte(7)
      ..write(obj.accessCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpeedLimitZoneAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
