import 'package:hive/hive.dart';

part 'cargo_type.g.dart';

@HiveType(typeId: 12)
class CargoType extends HiveObject {
  @HiveField(0)
  final String cargoName;

  @HiveField(1)
  final DateTime createdAt;

  @HiveField(2)
  DateTime updatedAt;

  CargoType({
    required this.cargoName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  @override
  String toString() => cargoName;
} 