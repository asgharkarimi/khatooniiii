import 'package:hive/hive.dart';

part 'customer.g.dart';

@HiveType(typeId: 4)
class Customer {
  @HiveField(0)
  final String firstName;

  @HiveField(1)
  final String lastName;

  @HiveField(2)
  final String phone;

  @HiveField(3)
  final String? address;

  Customer({
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.address,
  });
} 