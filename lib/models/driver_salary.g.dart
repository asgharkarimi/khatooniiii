// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_salary.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DriverSalaryAdapter extends TypeAdapter<DriverSalary> {
  @override
  final int typeId = 7;

  @override
  DriverSalary read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    // Safe conversion for cargoId field - handle both int and String types
    String? safeCargoId;
    if (fields[12] != null) {
      safeCargoId = fields[12] is String ? fields[12] : fields[12].toString();
    }
    
    return DriverSalary(
      id: fields[0] as String?,
      driver: fields[1] as Driver,
      amount: fields[2] as double,
      paymentDate: fields[3] as DateTime,
      paymentMethod: fields[4] as int,
      description: fields[5] as String?,
      percentage: fields[7] as double?,
      cargo: fields[8] as Cargo?,
      calculatedSalary: fields[9] as double?,
      totalPaidAmount: fields[10] as double?,
      remainingAmount: fields[11] as double,
      cargoId: safeCargoId,
    )..createdAt = fields[6] as DateTime;
  }

  @override
  void write(BinaryWriter writer, DriverSalary obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.driver)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.paymentDate)
      ..writeByte(4)
      ..write(obj.paymentMethod)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.percentage)
      ..writeByte(8)
      ..write(obj.cargo)
      ..writeByte(9)
      ..write(obj.calculatedSalary)
      ..writeByte(10)
      ..write(obj.totalPaidAmount)
      ..writeByte(11)
      ..write(obj.remainingAmount)
      ..writeByte(12)
      ..write(obj.cargoId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DriverSalaryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
