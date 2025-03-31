// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'freight.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FreightAdapter extends TypeAdapter<Freight> {
  @override
  final int typeId = 10;

  @override
  Freight read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Freight(
      id: fields[0] as int?,
      name: fields[1] as String,
      phoneNumber: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Freight obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.phoneNumber);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FreightAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
