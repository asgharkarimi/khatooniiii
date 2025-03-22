// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cargo_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CargoTypeAdapter extends TypeAdapter<CargoType> {
  @override
  final int typeId = 2;

  @override
  CargoType read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CargoType(
      id: fields[0] as int?,
      cargoName: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CargoType obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.cargoName);
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
