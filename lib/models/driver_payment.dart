import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:khatooniiii/models/driver.dart';
import 'package:khatooniiii/models/cargo.dart';

part 'driver_payment.g.dart';

@HiveType(typeId: 11) // Make sure this ID is unique in your Hive setup
class DriverPayment extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final Driver driver;

  @HiveField(2)
  final Cargo cargo;

  @HiveField(3)
  final double amount;

  @HiveField(4)
  final DateTime paymentDate;

  @HiveField(5)
  final int paymentMethod; // 0: Cash, 1: Bank Transfer, 2: Check

  @HiveField(6)
  final String? description;

  @HiveField(7)
  String? cargoId; // Changed from int? to String? to match Cargo.key type

  @HiveField(8)
  final double calculatedSalary; // حقوق محاسبه شده کل

  @HiveField(9)
  final double totalPaidAmount; // مجموع پرداختی‌های قبلی

  @HiveField(10)
  final double remainingAmount; // مبلغ باقیمانده

  @HiveField(11)
  final DateTime createdAt;

  @HiveField(12)
  String? driverId; // Changed from int? to String? to match Driver.key type

  DriverPayment({
    String? id,
    required this.driver,
    required this.cargo,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    this.description,
    String? cargoId,
    required this.calculatedSalary,
    required this.totalPaidAmount,
    required this.remainingAmount,
    String? driverId,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = DateTime.now(),
    // Set default values for cargoId and driverId if not provided
    cargoId = cargoId ?? cargo.key,
    driverId = driverId ?? driver.key;
}

// Payment method constants
class DriverPaymentMethod {
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