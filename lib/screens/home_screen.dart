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
import 'package:khatooniiii/screens/reports/cargo_report_screen.dart';
import 'package:khatooniiii/screens/settings_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:khatooniiii/models/driver.dart';
import 'package:khatooniiii/models/cargo.dart';
import 'package:khatooniiii/models/payment.dart';
import 'package:khatooniiii/models/expense.dart';
import 'package:khatooniiii/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('سامانه خاتون'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: themeProvider.isDarkMode ? 'حالت روشن' : 'حالت تاریک',
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'تنظیمات',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
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
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 56.0),
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
                
                const SizedBox(height: 40),
                
                // Stats section
                _buildStatsSection(context),
                const SizedBox(height: 40),
                
                // Sections divider
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(thickness: 1.5),
                ),
                
                const SizedBox(height: 40),
                
                // Create New section
              
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
    
    final reportItems = [
      _MenuItem('گزارش گیری سرویس‌های بار', Icons.local_shipping, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CargoReportScreen()),
        );
      }),
      _MenuItem('گزارش گیری مالی', Icons.monetization_on, () {
        _showTemporaryMessage(context, 'صفحه گزارش گیری مالی به زودی اضافه می‌شود');
      }),
      _MenuItem('گزارش گیری هزینه‌ها', Icons.money_off, () {
        _showTemporaryMessage(context, 'صفحه گزارش گیری هزینه‌ها به زودی اضافه می‌شود');
      }),
      _MenuItem('گزارش گیری راننده‌ها', Icons.people, () {
        _showTemporaryMessage(context, 'صفحه گزارش گیری راننده‌ها به زودی اضافه می‌شود');
      }),
      _MenuItem('گزارش گیری مشتریان', Icons.person_outline, () {
        _showTemporaryMessage(context, 'صفحه گزارش گیری مشتریان به زودی اضافه می‌شود');
      }),
      _MenuItem('گزارش گیری خلاصه', Icons.analytics, () {
        _showReportOptions(context);
      }),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Registration section
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.blue[700],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: const Text(
                  'ثبت اطلاعات جدید',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  height: (registrationItems.length / 3).ceil() * 130.0 + 20,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: registrationItems.length,
                    itemBuilder: (context, index) {
                      final item = registrationItems[index];
                      return _buildMenuCard(context, item, Colors.blue.shade50);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 40),
        
        // Management section
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.green[700],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: const Text(
                  'مدیریت اطلاعات',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  height: (managementItems.length / 3).ceil() * 130.0 + 20,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: managementItems.length,
                    itemBuilder: (context, index) {
                      final item = managementItems[index];
                      return _buildMenuCard(context, item, Colors.green.shade50);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 40),
        
        // Reports section
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.purple[700],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: const Text(
                  'گزارش گیری',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  height: (reportItems.length / 3).ceil() * 130.0 + 20,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: reportItems.length,
                    itemBuilder: (context, index) {
                      final item = reportItems[index];
                      return _buildMenuCard(context, item, Colors.purple.shade50);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 40),
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
      margin: const EdgeInsets.all(4.0),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
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
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 30,
                child: Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // تابع نمایش آپشن‌های گزارش گیری
  void _showReportOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'گزارش گیری',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // بخش انتخاب دوره زمانی
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'دوره زمانی:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildPeriodOption(context, 'امروز', Icons.today),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildPeriodOption(context, 'هفته', Icons.date_range),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildPeriodOption(context, 'ماه', Icons.calendar_month),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildPeriodOption(context, 'سال', Icons.calendar_today),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 24),
                const Text(
                  'نوع گزارش:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 8),
                _buildReportOption(
                  context,
                  'گزارش گیری سرویس‌های بار',
                  Icons.local_shipping,
                  Colors.blue,
                  () {
                    Navigator.pop(context);
                    try {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CargoReportScreen()),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('خطا در بارگیری صفحه گزارش گیری: $e')),
                      );
                    }
                  },
                ),
                _buildReportOption(
                  context,
                  'گزارش گیری مالی',
                  Icons.monetization_on,
                  Colors.green,
                  () {
                    Navigator.pop(context);
                    // TODO: نمایش صفحه گزارش مالی
                    _showTemporaryMessage(context, 'صفحه گزارش گیری مالی به زودی اضافه می‌شود');
                  },
                ),
                _buildReportOption(
                  context,
                  'گزارش گیری هزینه‌ها',
                  Icons.money_off,
                  Colors.red,
                  () {
                    Navigator.pop(context);
                    // TODO: نمایش صفحه گزارش هزینه‌ها
                    _showTemporaryMessage(context, 'صفحه گزارش گیری هزینه‌ها به زودی اضافه می‌شود');
                  },
                ),
                _buildReportOption(
                  context,
                  'گزارش گیری راننده‌ها',
                  Icons.person,
                  Colors.orange,
                  () {
                    Navigator.pop(context);
                    // TODO: نمایش صفحه گزارش راننده‌ها
                    _showTemporaryMessage(context, 'صفحه گزارش گیری راننده‌ها به زودی اضافه می‌شود');
                  },
                ),
                _buildReportOption(
                  context,
                  'گزارش گیری مشتریان',
                  Icons.person_outline,
                  Colors.purple,
                  () {
                    Navigator.pop(context);
                    // TODO: نمایش صفحه گزارش مشتریان
                    _showTemporaryMessage(context, 'صفحه گزارش گیری مشتریان به زودی اضافه می‌شود');
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('بستن'),
            ),
          ],
        );
      },
    );
  }
  
  // دکمه‌های انتخاب دوره زمانی گزارش
  Widget _buildPeriodOption(BuildContext context, String title, IconData icon) {
    return InkWell(
      onTap: () {
        _showTemporaryMessage(context, 'دوره زمانی $title انتخاب شد');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade700),
            const SizedBox(width: 4),
            Text(title, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
  
  // نمایش لیست آیتم‌های گزارش
  Widget _buildReportOption(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.2),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      onTap: onTap,
    );
  }
  
  // نمایش پیام موقت
  void _showTemporaryMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
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