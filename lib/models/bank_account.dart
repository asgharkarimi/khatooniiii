import 'package:hive/hive.dart';

part 'bank_account.g.dart';

@HiveType(typeId: 14)
class BankAccount extends HiveObject {
  @HiveField(0)
  final int? id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String? accountNumber;

  @HiveField(3)
  final String? cardNumber;

  @HiveField(4)
  final String? sheba;

  @HiveField(5)
  final String bankName;

  @HiveField(6)
  final String ownerName;

  @HiveField(7)
  final bool isDefault;

  BankAccount({
    this.id,
    required this.title,
    this.accountNumber,
    this.cardNumber,
    this.sheba,
    required this.bankName,
    required this.ownerName,
    this.isDefault = false,
  });
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BankAccount) return false;
    return id == other.id && 
           title == other.title &&
           accountNumber == other.accountNumber &&
           cardNumber == other.cardNumber &&
           sheba == other.sheba;
  }
  
  @override
  int get hashCode => Object.hash(id, title, accountNumber, cardNumber, sheba);
} 