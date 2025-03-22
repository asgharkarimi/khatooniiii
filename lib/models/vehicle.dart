import 'package:hive/hive.dart';

part 'vehicle.g.dart';

@HiveType(typeId: 1)
class Vehicle extends HiveObject {
  @HiveField(0)
  int? id;

  @HiveField(1)
  String vehicleName;

  Vehicle({
    this.id,
    required this.vehicleName,
  });
} 