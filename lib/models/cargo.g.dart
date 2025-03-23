// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cargo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PaymentStatusAdapter extends TypeAdapter<PaymentStatus> {
  @override
  final int typeId = 4;

  @override
  PaymentStatus read(BinaryReader reader) {
    return PaymentStatus();
  }

  @override
  void write(BinaryWriter writer, PaymentStatus obj) {
    writer.writeByte(0);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CargoAdapter extends TypeAdapter<Cargo> {
  @override
  final int typeId = 5;

  @override
  Cargo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    // Make sure we have a transportCostPerTon value (default to 0 if not present)
    double transportCost = 0.0;
    if (fields.containsKey(10)) {
      final value = fields[10];
      if (value is double) {
        transportCost = value;
      }
    }
    
    return Cargo(
      id: fields[0] as int?,
      vehicle: fields[1] as Vehicle,
      driver: fields[2] as Driver,
      cargoType: fields[3] as CargoType,
      origin: fields[4] as String,
      destination: fields[5] as String,
      date: fields[6] as DateTime,
      weight: fields[7] as double,
      pricePerTon: fields[8] as double,
      paymentStatus: fields[9] as int,
      transportCostPerTon: transportCost,
    );
  }

  @override
  void write(BinaryWriter writer, Cargo obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.vehicle)
      ..writeByte(2)
      ..write(obj.driver)
      ..writeByte(3)
      ..write(obj.cargoType)
      ..writeByte(4)
      ..write(obj.origin)
      ..writeByte(5)
      ..write(obj.destination)
      ..writeByte(6)
      ..write(obj.date)
      ..writeByte(7)
      ..write(obj.weight)
      ..writeByte(8)
      ..write(obj.pricePerTon)
      ..writeByte(9)
      ..write(obj.paymentStatus)
      ..writeByte(10)
      ..write(obj.transportCostPerTon);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CargoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
