import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:khatooniiii/models/driver.dart';
import 'package:khatooniiii/models/cargo.dart';

part 'driver_salary.g.dart';

@HiveType(typeId: 7)
class DriverSalary extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  Driver driver;

  @HiveField(2)
  double amount;

  @HiveField(3)
  DateTime paymentDate;

  @HiveField(4)
  int paymentMethod; // 0: Cash, 1: Bank Transfer, 2: Check

  @HiveField(5)
  String? description;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  double? percentage; // درصد حقوق راننده

  @HiveField(8)
  Cargo? cargo;

  DriverSalary({
    String? id,
    required this.driver,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    this.description,
    this.percentage,
    this.cargo,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = DateTime.now();
}

// Payment method constants
class PaymentMethod {
  static const int cash = 0;
  static const int bankTransfer = 1;
  static const int check = 2;
  
  static String getTitle(int method) {
    switch (method) {
      case cash:
        return 'نقدی';
      case bankTransfer:
        return 'انتقال بانکی';
      case check:
        return 'چک';
      default:
        return 'نامشخص';
    }
  }
}
