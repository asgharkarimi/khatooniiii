import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:khatooniiii/models/driver_salary.dart';
import 'package:khatooniiii/screens/driver_salary_form.dart';
import 'package:khatooniiii/utils/app_date_utils.dart';
import 'package:intl/intl.dart';
import 'package:khatooniiii/models/cargo.dart';
import 'package:khatooniiii/models/driver.dart';
import 'package:khatooniiii/models/driver_payment.dart';

class DriverSalaryList extends StatefulWidget {
  final Cargo? selectedCargo;
  final Driver? selectedDriver;

  const DriverSalaryList({
    super.key,
    this.selectedCargo,
    this.selectedDriver,
  });

  @override
  State<DriverSalaryList> createState() => _DriverSalaryListState();
}

class _DriverSalaryListState extends State<DriverSalaryList> {
  late Box<DriverSalary> _driverSalariesBox;
  double _totalPaid = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeBox();
  }

  Future<void> _initializeBox() async {
    try {
      _driverSalariesBox = await Hive.openBox<DriverSalary>('driverSalaries');
      final driverPaymentsBox = await Hive.openBox<DriverPayment>('driverPayments');
      
      print('\n========== لیست سرویس‌ها و حقوق راننده ==========');
      
      if (widget.selectedDriver != null) {
        print('\nمشخصات راننده:');
        print('شناسه راننده: ${widget.selectedDriver!.key}');
        print('نام راننده: ${widget.selectedDriver!.firstName} ${widget.selectedDriver!.lastName}');
        print('درصد حقوق: ${widget.selectedDriver!.salaryPercentage}%');
      }

      if (widget.selectedCargo != null) {
        print('\nاطلاعات سرویس:');
        print('شناسه سرویس: ${widget.selectedCargo!.key}');
        print('نوع سرویس: ${widget.selectedCargo!.cargoType.cargoName}');
        print('مسیر: ${widget.selectedCargo!.origin} -> ${widget.selectedCargo!.destination}');
        print('وزن: ${widget.selectedCargo!.weight} کیلوگرم');
        
        // Get payments for this cargo
        final cargoPayments = driverPaymentsBox.values
            .where((payment) => payment.cargoId == widget.selectedCargo!.key)
            .toList();
            
        print('\nپرداختی‌های سرویس:');
        print('تعداد پرداختی‌ها: ${cargoPayments.length}');
        
        if (cargoPayments.isNotEmpty) {
          double totalAmount = 0;
          print('\nجزئیات پرداختی‌ها:');
          for (var payment in cargoPayments) {
            print('-------------------');
            print('شناسه راننده: ${payment.driverId}');
            print('مبلغ: ${NumberFormat('#,###').format(payment.amount)} تومان');
            print('تاریخ: ${AppDateUtils.toPersianDate(payment.paymentDate)}');
            print('روش پرداخت: ${PaymentMethod.getTitle(payment.paymentMethod)}');
            if (payment.description?.isNotEmpty ?? false) {
              print('توضیحات: ${payment.description}');
            }
            totalAmount += payment.amount;
          }
          print('-------------------');
          print('مجموع پرداختی‌ها: ${NumberFormat('#,###').format(totalAmount)} تومان');
        } else {
          print('هیچ پرداختی برای این سرویس ثبت نشده است');
        }
      }
      
      // Get all payments for the selected driver
      if (widget.selectedDriver != null) {
        final driverPayments = driverPaymentsBox.values
            .where((payment) => payment.driverId == widget.selectedDriver!.key)
            .toList();
            
        print('\nکل پرداختی‌های راننده:');
        print('تعداد کل پرداختی‌ها: ${driverPayments.length}');
        
        if (driverPayments.isNotEmpty) {
          double totalAmount = 0;
          print('\nجزئیات تمام پرداختی‌ها:');
          for (var payment in driverPayments) {
            print('-------------------');
            print('شناسه سرویس: ${payment.cargoId}');
            print('مبلغ: ${NumberFormat('#,###').format(payment.amount)} تومان');
            print('تاریخ: ${AppDateUtils.toPersianDate(payment.paymentDate)}');
            print('روش پرداخت: ${PaymentMethod.getTitle(payment.paymentMethod)}');
            if (payment.description?.isNotEmpty ?? false) {
              print('توضیحات: ${payment.description}');
            }
            totalAmount += payment.amount;
          }
          print('-------------------');
          print('مجموع کل پرداختی‌ها: ${NumberFormat('#,###').format(totalAmount)} تومان');
        } else {
          print('هیچ پرداختی برای این راننده ثبت نشده است');
        }
      }
      
      print('\n===========================================');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error opening boxes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در بارگذاری لیست پرداختی‌ها')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.selectedCargo != null ? 'لیست پرداختی‌های سرویس' : 'لیست حقوق راننده'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    Colors.white,
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Header with total paid amount
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Cargo and Driver Info
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.selectedCargo != null)
                                  Text(
                                    'سرویس ${widget.selectedCargo!.cargoType.cargoName}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.selectedDriver != null 
                                      ? '${widget.selectedDriver!.firstName} ${widget.selectedDriver!.lastName}'
                                      : 'راننده انتخاب نشده',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            if (widget.selectedCargo != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'درصد حقوق: ${NumberFormat('#,##0.##').format(widget.selectedCargo!.driver.salaryPercentage)}%',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Total Payments Info
                        ValueListenableBuilder(
                          valueListenable: _driverSalariesBox.listenable(),
                          builder: (context, Box<DriverSalary> box, _) {
                            final salaries = box.values.where((salary) {
                              if (widget.selectedCargo != null) {
                                return salary.cargo?.key == widget.selectedCargo!.key;
                              }
                              return true;
                            }).toList();

                            _totalPaid = salaries.fold(0.0, (sum, salary) => sum + salary.amount);

                            return Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: const Text(
                                        'مجموع پرداختی‌ها:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${NumberFormat('#,###').format(_totalPaid.abs())} تومان',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                if (widget.selectedCargo != null) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: const Text(
                                          'تعداد پرداختی‌ها:',
                                          style: TextStyle(
                                            fontSize: 14,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${salaries.length} مورد',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // List of payments
                  Expanded(
                    child: _buildSalaryList(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSalaryList() {
    return ValueListenableBuilder(
      valueListenable: _driverSalariesBox.listenable(),
      builder: (context, Box<DriverSalary> box, _) {
        // Get all salaries
        List<DriverSalary> salaries = box.values.toList();
        
        print('\nDEBUG: Building salary list');
        print('Total salaries before filtering: ${salaries.length}');

        // Filter by cargo ID if selected
        if (widget.selectedCargo != null) {
          final cargoId = widget.selectedCargo!.key;
          final driverId = widget.selectedCargo!.driver?.key;
          
          print('\nFiltering by:');
          print('Cargo ID: $cargoId');
          print('Driver ID: $driverId');
          
          if (driverId != null) {
            salaries = salaries.where((salary) {
              final matchesCargo = salary.cargo?.key == cargoId;
              final matchesDriver = salary.driver?.key == driverId;
              print('\nChecking salary:');
              print('Salary Cargo ID: ${salary.cargo?.key}');
              print('Salary Driver ID: ${salary.driver?.key}');
              print('Matches Cargo: $matchesCargo');
              print('Matches Driver: $matchesDriver');
              return matchesCargo && matchesDriver;
            }).toList();
            
            print('\nSalaries after filtering:');
            print('Count: ${salaries.length}');
            
            // Load driver payments
            _loadDriverPayments(driverId);
          } else {
            print('Warning: Driver ID is null for cargo $cargoId');
          }
        }

        // Sort by date (newest first)
        salaries.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
        
        if (salaries.isNotEmpty) {
          print('\nFound salaries:');
          for (var salary in salaries) {
            print('Amount: ${salary.amount}');
            print('Date: ${salary.paymentDate}');
            print('Cargo: ${salary.cargo?.cargoType.cargoName}');
            print('Driver ID: ${salary.driver?.key}');
            print('Driver: ${salary.driver?.firstName} ${salary.driver?.lastName}');
          }
        }
        
        if (salaries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.payment_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  widget.selectedCargo != null 
                      ? 'هیچ پرداختی برای این سرویس ثبت نشده است'
                      : 'لیست حقوق‌های راننده خالی است',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: salaries.length,
          itemBuilder: (context, index) {
            final salary = salaries[index];
            return _buildSalaryItem(salary);
          },
        );
      },
    );
  }

  Future<void> _loadDriverPayments(int driverId) async {
    try {
      final driverPaymentsBox = await Hive.openBox<DriverPayment>('driverPayments');
      
      print('\n=== Loading Driver Payments ===');
      print('Driver ID: $driverId');
      
      if (driverId <= 0) {
        print('Warning: Invalid driver ID: $driverId');
        return;
      }
      
      final payments = driverPaymentsBox.values
          .where((payment) => payment.driverId == driverId)
          .toList();
      
      print('Found ${payments.length} payments');
      
      if (payments.isNotEmpty) {
        double totalAmount = 0;
        print('\nPayment Details:');
        for (var payment in payments) {
          print('-------------------');
          print('Payment ID: ${payment.key}');
          print('Cargo ID: ${payment.cargoId}');
          print('Amount: ${NumberFormat('#,###').format(payment.amount)} تومان');
          print('Date: ${AppDateUtils.toPersianDate(payment.paymentDate)}');
          print('Payment Method: ${PaymentMethod.getTitle(payment.paymentMethod)}');
          if (payment.description?.isNotEmpty ?? false) {
            print('Description: ${payment.description}');
          }
          totalAmount += payment.amount;
        }
        print('-------------------');
        print('Total Amount: ${NumberFormat('#,###').format(totalAmount)} تومان');
      }
      
      print('============================\n');
      
    } catch (e) {
      print('Error loading driver payments: $e');
    }
  }

  Widget _buildSalaryItem(DriverSalary salary) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${salary.getFormattedAmount()} تومان',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    PaymentMethod.getTitle(salary.paymentMethod),
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  salary.getFormattedDate(),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            if (salary.cargo != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.local_shipping, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'سرویس ${salary.cargo!.cargoType.cargoName}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'شناسه سرویس: ${salary.cargo!.key}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            if (salary.percentage != null) ...[
              const SizedBox(height: 4),
              Text(
                'درصد: ${salary.percentage}%',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
            if (salary.description?.isNotEmpty ?? false) ...[
              const SizedBox(height: 4),
              Text(
                'توضیحات: ${salary.description}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _deleteSalary(DriverSalary salary) {
    final box = Hive.box<DriverSalary>('driverSalaries');
    box.delete(salary.key);
  }

  void _editSalary(BuildContext context, DriverSalary salary) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriverSalaryForm(driverSalary: salary),
      ),
    );
  }

  String _getPaymentMethodText(int paymentMethod) {
    switch (paymentMethod) {
      case 0:
        return 'کارت به کارت';
      case 1:
        return 'انتقال بانکی';
      case 2:
        return 'چک';
      default:
        return 'نامشخص';
    }
  }

  Widget _buildDetailItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$title: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  double _calculateTotalSalary(List<DriverSalary> salaries) {
    return salaries.fold(0.0, (sum, salary) => sum + salary.amount);
  }

  double _calculateTotalPayments(List<DriverSalary> salaries) {
    return salaries.fold(0.0, (sum, salary) => sum + salary.amount);
  }

  double _calculateTotalDebt(List<DriverSalary> salaries) {
    final totalSalary = _calculateTotalSalary(salaries);
    final totalPayments = _calculateTotalPayments(salaries);
    return totalSalary - totalPayments;
  }

  Future<List<DriverSalary>> _getPaymentsByCargo(int cargoId) async {
    final box = await Hive.openBox<DriverSalary>('driverSalaries');
    
    print('\n=== Fetching Payments for Cargo ID: $cargoId ===');
    final payments = box.values.where((payment) {
      final matches = payment.cargoId == cargoId;
      print('Checking Payment:');
      print('Payment ID: ${payment.id}');
      print('Payment Cargo ID: ${payment.cargoId}');
      print('Amount: ${payment.getFormattedAmount()} toman');
      print('Date: ${payment.getFormattedDate()}');
      print('Matches Cargo ID: $matches');
      print('-------------------');
      return matches;
    }).toList();
    
    print('Total Payments Found: ${payments.length}');
    if (payments.isNotEmpty) {
      final totalAmount = payments.fold(0.0, (sum, payment) => sum + payment.amount);
      print('Total Amount: ${NumberFormat('#,###').format(totalAmount)} toman');
    }
    print('=====================================\n');
    
    return payments;
  }

  Widget _buildPaymentList() {
    return FutureBuilder<List<DriverSalary>>(
      future: _getPaymentsByCargo(widget.selectedCargo?.key ?? -1),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final payments = snapshot.data ?? [];
        
        if (payments.isEmpty) {
          return const Center(
            child: Text('هیچ پرداختی برای این سرویس ثبت نشده است'),
          );
        }

        return ListView.builder(
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final payment = payments[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: ListTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${payment.getFormattedAmount()} تومان'),
                    Text('شناسه سرویس: ${payment.cargoId}'),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('تاریخ: ${payment.getFormattedDate()}'),
                    Text('روش پرداخت: ${PaymentMethod.getTitle(payment.paymentMethod)}'),
                    if (payment.description?.isNotEmpty ?? false)
                      Text('توضیحات: ${payment.description}'),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<DriverPayment>> _getPaymentsByDriver(int driverId) async {
    final box = await Hive.openBox<DriverPayment>('driverPayments');
    
    print('\n=== Fetching Payments for Driver ID: $driverId ===');
    final payments = box.values.where((payment) {
      final matches = payment.driverId == driverId;
      print('Checking Payment:');
      print('Payment Amount: ${NumberFormat('#,###').format(payment.amount)} toman');
      print('Payment Date: ${AppDateUtils.toPersianDate(payment.paymentDate)}');
      print('Driver ID: ${payment.driverId}');
      print('Cargo ID: ${payment.cargoId}');
      print('Matches Driver ID: $matches');
      print('-------------------');
      return matches;
    }).toList();
    
    print('Total Payments Found: ${payments.length}');
    if (payments.isNotEmpty) {
      final totalAmount = payments.fold(0.0, (sum, payment) => sum + payment.amount);
      print('Total Amount: ${NumberFormat('#,###').format(totalAmount)} toman');
    }
    print('=====================================\n');
    
    return payments;
  }

  Widget _buildDriverPaymentList() {
    if (widget.selectedDriver == null) {
      return const Center(child: Text('راننده انتخاب نشده است'));
    }

    return FutureBuilder<List<DriverPayment>>(
      future: _getPaymentsByDriver(widget.selectedDriver!.key),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final payments = snapshot.data ?? [];
        
        if (payments.isEmpty) {
          return const Center(
            child: Text('هیچ پرداختی برای این راننده ثبت نشده است'),
          );
        }

        return ListView.builder(
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final payment = payments[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: ListTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${NumberFormat('#,###').format(payment.amount)} تومان'),
                    Text('شناسه سرویس: ${payment.cargoId}'),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('تاریخ: ${AppDateUtils.toPersianDate(payment.paymentDate)}'),
                    Text('روش پرداخت: ${PaymentMethod.getTitle(payment.paymentMethod)}'),
                    if (payment.description?.isNotEmpty ?? false)
                      Text('توضیحات: ${payment.description}'),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
} 