import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'driver.g.dart';

@HiveType(typeId: 0)
class Driver extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String nationalId;

  @HiveField(3)
  String mobile;

  @HiveField(4)
  String licenseNumber;

  @HiveField(5)
  String address;

  @HiveField(6)
  String? imagePath;
  
  @HiveField(7)
  String firstName;
  
  @HiveField(8)
  String lastName;
  
  @HiveField(9)
  String? licenseImagePath;
  
  @HiveField(10)
  String password;

  Driver({
    String? id,
    required this.name,
    required this.nationalId,
    required this.mobile,
    required this.licenseNumber,
    this.address = '',
    this.imagePath,
    String? firstName,
    String? lastName,
    this.licenseImagePath,
    String? password,
  }) : 
    id = id ?? const Uuid().v4(),
    firstName = firstName ?? name.split(' ').first,
    lastName = lastName ?? (name.split(' ').length > 1 ? name.split(' ').skip(1).join(' ') : ''),
    password = password ?? '';
} 