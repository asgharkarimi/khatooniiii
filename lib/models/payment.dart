import 'package:hive/hive.dart';
import 'package:khatooniiii/models/cargo.dart';
import 'package:khatooniiii/models/customer.dart';

part 'payment.g.dart';

@HiveType(typeId: 6)
class PaymentType {
  static const int cash = 0;
  static const int check = 1;
  static const int cardToCard = 2;
  static const int bankTransfer = 3;
}

@HiveType(typeId: 7)
class PayerType {
  static const int driverToCompany = 0;
  static const int customerToDriver = 1;
}

@HiveType(typeId: 8)
class Payment extends HiveObject {
  @HiveField(0)
  int? id;

  @HiveField(1)
  int paymentType; // Uses PaymentType constants

  @HiveField(2)
  int payerType; // Uses PayerType constants

  @HiveField(3)
  Customer customer;

  @HiveField(4)
  Cargo cargo;

  @HiveField(5)
  double amount;

  @HiveField(6)
  String? cardToCardReceiptImagePath;

  @HiveField(7)
  String? checkImagePath;

  @HiveField(8)
  DateTime? checkDueDate;

  @HiveField(9)
  DateTime paymentDate;

  Payment({
    this.id,
    required this.paymentType,
    required this.payerType,
    required this.customer,
    required this.cargo,
    required this.amount,
    this.cardToCardReceiptImagePath,
    this.checkImagePath,
    this.checkDueDate,
    required this.paymentDate,
  });
} 