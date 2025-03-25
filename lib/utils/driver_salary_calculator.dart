import 'package:hive_flutter/hive_flutter.dart';
import 'package:khatooniiii/models/cargo.dart';
import 'package:khatooniiii/models/driver_salary.dart';
import 'package:khatooniiii/models/driver.dart';

class DriverSalaryCalculator {
  final Driver driver;
  final Cargo cargo;
  final Box<DriverSalary> driverSalariesBox;

  DriverSalaryCalculator({
    required this.driver,
    required this.cargo,
    required this.driverSalariesBox,
  });

  // Calculate total transport cost
  double calculateTotalTransportCost() {
    return cargo.totalTransportCost.abs();
  }

  // Calculate net amount after subtracting waybill
  double calculateNetAmount() {
    return ((cargo.waybillAmount ?? 0) - cargo.totalTransportCost).abs();
  }

  // Calculate driver's share based on percentage
  double calculateDriverShare() {
    // Get the salary percentage from the driver table
    final salaryPercentage = driver.salaryPercentage;
    final netAmount = calculateNetAmount();
    return (netAmount * salaryPercentage) / 100;
  }

  // Calculate remaining amount after previous payments
  double calculateRemainingAmount() {
    final driverShare = calculateDriverShare();
    final previousPayments = getPreviousPaymentsTotal();
    return (driverShare - previousPayments).abs();
  }

  // Get total paid amount including previous payments
  double getPreviousPaymentsTotal() {
    return driverSalariesBox.values
        .where((salary) => salary.cargo?.key == cargo.key)
        .fold(0, (sum, salary) => sum + salary.amount.abs());
  }

  // Calculate percentage of total salary that has been paid
  double calculatePaidPercentage() {
    final totalShare = calculateDriverShare();
    if (totalShare == 0) return 0;
    return (getPreviousPaymentsTotal() / totalShare) * 100;
  }

  // Static method to get previous payments for a cargo
  static double getPreviousPaymentsForCargo(Cargo cargo) {
    final driverSalariesBox = Hive.box<DriverSalary>('driverSalaries');
    return driverSalariesBox.values
        .where((salary) => salary.cargo?.key == cargo.key)
        .fold(0.0, (sum, salary) => sum + (salary.amount ?? 0));
  }

  // Static method to create calculator with previous payments
  static DriverSalaryCalculator withPreviousPayments(Driver driver, Cargo cargo) {
    final previousPayments = getPreviousPaymentsForCargo(cargo);
    return DriverSalaryCalculator(
      driver: driver,
      cargo: cargo,
      driverSalariesBox: Hive.box<DriverSalary>('driverSalaries'),
    );
  }

  static DriverSalaryCalculator create({
    required Driver driver,
    required Cargo cargo,
  }) {
    return DriverSalaryCalculator(
      driver: driver,
      cargo: cargo,
      driverSalariesBox: Hive.box<DriverSalary>('driverSalaries'),
    );
  }
} 