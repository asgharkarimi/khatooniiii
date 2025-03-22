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
import 'package:khatooniiii/screens/customer_list.dart';
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
      // appBar: AppBar(
      //   //title: const Text('سامانه خاتون بار', style: TextStyle(fontWeight: FontWeight.bold)),
      //   backgroundColor: Theme.of(context).colorScheme.primary,
      //   foregroundColor: Theme.of(context).colorScheme.onPrimary,
      //   elevation: 0,
      // ),
      body: Container(
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Column(
                    children: [
                      const Center(
                        child: Icon(
                          Icons.local_shipping,
                          size: 80,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'سامانه خاتون بار',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Stats section
                _buildStatsSection(context),
                const SizedBox(height: 24),
                
                // Sections divider
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(thickness: 1.5),
                ),
                
                // Create New section
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'مدیریت سیستم',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildCreateNewGrid(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16.0),
              child: Text(
                'خلاصه وضعیت',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ValueListenableBuilder(
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
                            'سرویس‌ها',
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateNewGrid(BuildContext context) {
    final registrationItems = [
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
      _MenuItem('ثبت نوع سرویس بار', Icons.category, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CargoTypeForm()),
        );
      }),
      _MenuItem('ثبت مشتری', Icons.person_add_alt_1, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CustomerForm()),
        );
      }),
      _MenuItem('ثبت سرویس بار', Icons.local_shipping, () {
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

    final managementItems = [
      _MenuItem('مدیریت رانندگان', Icons.people, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DriverList()),
        );
      }),
      _MenuItem('مدیریت مشتریان', Icons.people_outline, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CustomerList()),
        );
      }),
      _MenuItem('مدیریت سرویس‌ها', Icons.inventory, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CargoList()),
        );
      }),
      _MenuItem('مدیریت پرداخت‌ها', Icons.receipt, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PaymentList()),
        );
      }),
      _MenuItem('مدیریت هزینه‌ها', Icons.money_off_csred, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ExpenseList()),
        );
      }),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Registration section
        const Padding(
          padding: EdgeInsets.only(bottom: 12.0),
          child: Text(
            'ثبت اطلاعات جدید',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemCount: registrationItems.length,
          itemBuilder: (context, index) {
            final item = registrationItems[index];
            return _buildMenuCard(context, item, Colors.blue.shade50);
          },
        ),
        
        const SizedBox(height: 24),
        
        // Management section
        const Padding(
          padding: EdgeInsets.only(bottom: 12.0),
          child: Text(
            'مدیریت اطلاعات',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemCount: managementItems.length,
          itemBuilder: (context, index) {
            final item = managementItems[index];
            return _buildMenuCard(context, item, Colors.green.shade50);
          },
        ),
      ],
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, _MenuItem item, Color backgroundColor) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: backgroundColor,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  item.icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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