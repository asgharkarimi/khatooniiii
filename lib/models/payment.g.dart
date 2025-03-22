// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PaymentTypeAdapter extends TypeAdapter<PaymentType> {
  @override
  final int typeId = 6;

  @override
  PaymentType read(BinaryReader reader) {
    return PaymentType();
  }

  @override
  void write(BinaryWriter writer, PaymentType obj) {
    writer.writeByte(0);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PayerTypeAdapter extends TypeAdapter<PayerType> {
  @override
  final int typeId = 7;

  @override
  PayerType read(BinaryReader reader) {
    return PayerType();
  }

  @override
  void write(BinaryWriter writer, PayerType obj) {
    writer.writeByte(0);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PayerTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PaymentAdapter extends TypeAdapter<Payment> {
  @override
  final int typeId = 8;

  @override
  Payment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Payment(
      id: fields[0] as int?,
      paymentType: fields[1] as int,
      payerType: fields[2] as int,
      customer: fields[3] as Customer,
      cargo: fields[4] as Cargo,
      amount: fields[5] as double,
      cardToCardReceiptImagePath: fields[6] as String?,
      checkImagePath: fields[7] as String?,
      checkDueDate: fields[8] as DateTime?,
      paymentDate: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Payment obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.paymentType)
      ..writeByte(2)
      ..write(obj.payerType)
      ..writeByte(3)
      ..write(obj.customer)
      ..writeByte(4)
      ..write(obj.cargo)
      ..writeByte(5)
      ..write(obj.amount)
      ..writeByte(6)
      ..write(obj.cardToCardReceiptImagePath)
      ..writeByte(7)
      ..write(obj.checkImagePath)
      ..writeByte(8)
      ..write(obj.checkDueDate)
      ..writeByte(9)
      ..write(obj.paymentDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
