// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tution_class.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TutionClassAdapter extends TypeAdapter<TutionClass> {
  @override
  final int typeId = 0;

  @override
  TutionClass read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TutionClass(
      subject: fields[0] as String,
      teacher: fields[1] as String,
      location: fields[2] as String,
      day: fields[3] as String,
      startTime: fields[4] as String,
      durationHours: fields[5] as int,
      monthlyFee: fields[6] as double,
    );
  }

  @override
  void write(BinaryWriter writer, TutionClass obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.subject)
      ..writeByte(1)
      ..write(obj.teacher)
      ..writeByte(2)
      ..write(obj.location)
      ..writeByte(3)
      ..write(obj.day)
      ..writeByte(4)
      ..write(obj.startTime)
      ..writeByte(5)
      ..write(obj.durationHours)
      ..writeByte(6)
      ..write(obj.monthlyFee);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TutionClassAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
