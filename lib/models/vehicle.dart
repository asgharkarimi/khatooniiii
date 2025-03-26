import 'package:hive/hive.dart';

part 'vehicle.g.dart';

@HiveType(typeId: 1)
class Vehicle extends HiveObject {
  @HiveField(0)
  int? id;

  @HiveField(1)
  String vehicleName;
  
  @HiveField(2)
  String? smartCardNumber; // شماره هوشمند خودرو
  
  @HiveField(3)
  String? healthCode; // کد بهداشتی خودرو

  Vehicle({
    this.id,
    required this.vehicleName,
    this.smartCardNumber,
    this.healthCode,
  });
} 