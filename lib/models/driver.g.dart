// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DriverAdapter extends TypeAdapter<Driver> {
  @override
  final int typeId = 0;

  @override
  Driver read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Driver(
      id: fields[0] as String?,
      name: fields[1] as String,
      nationalId: fields[2] as String,
      mobile: fields[3] as String,
      licenseNumber: fields[4] as String,
      address: fields[5] as String,
      imagePath: fields[6] as String?,
      firstName: fields[7] as String?,
      lastName: fields[8] as String?,
      licenseImagePath: fields[9] as String?,
      smartCardImagePath: fields[14] as String?,
      password: fields[10] as String?,
      salaryPercentage: fields[11] as double,
      bankAccountNumber: fields[12] as String?,
      bankName: fields[13] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Driver obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.nationalId)
      ..writeByte(3)
      ..write(obj.mobile)
      ..writeByte(4)
      ..write(obj.licenseNumber)
      ..writeByte(5)
      ..write(obj.address)
      ..writeByte(6)
      ..write(obj.imagePath)
      ..writeByte(7)
      ..write(obj.firstName)
      ..writeByte(8)
      ..write(obj.lastName)
      ..writeByte(9)
      ..write(obj.licenseImagePath)
      ..writeByte(10)
      ..write(obj.password)
      ..writeByte(11)
      ..write(obj.salaryPercentage)
      ..writeByte(12)
      ..write(obj.bankAccountNumber)
      ..writeByte(13)
      ..write(obj.bankName)
      ..writeByte(14)
      ..write(obj.smartCardImagePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DriverAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
