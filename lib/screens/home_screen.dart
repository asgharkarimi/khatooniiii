import 'package:flutter/material.dart';
import 'package:khatooniiii/screens/driver_form.dart';
import 'package:khatooniiii/screens/vehicle_form.dart';
import 'package:khatooniiii/screens/cargo_type_form.dart';
import 'package:khatooniiii/screens/customer_form.dart';
import 'package:khatooniiii/screens/cargo_form.dart';
import 'package:khatooniiii/screens/payment_form.dart';
import 'package:khatooniiii/screens/expense_form.dart';
import 'package:khatooniiii/screens/driver_list.dart';
import 'package:khatooniiii/screens/cargo_list.dart';
import 'package:khatooniiii/screens/payment_list.dart';
import 'package:khatooniiii/screens/expense_list.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:khatooniiii/models/driver.dart';
import 'package:khatooniiii/models/cargo.dart';
import 'package:khatooniiii/models/payment.dart';
import 'package:khatooniiii/models/expense.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سامانه خاتون بار'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Center(
                child: Icon(
                  Icons.local_shipping,
                  size: 64,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
              // Center(
              //   child: Text(
              //     'داشبورد سامانه خاتونی',
              //     style: Theme.of(context).textTheme.headlineSmall,
              //     textAlign: TextAlign.center,
              //   ),
              // ),
              // const SizedBox(height: 24),
              
              // Stats section
              //_buildStatsSection(context),
              //const SizedBox(height: 32),
              
              // Records and Lists section
              // const Padding(
              //   padding: EdgeInsets.only(bottom: 16.0),
              //   child: Text(
              //     'گزارش‌ها و لیست‌ها',
              //     style: TextStyle(
              //       fontSize: 20,
              //       fontWeight: FontWeight.bold,
              //     ),
              //   ),
              // ),
             // _buildRecordsGrid(context),
             // const SizedBox(height: 32),
              
              // Create New section
              // const Padding(
              //   padding: EdgeInsets.only(bottom: 16.0),
              //   child: Text(
              //     'ثبت اطلاعات جدید',
              //     style: TextStyle(
              //       fontSize: 20,
              //       fontWeight: FontWeight.bold,
              //     ),
              //   ),
              // ),
              _buildCreateNewGrid(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Cargo>('cargos').listenable(),
      builder: (context, cargoBox, child) {
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'رانندگان',
                    Hive.box<Driver>('drivers').length.toString(),
                    Icons.person,
                    Colors.blue,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const DriverList()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'محموله‌ها',
                    cargoBox.length.toString(),
                    Icons.inventory,
                    Colors.orange,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CargoList()),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'پرداخت‌ها',
                    Hive.box<Payment>('payments').length.toString(),
                    Icons.payment,
                    Colors.green,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PaymentList()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'هزینه‌ها',
                    Hive.box<Expense>('expenses').length.toString(),
                    Icons.money_off,
                    Colors.red,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ExpenseList()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // Widget _buildRecordsGrid(BuildContext context) {
  //   final menuItems = [
  //     _MenuItem('لیست رانندگان', Icons.people, () {
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(builder: (context) => const DriverList()),
  //       );
  //     }),
  //     _MenuItem('لیست محموله‌ها', Icons.inventory_2, () {
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(builder: (context) => const CargoList()),
  //       );
  //     }),
  //     _MenuItem('لیست پرداخت‌ها', Icons.receipt_long, () {
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(builder: (context) => const PaymentList()),
  //       );
  //     }),
  //     _MenuItem('لیست هزینه‌ها', Icons.money_off, () {
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(builder: (context) => const ExpenseList()),
  //       );
  //     }),
  //   ];

  //   return GridView.builder(
  //     shrinkWrap: true,
  //     physics: const NeverScrollableScrollPhysics(),
  //     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  //       crossAxisCount: 2,
  //       crossAxisSpacing: 16,
  //       mainAxisSpacing: 16,
  //       childAspectRatio: 1.5,
  //     ),
  //     itemCount: menuItems.length,
  //     itemBuilder: (context, index) {
  //       final item = menuItems[index];
  //       return _buildMenuCard(context, item);
  //     },
  //   );
  // }

  Widget _buildCreateNewGrid(BuildContext context) {
    final menuItems = [
      _MenuItem('ثبت راننده', Icons.person_add, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DriverForm()),
        );
      }),
      _MenuItem('ثبت خودرو', Icons.directions_car, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const VehicleForm()),
        );
      }),
      _MenuItem('ثبت نوع محموله', Icons.category, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CargoTypeForm()),
        );
      }),
      _MenuItem('ثبت مشتری', Icons.people, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CustomerForm()),
        );
      }),
      _MenuItem('ثبت محموله', Icons.local_shipping, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CargoForm()),
        );
      }),
      _MenuItem('ثبت پرداخت', Icons.payment, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PaymentForm()),
        );
      }),
      _MenuItem('ثبت هزینه', Icons.money_off, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ExpenseForm()),
        );
      }),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        return _buildMenuCard(context, item);
      },
    );
  }
  
  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(
                icon,
                color: color,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, _MenuItem item) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                item.icon,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  _MenuItem(this.title, this.icon, this.onTap);
} 