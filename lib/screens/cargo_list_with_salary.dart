import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:khatooniiii/models/cargo.dart';
import 'package:khatooniiii/screens/driver_salary_form.dart';
import 'package:khatooniiii/models/driver_salary.dart';
import 'package:khatooniiii/utils/app_date_utils.dart';
import 'package:khatooniiii/screens/driver_salary_list.dart';
import 'package:khatooniiii/utils/driver_salary_calculator.dart';

class CargoListWithSalary extends StatefulWidget {
  const CargoListWithSalary({super.key});

  @override
  State<CargoListWithSalary> createState() => _CargoListWithSalaryState();
}

class _CargoListWithSalaryState extends State<CargoListWithSalary> {
  late Box<DriverSalary> _driverSalariesBox;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeBox();
    _printCargoList();
  }

  Future<void> _initializeBox() async {
    try {
      _driverSalariesBox = await Hive.openBox<DriverSalary>('driverSalaries');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error opening driver salaries box: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در بارگذاری لیست پرداختی‌ها')),
        );
      }
    }
  }

  Future<void> _printCargoList() async {
    try {
      final cargosBox = await Hive.openBox<Cargo>('cargos');
      final cargos = cargosBox.values.toList();
      
      print('\n============= APP CARGO LIST =============');
      print('Total Cargos in App: ${cargos.length}');
      
      for (var cargo in cargos) {
        print('\n--- Cargo Entry ---');
        print('Cargo Key/ID: ${cargo.key}');
        print('Type: ${cargo.cargoType.cargoName}');
        print('Driver: ${cargo.driver.firstName} ${cargo.driver.lastName}');
        print('Driver ID: ${cargo.driver.key}');
        print('Route: ${cargo.origin} -> ${cargo.destination}');
        print('Weight: ${NumberFormat('#,###').format(cargo.weight)} kg');
        print('Price/Ton: ${NumberFormat('#,###').format(cargo.pricePerTon)} toman');
        print('Transport Cost/Ton: ${NumberFormat('#,###').format(cargo.transportCostPerTon)} toman');
        print('Date: ${AppDateUtils.toPersianDate(cargo.date)}');
        if (cargo.waybillAmount != null) {
          print('Waybill Amount: ${NumberFormat('#,###').format(cargo.waybillAmount!)} toman');
        }
        print('Driver Salary Percentage: ${cargo.driver.salaryPercentage}%');
        print('---------------------------');
      }
      
      print('=========================================\n');
    } catch (e) {
      print('Error printing cargo list: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لیست سرویس‌ها و حقوق'),
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
              child: _buildCargoList(),
            ),
    );
  }

  Widget _buildCargoList() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Cargo>('cargos').listenable(),
      builder: (context, Box<Cargo> box, _) {
        final cargos = box.values.toList();
        
        // Debug print all cargos
        print('\n========== CARGO LIST DEBUG ==========');
        print('Total number of cargos: ${cargos.length}');
        
        for (var cargo in cargos) {
          print('\n--- Cargo Details ---');
          print('Cargo ID: ${cargo.key}');
          print('Cargo Type: ${cargo.cargoType.cargoName}');
          print('Driver: ${cargo.driver.firstName} ${cargo.driver.lastName}');
          print('Route: ${cargo.origin} -> ${cargo.destination}');
          print('Weight: ${cargo.weight} kg');
          print('Price per ton: ${cargo.pricePerTon} toman');
          print('Transport cost per ton: ${cargo.transportCostPerTon} toman');
          print('Driver salary percentage: ${cargo.driver.salaryPercentage}%');
          print('Date: ${cargo.date}');
          if (cargo.waybillAmount != null) {
            print('Waybill amount: ${cargo.waybillAmount} toman');
          }
          print('------------------------');
        }
        print('=====================================\n');
        
        if (cargos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'لیست سرویس‌ها خالی است',
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
          itemCount: cargos.length,
          itemBuilder: (context, index) {
            final cargo = cargos[index];
            return _buildCargoItem(context, cargo);
          },
        );
      },
    );
  }

  Widget _buildCargoItem(BuildContext context, Cargo cargo) {
    // Get salaries for this cargo, handling null values
    final salaries = _driverSalariesBox.values
        .where((salary) {
          print('\n=== Searching Payments for Cargo ID ===');
          if (salary.cargo == null) {
            print('WARNING: Found salary with null cargo - Skipping');
            return false;
          }
          
          print('Checking Payment:');
          print('Payment Cargo ID: ${salary.cargo!.key}');
          print('Searching for Cargo ID: ${cargo.key}');
          
          final matches = salary.cargo!.key == cargo.key;
          print('Match found: $matches');
          
          if (matches) {
            print('Payment Details:');
            print('- Amount: ${NumberFormat('#,###').format(salary.amount)} toman');
            print('- Date: ${AppDateUtils.toPersianDate(salary.paymentDate)}');
            print('- Method: ${PaymentMethod.getTitle(salary.paymentMethod)}');
            if (salary.description?.isNotEmpty ?? false) {
              print('- Description: ${salary.description}');
            }
          }
          
          print('-----------------------------------');
          return matches;
        })
        .toList();

    print('\nSearch Results for Cargo ID: ${cargo.key}');
    print('Total Payments Found: ${salaries.length}');
    if (salaries.isNotEmpty) {
      final totalAmount = salaries.fold(0.0, (sum, salary) => sum + salary.amount);
      print('Total Amount: ${NumberFormat('#,###').format(totalAmount)} toman');
    }
    print('===================================\n');

    final totalPaid = salaries.fold(0.0, (sum, salary) => sum + salary.amount);
    final totalTransportCost = cargo.weight > 0 ? 
        (cargo.weight / 1000) * cargo.transportCostPerTon : 
        cargo.transportCostPerTon;

    // Calculate driver's salary using the driver's percentage
    final calculator = DriverSalaryCalculator.create(
      driver: cargo.driver,
      cargo: cargo,
    );
    final calculatedSalary = calculator.calculateDriverShare();
    final remainingAmount = calculatedSalary - totalPaid;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Icon(
                Icons.local_shipping,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'سرویس ${cargo.cargoType.cargoName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${cargo.driver.firstName} ${cargo.driver.lastName}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'شناسه سرویس: ${cargo.key}',
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
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                AppDateUtils.toPersianDate(cargo.date),
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // اطلاعات سرویس
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'اطلاعات سرویس',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Divider(),
                      _buildDetailItem('مسیر', '${cargo.origin} به ${cargo.destination}'),
                      _buildDetailItem('وزن', '${NumberFormat('#,###').format(cargo.weight.abs())} کیلوگرم'),
                      _buildDetailItem('قیمت هر تن', '${NumberFormat('#,###').format(cargo.pricePerTon.abs())} تومان'),
                      _buildDetailItem('هزینه حمل هر تن', '${NumberFormat('#,###').format(cargo.transportCostPerTon.abs())} تومان'),
                      _buildDetailItem('هزینه کل حمل', '${NumberFormat('#,###').format(totalTransportCost.abs())} تومان'),
                      if (cargo.waybillAmount != null)
                        _buildDetailItem('مبلغ بارنامه', '${NumberFormat('#,###').format(cargo.waybillAmount!.abs())} تومان'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // اطلاعات حقوق
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'اطلاعات حقوق',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'درصد حقوق: ${NumberFormat('#,##0.##').format(cargo.driver.salaryPercentage)}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      _buildDetailItem('حقوق کل', '${NumberFormat('#,###').format(calculatedSalary.abs())} تومان'),
                      _buildDetailItem('پرداختی‌های قبلی', '${NumberFormat('#,###').format(totalPaid.abs())} تومان'),
                      _buildDetailItem('مانده حقوق', '${NumberFormat('#,###').format((calculatedSalary - totalPaid).abs())} تومان'),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'پرداختی‌های انجام شده (${salaries.length} مورد)',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'مجموع: ${NumberFormat('#,###').format(totalPaid.abs())} تومان',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      if (salaries.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          child: Text(
                            'هیچ حقوقی برای این سرویس پرداخت نشده است',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: salaries.length,
                          itemBuilder: (context, index) {
                            final salary = salaries[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade100),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${NumberFormat('#,###').format(salary.amount.abs())} تومان',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
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
                                      Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        AppDateUtils.toPersianDate(salary.paymentDate),
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
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
                            );
                          },
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // دکمه اضافه کردن حقوق جدید
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DriverSalaryForm(
                                selectedCargo: cargo,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text(
                          'افزودن پرداختی جدید',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            // Ensure the box is opened
                            final driverSalariesBox = await Hive.openBox<DriverSalary>('driverSalaries');
                            
                            // Debug logging for cargo and payments
                            print('\n========== CARGO WITH PAYMENTS DEBUG ==========');
                            print('Current Cargo Details:');
                            print('Cargo ID: ${cargo.key}');
                            print('Cargo Type: ${cargo.cargoType.cargoName}');
                            print('Driver: ${cargo.driver.firstName} ${cargo.driver.lastName}');
                            
                            // Get all salaries for this cargo
                            final salaries = driverSalariesBox.values
                                .where((salary) => salary.cargo?.key == cargo.key)
                                .toList();
                                
                            print('\nPayments Information:');
                            print('Total number of payments: ${salaries.length}');
                            
                            // Print each payment's details
                            for (var salary in salaries) {
                              print('\n--- Payment Details ---');
                              print('Payment Amount: ${NumberFormat('#,###').format(salary.amount)} toman');
                              print('Payment Date: ${AppDateUtils.toPersianDate(salary.paymentDate)}');
                              print('Payment Method: ${PaymentMethod.getTitle(salary.paymentMethod)}');
                              print('Associated Cargo ID: ${salary.cargo?.key}');
                              if (salary.description?.isNotEmpty ?? false) {
                                print('Description: ${salary.description}');
                              }
                              print('------------------------');
                            }
                            
                            double totalPaid = salaries.fold(0.0, (sum, salary) => sum + salary.amount);
                            print('\nSummary:');
                            print('Total Paid Amount: ${NumberFormat('#,###').format(totalPaid)} toman');
                            print('==========================================\n');
                            
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DriverSalaryList(
                                    selectedCargo: cargo,
                                    selectedDriver: cargo.driver,
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            print('Error loading salaries: $e');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('خطا در بارگذاری لیست پرداختی‌ها: $e')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.list, size: 18),
                        label: const Text(
                          'لیست پرداختی ها',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$title: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
} 