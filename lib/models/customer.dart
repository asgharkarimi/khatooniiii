import 'package:hive/hive.dart';

part 'customer.g.dart';

@HiveType(typeId: 3)
class Customer extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String firstName;

  @HiveField(2)
  final String lastName;

  @HiveField(3)
  final String phoneNumber;

  @HiveField(4)
  final String? address;

  Customer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    this.address,
  });
} 