import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:khatooniiii/models/cargo.dart';
import 'package:khatooniiii/models/driver.dart';
import 'package:khatooniiii/models/payment.dart';
import 'package:khatooniiii/models/customer.dart';
import 'package:khatooniiii/utils/number_formatter.dart';

class CargoReportScreen extends StatefulWidget {
  const CargoReportScreen({super.key});

  @override
  State<CargoReportScreen> createState() => _CargoReportScreenState();
}

class _CargoReportScreenState extends State<CargoReportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  Driver? _selectedDriver;
  String? _selectedOrigin;
  String? _selectedDestination;
  Customer? _selectedCustomer;
  bool _onlyShowDebtors = false;
  
  // فیلترهای فعال
  bool _showDateFilter = true;
  bool _showDriverFilter = false;
  bool _showRouteFilter = false;
  bool _showCustomerFilter = false;
  bool _showDebtorFilter = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('گزارش سرویس‌های بار'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'لیست سرویس‌ها'),
            Tab(text: 'خلاصه مالی'),
            Tab(text: 'نمودار'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCargoListReport(),
                _buildFinancialSummaryReport(),
                _buildChartReport(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'فیلترها:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.filter_list),
                  label: const Text('تنظیم فیلترها'),
                  onPressed: _showFilterDialog,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_showDateFilter) _buildDateFilterChip(),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_showDriverFilter && _selectedDriver != null)
                  _buildFilterChip(
                    'راننده: ${_selectedDriver!.name}',
                    () => setState(() => _selectedDriver = null),
                  ),
                if (_showRouteFilter && _selectedOrigin != null)
                  _buildFilterChip(
                    'مبدا: $_selectedOrigin',
                    () => setState(() => _selectedOrigin = null),
                  ),
                if (_showRouteFilter && _selectedDestination != null)
                  _buildFilterChip(
                    'مقصد: $_selectedDestination',
                    () => setState(() => _selectedDestination = null),
                  ),
                if (_showCustomerFilter && _selectedCustomer != null)
                  _buildFilterChip(
                    'مشتری: ${_selectedCustomer!.firstName} ${_selectedCustomer!.lastName}',
                    () => setState(() => _selectedCustomer = null),
                  ),
                if (_showDebtorFilter)
                  _buildFilterChip(
                    'فقط بدهکاران',
                    () => setState(() => _showDebtorFilter = false),
                    color: Colors.red.shade50,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // نمایش فیلتر تاریخ
  Widget _buildDateFilterChip() {
    final startText = DateFormat('yyyy/MM/dd').format(_startDate);
    final endText = DateFormat('yyyy/MM/dd').format(_endDate);
    
    return InkWell(
      onTap: _selectDateRange,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.date_range, size: 16, color: Colors.blue),
            const SizedBox(width: 8),
            Text('از $startText تا $endText'),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: _resetDateFilter,
            ),
          ],
        ),
      ),
    );
  }

  // نمایش فیلترهای دیگر
  Widget _buildFilterChip(String label, VoidCallback onDelete, {Color? color}) {
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onDelete,
      backgroundColor: color ?? Colors.blue.shade50,
    );
  }

  // انتخاب بازه زمانی
  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[800]!,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  // بازنشانی فیلتر تاریخ
  void _resetDateFilter() {
    setState(() {
      _startDate = DateTime.now().subtract(const Duration(days: 30));
      _endDate = DateTime.now();
    });
  }

  // نمایش دیالوگ تنظیم فیلترها
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('تنظیم فیلترها'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('فیلتر تاریخ'),
                  value: _showDateFilter,
                  onChanged: (value) {
                    setDialogState(() => _showDateFilter = value);
                  },
                ),
                SwitchListTile(
                  title: const Text('فیلتر راننده'),
                  value: _showDriverFilter,
                  onChanged: (value) {
                    setDialogState(() => _showDriverFilter = value);
                    if (value && _selectedDriver == null) {
                      Navigator.pop(context);
                      _selectDriver();
                    }
                  },
                ),
                SwitchListTile(
                  title: const Text('فیلتر مسیر'),
                  value: _showRouteFilter,
                  onChanged: (value) {
                    setDialogState(() => _showRouteFilter = value);
                    if (value && (_selectedOrigin == null || _selectedDestination == null)) {
                      Navigator.pop(context);
                      _selectRoute();
                    }
                  },
                ),
                SwitchListTile(
                  title: const Text('فیلتر مشتری'),
                  value: _showCustomerFilter,
                  onChanged: (value) {
                    setDialogState(() => _showCustomerFilter = value);
                    if (value && _selectedCustomer == null) {
                      Navigator.pop(context);
                      _selectCustomer();
                    }
                  },
                ),
                SwitchListTile(
                  title: const Text('فقط سرویس‌های بدهکار'),
                  subtitle: const Text('نمایش سرویس‌هایی که هنوز بدهی دارند'),
                  value: _showDebtorFilter,
                  activeColor: Colors.red,
                  onChanged: (value) {
                    setDialogState(() => _showDebtorFilter = value);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {});
                },
                child: const Text('تایید'),
              ),
            ],
          );
        },
      ),
    );
  }

  // انتخاب راننده
  Future<void> _selectDriver() async {
    final driversBox = Hive.box<Driver>('drivers');
    final drivers = driversBox.values.toList();
    
    if (drivers.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('هیچ راننده‌ای یافت نشد')),
        );
      }
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('انتخاب راننده'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: drivers.length,
            itemBuilder: (context, index) {
              final driver = drivers[index];
              return ListTile(
                title: Text(driver.name),
                subtitle: Text(driver.mobile),
                onTap: () {
                  setState(() => _selectedDriver = driver);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو'),
          ),
        ],
      ),
    );
  }

  // انتخاب مسیر (مبدا و مقصد)
  Future<void> _selectRoute() async {
    final cargosBox = Hive.box<Cargo>('cargos');
    final cargos = cargosBox.values.toList();
    
    if (cargos.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('هیچ سرویس باری یافت نشد')),
        );
      }
      return;
    }
    
    // استخراج مبدا‌ها و مقصدهای منحصر به فرد
    final origins = <String>{};
    final destinations = <String>{};
    
    for (final cargo in cargos) {
      origins.add(cargo.origin);
      destinations.add(cargo.destination);
    }
    
    // انتخاب مبدا
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('انتخاب مبدا'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: origins.length,
            itemBuilder: (context, index) {
              final origin = origins.elementAt(index);
              return ListTile(
                title: Text(origin),
                onTap: () {
                  setState(() => _selectedOrigin = origin);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو'),
          ),
        ],
      ),
    );
    
    // انتخاب مقصد
    if (mounted) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('انتخاب مقصد'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: destinations.length,
              itemBuilder: (context, index) {
                final destination = destinations.elementAt(index);
                return ListTile(
                  title: Text(destination),
                  onTap: () {
                    setState(() => _selectedDestination = destination);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('لغو'),
            ),
          ],
        ),
      );
    }
  }

  // انتخاب مشتری
  Future<void> _selectCustomer() async {
    final customersBox = Hive.box<Customer>('customers');
    final customers = customersBox.values.toList();
    
    if (customers.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('هیچ مشتری‌ای یافت نشد')),
        );
      }
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('انتخاب مشتری'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];
              return ListTile(
                title: Text('${customer.firstName} ${customer.lastName}'),
                subtitle: Text(customer.phone),
                onTap: () {
                  setState(() => _selectedCustomer = customer);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو'),
          ),
        ],
      ),
    );
  }

  // بخش گزارش لیست سرویس‌ها
  Widget _buildCargoListReport() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Cargo>('cargos').listenable(),
      builder: (context, Box<Cargo> box, _) {
        final cargos = _getFilteredCargos(box);
        
        if (cargos.isEmpty) {
          return const Center(
            child: Text('هیچ سرویس باری در بازه انتخاب شده یافت نشد'),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: cargos.length,
          itemBuilder: (context, index) {
            final cargo = cargos[index];
            final paymentsBox = Hive.box<Payment>('payments');
            final cargoPayments = paymentsBox.values.where((p) => p.cargo.key == cargo.key).toList();
            final totalPaid = cargoPayments.fold(0.0, (sum, p) => sum + p.amount);
            final remaining = cargo.totalPrice - totalPaid;
            
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${cargo.driver.name} - ${cargo.vehicle.vehicleName}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('${cargo.origin} به ${cargo.destination}'),
                              const SizedBox(height: 4),
                              Text(
                                'تاریخ: ${DateFormat('yyyy/MM/dd').format(cargo.date)}',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${formatNumber(cargo.totalPrice)} تومان',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _buildPaymentStatusBadge(remaining),
                          ],
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('نوع بار: ${cargo.cargoType.cargoName}'),
                        Text('وزن: ${formatNumber(cargo.weight)} کیلوگرم'),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // دریافت سرویس‌های فیلتر شده
  List<Cargo> _getFilteredCargos(Box<Cargo> box) {
    final List<Cargo> filteredCargos = box.values.where((cargo) {
      // فیلتر تاریخ
      if (_showDateFilter) {
        final cargoDate = DateTime(cargo.date.year, cargo.date.month, cargo.date.day);
        final startDate = DateTime(_startDate.year, _startDate.month, _startDate.day);
        final endDate = DateTime(_endDate.year, _endDate.month, _endDate.day);
        
        if (cargoDate.isBefore(startDate) || cargoDate.isAfter(endDate)) {
          return false;
        }
      }
      
      // فیلتر راننده
      if (_showDriverFilter && _selectedDriver != null) {
        if (cargo.driver.key != _selectedDriver!.key) {
          return false;
        }
      }
      
      // فیلتر مسیر
      if (_showRouteFilter) {
        if (_selectedOrigin != null && cargo.origin != _selectedOrigin) {
          return false;
        }
        
        if (_selectedDestination != null && cargo.destination != _selectedDestination) {
          return false;
        }
      }
      
      // فیلتر مشتری
      if (_showCustomerFilter && _selectedCustomer != null) {
        // چک کردن پرداخت‌های مرتبط با این سرویس بار
        final paymentsBox = Hive.box<Payment>('payments');
        final hasCustomerPayment = paymentsBox.values.any(
          (payment) => payment.cargo.key == cargo.key && 
          payment.customer.firstName == _selectedCustomer!.firstName && 
          payment.customer.lastName == _selectedCustomer!.lastName &&
          payment.customer.phone == _selectedCustomer!.phone
        );
        
        if (!hasCustomerPayment) {
          return false;
        }
      }
      
      return true;
    }).toList();
    
    // فیلتر بدهکاران - اعمال بعد از سایر فیلترها
    if (_showDebtorFilter) {
      final paymentsBox = Hive.box<Payment>('payments');
      return filteredCargos.where((cargo) {
        final cargoPayments = paymentsBox.values.where((p) => p.cargo.key == cargo.key).toList();
        final totalPaid = cargoPayments.fold(0.0, (sum, p) => sum + p.amount);
        return cargo.totalPrice > totalPaid; // فقط آنهایی که بدهی دارند
      }).toList();
    }
    
    return filteredCargos;
  }

  // نمایش وضعیت پرداخت
  Widget _buildPaymentStatusBadge(double remaining) {
    if (remaining > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '${formatNumber(remaining)} تومان باقیمانده',
          style: const TextStyle(color: Colors.red, fontSize: 12),
        ),
      );
    } else if (remaining < 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '${formatNumber(-remaining)} تومان اضافه پرداخت',
          style: const TextStyle(color: Colors.blue, fontSize: 12),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'پرداخت شده',
          style: TextStyle(color: Colors.green, fontSize: 12),
        ),
      );
    }
  }

  // بخش گزارش خلاصه مالی
  Widget _buildFinancialSummaryReport() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Cargo>('cargos').listenable(),
      builder: (context, Box<Cargo> box, _) {
        final cargos = _getFilteredCargos(box);
        
        if (cargos.isEmpty) {
          return const Center(
            child: Text('هیچ سرویس باری در بازه انتخاب شده یافت نشد'),
          );
        }

        // محاسبه مجموع کل
        final totalPriceSum = cargos.fold(0.0, (sum, cargo) => sum + cargo.totalPrice);
        
        // محاسبه مجموع پرداخت‌ها
        final paymentsBox = Hive.box<Payment>('payments');
        double totalPaidSum = 0;
        double totalRemainingSum = 0;
        int completedPayments = 0;
        int partialPayments = 0;
        int pendingPayments = 0;
        
        for (final cargo in cargos) {
          final cargoPayments = paymentsBox.values.where((p) => p.cargo.key == cargo.key).toList();
          final totalPaid = cargoPayments.fold(0.0, (sum, p) => sum + p.amount);
          totalPaidSum += totalPaid;
          
          final remaining = cargo.totalPrice - totalPaid;
          totalRemainingSum += remaining > 0 ? remaining : 0;
          
          if (remaining <= 0) {
            completedPayments++;
          } else if (totalPaid > 0) {
            partialPayments++;
          } else {
            pendingPayments++;
          }
        }
        
        // محاسبه درصد وصول، با محافظت در برابر تقسیم بر صفر
        final collectionPercentage = totalPriceSum > 0 
            ? ((totalPaidSum / totalPriceSum) * 100).toStringAsFixed(1) 
            : '0.0';
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'خلاصه مالی',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSummaryRow('تعداد کل سرویس‌ها:', '${cargos.length}'),
                      const Divider(),
                      _buildSummaryRow('مجموع کل قیمت‌ها:', '${formatNumber(totalPriceSum)} تومان'),
                      _buildSummaryRow('مجموع پرداخت شده:', '${formatNumber(totalPaidSum)} تومان', color: Colors.green),
                      _buildSummaryRow('مجموع باقیمانده:', '${formatNumber(totalRemainingSum)} تومان', color: Colors.red),
                      const Divider(),
                      _buildSummaryRow('درصد وصول:', '$collectionPercentage%'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'وضعیت پرداخت‌ها',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSummaryRow('تعداد سرویس‌های پرداخت شده:', '$completedPayments', color: Colors.green),
                      _buildSummaryRow('تعداد سرویس‌های پرداخت جزئی:', '$partialPayments', color: Colors.orange),
                      _buildSummaryRow('تعداد سرویس‌های بدون پرداخت:', '$pendingPayments', color: Colors.red),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // بخش گزارش نمودار
  Widget _buildChartReport() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Cargo>('cargos').listenable(),
      builder: (context, Box<Cargo> box, _) {
        final cargos = _getFilteredCargos(box);
        
        if (cargos.isEmpty) {
          return const Center(
            child: Text('هیچ سرویس باری در بازه انتخاب شده یافت نشد'),
          );
        }

        // محاسبه مجموع کل
        final totalPriceSum = cargos.fold(0.0, (sum, cargo) => sum + cargo.totalPrice);
        
        // محاسبه مجموع پرداخت‌ها و بدهی‌ها
        final paymentsBox = Hive.box<Payment>('payments');
        double totalPaidSum = 0;
        double totalRemainingSum = 0;
        
        for (final cargo in cargos) {
          final cargoPayments = paymentsBox.values.where((p) => p.cargo.key == cargo.key).toList();
          final totalPaid = cargoPayments.fold(0.0, (sum, p) => sum + p.amount);
          totalPaidSum += totalPaid;
          
          final remaining = cargo.totalPrice - totalPaid;
          totalRemainingSum += remaining > 0 ? remaining : 0;
        }

        // محاسبه مجموع هزینه‌ها (فرض می‌کنیم 70% از مبلغ کل هزینه است)
        final totalExpenses = totalPriceSum * 0.7;
        final totalProfit = totalPriceSum - totalExpenses;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'نمودار مبلغ کل به مبلغ بدهکاری',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 200,
                        child: _buildDebtChart(totalPriceSum, totalPaidSum, totalRemainingSum),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildChartLegendItem('مبلغ کل', Colors.blue),
                          const SizedBox(width: 24),
                          _buildChartLegendItem('پرداخت شده', Colors.green),
                          const SizedBox(width: 24),
                          _buildChartLegendItem('بدهکاری', Colors.red),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSummaryRow('مبلغ کل:', '${formatNumber(totalPriceSum)} تومان', color: Colors.blue),
                      _buildSummaryRow('پرداخت شده:', '${formatNumber(totalPaidSum)} تومان', color: Colors.green),
                      _buildSummaryRow('بدهکاری:', '${formatNumber(totalRemainingSum)} تومان', color: Colors.red),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'نمودار مبلغ کل به هزینه',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 200,
                        child: _buildExpenseChart(totalPriceSum, totalExpenses, totalProfit),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildChartLegendItem('مبلغ کل', Colors.blue),
                          const SizedBox(width: 24),
                          _buildChartLegendItem('هزینه‌ها', Colors.orange),
                          const SizedBox(width: 24),
                          _buildChartLegendItem('سود', Colors.green),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSummaryRow('مبلغ کل:', '${formatNumber(totalPriceSum)} تومان', color: Colors.blue),
                      _buildSummaryRow('هزینه‌ها:', '${formatNumber(totalExpenses)} تومان', color: Colors.orange),
                      _buildSummaryRow('سود:', '${formatNumber(totalProfit)} تومان', color: Colors.green),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // نمایش راهنمای رنگ‌های نمودار
  Widget _buildChartLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  // نمودار مبلغ کل به بدهکاری
  Widget _buildDebtChart(double total, double paid, double debt) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        
        // Prevent division by zero or negative values
        if (total <= 0) {
          return const Center(
            child: Text('داده‌ای برای نمایش وجود ندارد'),
          );
        }
        
        // ستون مبلغ کل
        final totalBarWidth = width * 0.25;
        final totalBarHeight = height * 0.8;
        
        // ستون‌های پرداخت شده و بدهکاری
        final detailBarWidth = width * 0.25;
        final paidBarHeight = (paid / total) * totalBarHeight;
        final debtBarHeight = (debt / total) * totalBarHeight;
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // ستون مبلغ کل
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: totalBarWidth,
                  height: totalBarHeight,
                  color: Colors.blue,
                ),
                const SizedBox(height: 8),
                const Text('مبلغ کل'),
              ],
            ),
            
            // ستون‌های پرداخت شده و بدهکاری
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Column(
                  children: [
                    Container(
                      width: detailBarWidth,
                      height: debtBarHeight,
                      color: Colors.red,
                    ),
                    Container(
                      width: detailBarWidth,
                      height: paidBarHeight,
                      color: Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('وضعیت پرداخت'),
              ],
            ),
          ],
        );
      },
    );
  }

  // نمودار مبلغ کل به هزینه
  Widget _buildExpenseChart(double total, double expense, double profit) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        
        // Prevent division by zero or negative values
        if (total <= 0) {
          return const Center(
            child: Text('داده‌ای برای نمایش وجود ندارد'),
          );
        }
        
        // ستون مبلغ کل
        final totalBarWidth = width * 0.25;
        final totalBarHeight = height * 0.8;
        
        // ستون‌های هزینه و سود
        final detailBarWidth = width * 0.25;
        final expenseBarHeight = (expense / total) * totalBarHeight;
        final profitBarHeight = (profit / total) * totalBarHeight;
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // ستون مبلغ کل
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: totalBarWidth,
                  height: totalBarHeight,
                  color: Colors.blue,
                ),
                const SizedBox(height: 8),
                const Text('مبلغ کل'),
              ],
            ),
            
            // ستون‌های هزینه و سود
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Column(
                  children: [
                    Container(
                      width: detailBarWidth,
                      height: profitBarHeight,
                      color: Colors.green,
                    ),
                    Container(
                      width: detailBarWidth,
                      height: expenseBarHeight,
                      color: Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('هزینه و سود'),
              ],
            ),
          ],
        );
      },
    );
  }

  // سطر خلاصه در گزارش مالی
  Widget _buildSummaryRow(String title, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
} 