import 'package:hive/hive.dart';

part 'cargo_type.g.dart';

@HiveType(typeId: 2)
class CargoType extends HiveObject {
  @HiveField(0)
  int? id;

  @HiveField(1)
  String cargoName;

  CargoType({
    this.id,
    required this.cargoName,
  });
} 