// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cargo_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CargoTypeAdapter extends TypeAdapter<CargoType> {
  @override
  final int typeId = 12;

  @override
  CargoType read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CargoType(
      cargoName: fields[0] as String,
      createdAt: fields[1] as DateTime?,
      updatedAt: fields[2] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, CargoType obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.cargoName)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CargoTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
