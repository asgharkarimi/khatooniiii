// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_payment.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DriverPaymentAdapter extends TypeAdapter<DriverPayment> {
  @override
  final int typeId = 11;

  @override
  DriverPayment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    // Safe conversion for cargoId and driverId fields
    String? safeCargoId;
    if (fields[7] != null) {
      safeCargoId = fields[7] is String ? fields[7] : fields[7].toString();
    }
    
    String? safeDriverId;
    if (fields[12] != null) {
      safeDriverId = fields[12] is String ? fields[12] : fields[12].toString();
    }
    
    return DriverPayment(
      id: fields[0] as String?,
      driver: fields[1] as Driver,
      cargo: fields[2] as Cargo,
      amount: fields[3] as double,
      paymentDate: fields[4] as DateTime,
      paymentMethod: fields[5] as int,
      description: fields[6] as String?,
      cargoId: safeCargoId,
      calculatedSalary: fields[8] as double,
      totalPaidAmount: fields[9] as double,
      remainingAmount: fields[10] as double,
      driverId: safeDriverId,
    );
  }

  @override
  void write(BinaryWriter writer, DriverPayment obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.driver)
      ..writeByte(2)
      ..write(obj.cargo)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.paymentDate)
      ..writeByte(5)
      ..write(obj.paymentMethod)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.cargoId)
      ..writeByte(8)
      ..write(obj.calculatedSalary)
      ..writeByte(9)
      ..write(obj.totalPaidAmount)
      ..writeByte(10)
      ..write(obj.remainingAmount)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.driverId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DriverPaymentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
