import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:khatooniiii/models/driver.dart';
import 'package:khatooniiii/models/cargo.dart';
import 'package:intl/intl.dart';
import 'package:khatooniiii/utils/app_date_utils.dart';

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

  @HiveField(9)
  double? calculatedSalary;

  @HiveField(10)
  double? totalPaidAmount;

  @HiveField(11)
  double remainingAmount;

  @HiveField(12)
  int? cargoId;

  DriverSalary({
    String? id,
    required this.driver,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    this.description,
    this.percentage,
    this.cargo,
    this.calculatedSalary,
    this.totalPaidAmount,
    this.remainingAmount = 0.0,
    this.cargoId,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = DateTime.now();

  // Add method to check if salary is for a specific cargo
  bool isForCargo(Cargo cargo) {
    if (this.cargo == null) return false;
    return this.cargo!.key == cargo.key;
  }

  // Add method to check if salary is for a specific driver
  bool isForDriver(Driver driver) {
    return this.driver.key == driver.key;
  }

  // Add method to get formatted amount
  String getFormattedAmount() {
    return NumberFormat('#,###').format(amount.abs());
  }

  // Add method to get formatted date
  String getFormattedDate() {
    return AppDateUtils.toPersianDate(paymentDate);
  }

  // Add method to get cargo name
  String? getCargoName() {
    return cargo?.cargoType.cargoName;
  }

  // Add method to get cargo key
  String? getCargoKey() {
    return cargo?.key;
  }
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
