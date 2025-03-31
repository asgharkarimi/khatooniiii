import 'package:hive/hive.dart';

part 'address.g.dart';

@HiveType(typeId: 13)
class Address extends HiveObject {
  @HiveField(0)
  int? id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String province;

  @HiveField(3)
  String city;

  @HiveField(4)
  String? details;

  @HiveField(5)
  String? postalCode;

  @HiveField(6)
  String? contactName;

  @HiveField(7)
  String? contactPhone;

  Address({
    this.id,
    required this.title,
    required this.province,
    required this.city,
    this.details,
    this.postalCode,
    this.contactName,
    this.contactPhone,
  });

  @override
  String toString() {
    return '$province، $city${details != null ? '، $details' : ''}';
  }

  @override
  String getFullAddress() {
    return '$province، $city${details != null ? '، $details' : ''}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Address) return false;
    return id == other.id && 
           title == other.title &&
           province == other.province &&
           city == other.city &&
           details == other.details;
  }
  
  @override
  int get hashCode => Object.hash(id, title, province, city, details);
} 