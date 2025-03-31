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
import 'package:khatooniiii/screens/address_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:khatooniiii/models/driver.dart';
import 'package:khatooniiii/models/cargo.dart';
import 'package:khatooniiii/models/payment.dart';
import 'package:khatooniiii/models/expense.dart';
import 'package:khatooniiii/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:khatooniiii/screens/cargo_type_management.dart';
import 'package:khatooniiii/screens/driver_salary_management.dart';
import 'package:khatooniiii/screens/freight_screen.dart';
import 'package:khatooniiii/screens/bank_account_list.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('سامانه خاتون بار', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
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
              Colors.white.withOpacity(0.9),
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
                _buildAnimatedHeader(context),
                
                const SizedBox(height: 24),
                
                // Dashboard Stats
                _buildDashboardStats(context),
                
                const SizedBox(height: 24),
                
                // Create New section
                _buildCreateNewGrid(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader(BuildContext context) {
    return Hero(
      tag: 'dashboard_header',
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_shipping,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'داشبورد مدیریتی سامانه',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  const Shadow(
                    offset: Offset(0, 2),
                    blurRadius: 3,
                    color: Color.fromRGBO(0, 0, 0, 0.3),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'مدیریت آسان ناوگان حمل و نقل',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardStats(BuildContext context) {
    final cargosBox = Hive.box<Cargo>('cargos');
    final driversBox = Hive.box<Driver>('drivers');
    final paymentsBox = Hive.box<Payment>('payments');
    final expensesBox = Hive.box<Expense>('expenses');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'آمار کلی',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                Icons.local_shipping,
                cargosBox.length.toString(),
                'سرویس‌ها',
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                Icons.people,
                driversBox.length.toString(),
                'رانندگان',
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                Icons.payment,
                paymentsBox.length.toString(),
                'پرداخت‌ها',
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                Icons.money_off,
                expensesBox.length.toString(),
                'هزینه‌ها',
                Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, IconData icon, String count, String title, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            count,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
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
      _MenuItem('ثبت اطلاعات بانکی', Icons.credit_card, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BankAccountList()),
        );
      }),
      _MenuItem('ثبت آدرس', Icons.add_location, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddressScreen()),
        );
      }),
      _MenuItem('ثبت سرویس بار', Icons.local_shipping, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CargoForm()),
        );
      }),
      _MenuItem('ثبت باربری', Icons.add_business, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FreightScreen()),
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
      _MenuItem('ثبت حقوق راننده', Icons.account_balance_wallet, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DriverSalaryManagement()),
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
      _MenuItem('مدیریت انواع بار', Icons.category, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CargoTypeManagement()),
        );
      }),
      _MenuItem('مدیریت آدرس‌ها', Icons.location_city, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddressScreen()),
        );
      }),
      _MenuItem('مدیریت حساب‌های بانکی', Icons.account_balance, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BankAccountList()),
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
    ];

    return Column(
      children: [
        _buildCategoryCard(
          context,
          'ثبت اطلاعات جدید',
          'افزودن اطلاعات و ثبت موجودیت‌های جدید',
          Colors.blue,
          Icons.add_circle,
          registrationItems,
        ),
        const SizedBox(height: 24),
        _buildCategoryCard(
          context,
          'مدیریت اطلاعات',
          'مشاهده و ویرایش اطلاعات موجود',
          Colors.green,
          Icons.edit_document,
          managementItems,
        ),
        const SizedBox(height: 24),
        _buildCategoryCard(
          context,
          'گزارش‌گیری',
          'مشاهده و استخراج گزارش‌های مختلف',
          Colors.orange,
          Icons.bar_chart,
          reportItems,
        ),
      ],
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String title,
    String subtitle,
    Color color,
    IconData icon,
    List<_MenuItem> items,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  color,
                  color.withOpacity(0.8),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final menuItem = items[index];
                return _buildAnimatedMenuItem(context, menuItem, color);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedMenuItem(BuildContext context, _MenuItem menuItem, Color color) {
    return InkWell(
      onTap: menuItem.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                menuItem.icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                menuItem.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

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