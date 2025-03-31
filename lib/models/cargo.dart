import 'package:hive/hive.dart';
import 'package:khatooniiii/models/vehicle.dart';
import 'package:khatooniiii/models/driver.dart';
import 'package:khatooniiii/models/cargo_type.dart';
import 'package:khatooniiii/models/driver_payment.dart';
import 'package:khatooniiii/models/freight.dart';

part 'cargo.g.dart';

@HiveType(typeId: 4)
class PaymentStatus {
  static const int pending = 0;
  static const int partiallyPaid = 1;
  static const int fullyPaid = 2;
}

@HiveType(typeId: 5)
class Cargo extends HiveObject {
  @HiveField(0)
  int? id;

  @HiveField(1)
  Vehicle vehicle;

  @HiveField(2)
  Driver driver;

  @HiveField(3)
  CargoType cargoType;

  @HiveField(4)
  String origin;

  @HiveField(5)
  String destination;

  @HiveField(6)
  DateTime date;

  @HiveField(7)
  double weight; // وزن بر حسب کیلوگرم

  @HiveField(8)
  double pricePerTon; // قیمت هر تن بر حسب تومان

  @HiveField(9)
  int paymentStatus; // Uses PaymentStatus constants
  
  @HiveField(10)
  double transportCostPerTon; // هزینه حمل هر تن بر حسب تومان

  @HiveField(11)
  double? waybillAmount; // مبلغ بارنامه

  @HiveField(12)
  String? waybillImagePath; // مسیر عکس بارنامه

  @HiveField(13)
  DateTime? unloadingDate; // تاریخ تخلیه

  @HiveField(14)
  HiveList<DriverPayment>? driverPayments;

  @HiveField(15)
  String? bankAccount; // شماره شبا یا حساب اعلامی جهت واریز هزینه سرویس

  @HiveField(16)
  String? bankName; // نام بانک

  @HiveField(17)
  String? accountOwnerName; // نام صاحب حساب

  @HiveField(18)
  String? loadingAddress; // آدرس بارگیری

  @HiveField(19)
  String? unloadingAddress; // آدرس تخلیه

  @HiveField(20)
  String? recipientContactNumber; // شماره تماس تحویل گیرنده بار

  @HiveField(21)
  Freight? freight;

  Cargo({
    this.id,
    required this.vehicle,
    required this.driver,
    required this.cargoType,
    required this.origin,
    required this.destination,
    required this.date,
    this.unloadingDate,
    required this.weight,
    required this.pricePerTon,
    this.paymentStatus = PaymentStatus.pending,
    this.transportCostPerTon = 0, // Default value is 0
    this.waybillAmount = 0, // Default value
    this.waybillImagePath,
    this.driverPayments,
    this.bankAccount,
    this.bankName,
    this.accountOwnerName,
    this.loadingAddress,
    this.unloadingAddress,
    this.recipientContactNumber,
    this.freight,
  });

  // وزن را به تن تبدیل می‌کند (هر تن = 1000 کیلوگرم)
  double get weightInTons => weight / 1000;

  // قیمت کل بر اساس وزن (تن) و قیمت هر تن (تومان)
  // اگر وزن صفر باشد، از مقدار pricePerTon به عنوان قیمت کل استفاده می‌شود
  double get totalPrice => weight > 0 ? weightInTons * (pricePerTon ?? 0) : (pricePerTon ?? 0);
  
  // هزینه حمل کل بر اساس وزن (تن) و هزینه حمل هر تن (تومان)
  // اگر وزن صفر باشد، از مقدار transportCostPerTon به عنوان هزینه کل استفاده می‌شود
  double get totalTransportCost => weight > 0 ? weightInTons * (transportCostPerTon ?? 0) : (transportCostPerTon ?? 0);
  
  // سود خالص: قیمت کل منهای هزینه حمل کل
  double get netProfit => totalPrice - totalTransportCost;
  
  // تعیین حالت گزارش‌گیری بر اساس وزن و هزینه حمل
  String get reportingMode {
    if (weight == 0 && transportCostPerTon > 0) {
      return 'بر اساس هزینه حمل';
    } else if (weight > 0 && transportCostPerTon == 0) {
      return 'بر اساس وزن';
    } else if (weight > 0 && transportCostPerTon > 0) {
      return 'ترکیبی';
    } else {
      return 'نامشخص';
    }
  }
  
  // تعیین آیا این سرویس مقطوع است
  bool get isFixedPrice => weight == 0;

  // Get total amount paid to driver
  double get totalDriverPayments {
    if (driverPayments == null || driverPayments!.isEmpty) return 0;
    return driverPayments!.fold(0, (sum, payment) => sum + payment.amount);
  }
  
  // Get remaining amount to be paid to driver
  double getRemainingDriverPayment(double calculatedSalary) {
    return calculatedSalary - totalDriverPayments;
  }
  
  // Add a payment to this cargo
  void addDriverPayment(DriverPayment payment, Box<DriverPayment> box) {
    try {
      print('Adding driver payment to cargo - debug info:');
      print('Cargo key: ${key}');
      print('Payment cargoId: ${payment.cargoId}');
      print('Payment ID: ${payment.id}');
      
      // Get this cargo's key as a String with explicit conversion
      final String cargoKey = key != null ? key.toString() : '';
      
      print('Cargo key converted to String: $cargoKey');
      
      // Update payment cargoId if needed to ensure consistency
      if (payment.cargoId != cargoKey && cargoKey.isNotEmpty) {
        print('Updating payment cargoId from "${payment.cargoId}" to "$cargoKey"');
        payment.cargoId = cargoKey;
        payment.save();
      }
      
      // Initialize HiveList if needed
      if (driverPayments == null) {
        print('Creating new HiveList for driverPayments');
        driverPayments = HiveList<DriverPayment>(box);
      }
      
      // Add the payment to the HiveList
      print('Adding payment to driverPayments list');
      driverPayments!.add(payment);
      
      // Save the cargo object
      print('Saving cargo after adding payment');
      save();
      print('Successfully added payment to cargo');
    } catch (e) {
      print('Error adding driver payment to cargo: $e');
    }
  }
} 