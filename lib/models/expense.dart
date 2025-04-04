import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:khatooniiii/models/cargo.dart';

part 'expense.g.dart';

@HiveType(typeId: 6)
class Expense extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  double amount;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  String category;

  @HiveField(5)
  String description;

  @HiveField(6)
  String? imagePath;
  
  @HiveField(7)
  Cargo? cargo;

  Expense({
    String? id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.description = '',
    this.imagePath,
    this.cargo,
  }) : id = id ?? const Uuid().v4();
} 