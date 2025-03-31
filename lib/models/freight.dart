import 'package:hive/hive.dart';

part 'freight.g.dart';

@HiveType(typeId: 10)
class Freight extends HiveObject {
  @HiveField(0)
  int? id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String phoneNumber;

  Freight({
    this.id,
    required this.name,
    required this.phoneNumber,
  });
} 