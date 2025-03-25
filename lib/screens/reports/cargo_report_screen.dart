import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:khatooniiii/models/cargo.dart';
import 'package:khatooniiii/models/driver.dart';
import 'package:khatooniiii/models/payment.dart';
import 'package:khatooniiii/models/customer.dart';
import 'package:khatooniiii/utils/number_formatter.dart';
import 'package:khatooniiii/screens/cargo_form.dart';
import 'package:khatooniiii/widgets/float_button_style.dart';
import 'package:khatooniiii/screens/vehicle_list.dart';
import 'package:khatooniiii/screens/driver_list.dart';

// کلاس برای نگهداری محاسبات گزارش
class ReportData {
  final double totalPriceSum;
  final double totalTransportCosts;
  final double totalAmount;
  final double totalPaidSum;
  final double totalRemainingSum;
  final double totalNetProfit;
  
  final int fixedPriceServices;
  final double fixedPriceValuesSum;
  final double fixedPriceTransportSum;
  
  final double normalServicesValue;
  final double normalServicesTransport;
  
  final int weightBasedServices;
  final int transportBasedServices;
  final int combinedServices;
  
  final double transportBasedValue;
  final double weightBasedValue;
  final double combinedValue;
  final double combinedTransport;
  
  final int completedPayments;
  final int partialPayments;
  final int pendingPayments;
  
  ReportData({
    required this.totalPriceSum,
    required this.totalTransportCosts,
    required this.totalAmount,
    required this.totalPaidSum,
    required this.totalRemainingSum,
    required this.totalNetProfit,
    required this.fixedPriceServices,
    required this.fixedPriceValuesSum,
    required this.fixedPriceTransportSum,
    required this.normalServicesValue,
    required this.normalServicesTransport,
    required this.weightBasedServices,
    required this.transportBasedServices,
    required this.combinedServices,
    required this.transportBasedValue,
    required this.weightBasedValue,
    required this.combinedValue,
    required this.combinedTransport,
    required this.completedPayments,
    required this.partialPayments,
    required this.pendingPayments,
  });
}

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
  final bool _onlyShowDebtors = false;
  final bool _sortByAmount = false;
  final bool _showProfitLossReport = false;
  
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
    return FloatButtonScaffold.withFloatButton(
      label: 'افزودن سرویس',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CargoForm()),
        );
      },
      icon: Icons.add,
      tooltip: 'افزودن سرویس بار جدید',
      bottomMargin: 20,
      appBar: AppBar(
        title: const Text('گزارش سرویس‌های بار'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'چاپ گزارش',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('قابلیت چاپ گزارش به زودی اضافه خواهد شد')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'اشتراک گذاری',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('قابلیت اشتراک گذاری گزارش به زودی اضافه خواهد شد')),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'لیست سرویس‌ها'),
            Tab(text: 'خلاصه مالی'),
            Tab(text: 'سود و زیان'),
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
                _buildProfitLossReport(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const SizedBox(height: 40),
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
                  'فیلترهای گزارش',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.filter_list, size: 18),
                  label: const Text('تنظیم', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  onPressed: _showFilterDialog,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_showDateFilter) _buildDateFilterChip(),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (_showDriverFilter && _selectedDriver != null)
                  _buildFilterChip(
                    'راننده: ${_selectedDriver!.name}',
                    () => setState(() => _selectedDriver = null),
                    icon: Icons.person,
                  ),
                if (_showRouteFilter && _selectedOrigin != null)
                  _buildFilterChip(
                    'مبدا: $_selectedOrigin',
                    () => setState(() => _selectedOrigin = null),
                    icon: Icons.location_on,
                  ),
                if (_showRouteFilter && _selectedDestination != null)
                  _buildFilterChip(
                    'مقصد: $_selectedDestination',
                    () => setState(() => _selectedDestination = null),
                    icon: Icons.location_on,
                  ),
                if (_showCustomerFilter && _selectedCustomer != null)
                  _buildFilterChip(
                    'مشتری: ${_selectedCustomer!.firstName}',
                    () => setState(() => _selectedCustomer = null),
                    icon: Icons.person_outline,
                  ),
                if (_showDebtorFilter)
                  _buildFilterChip(
                    'بدهکاران',
                    () => setState(() => _showDebtorFilter = false),
                    color: Colors.red.shade50,
                    icon: Icons.money_off,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildManagementButton(
                  'مدیریت وسایل نقلیه',
                  Icons.directions_car,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const VehicleList()),
                  ),
                ),
                const SizedBox(width: 8),
                _buildManagementButton(
                  'مدیریت رانندگان',
                  Icons.person,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DriverList()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // دکمه مدیریت
  Widget _buildManagementButton(String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.date_range, size: 14, color: Colors.blue),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                'از $startText تا $endText',
                style: const TextStyle(fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: _resetDateFilter,
              child: const Icon(Icons.close, size: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // نمایش فیلترهای دیگر
  Widget _buildFilterChip(String label, VoidCallback onDelete, {Color? color, IconData? icon}) {
    return Chip(
      avatar: icon != null ? Icon(icon, size: 14, color: Colors.grey[700]) : null,
      label: Text(label, style: const TextStyle(fontSize: 11)),
      deleteIcon: const Icon(Icons.close, size: 14),
      onDeleted: onDelete,
      backgroundColor: color ?? Colors.blue.shade50,
      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'هیچ سرویس باری در بازه انتخاب شده یافت نشد',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _showFilterDialog,
                  icon: const Icon(Icons.filter_alt),
                  label: const Text('تغییر فیلترها'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          );
        }
        
        // محاسبه آمار گزارش
        final reportData = _calculateReportData(cargos);
        
        return Column(
          children: [
            // کارت خلاصه
            Container(
              margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.insights, color: Colors.purple, size: 18),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'خلاصه سرویس‌های بار',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.purple,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${cargos.length} سرویس',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryColumn('ارزش کل', formatNumber(reportData.totalPriceSum), 
                          Colors.blue, Icons.monetization_on),
                        _buildSummaryColumn('هزینه حمل', formatNumber(reportData.totalTransportCosts), 
                          Colors.red, Icons.local_shipping),
                        _buildSummaryColumn('مجموع', formatNumber(reportData.totalAmount), 
                          Colors.purple, Icons.account_balance_wallet),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // سورت و فیلتر سرویس‌ها
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  Text('${cargos.length} سرویس یافت شد',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sort, size: 14, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text('ترتیب: تاریخ جدید', style: TextStyle(fontSize: 11, color: Colors.blue[700])),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // لیست سرویس‌ها
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: cargos.length,
                itemBuilder: (context, index) {
                  final cargo = cargos[index];
                  final paymentsBox = Hive.box<Payment>('payments');
                  final cargoPayments = paymentsBox.values.where((p) => p.cargo.key == cargo.key).toList();
                  final totalPaid = cargoPayments.fold(0.0, (sum, p) => sum + p.amount);
                  final totalAmount = cargo.totalPrice + cargo.totalTransportCost;
                  final remaining = totalAmount - totalPaid;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Card(
                      margin: EdgeInsets.zero,
                      elevation: 0,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // رنگ نمایشگر وضعیت
                          Container(
                            height: 4,
                            color: remaining <= 0 ? Colors.green : Colors.red,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // بخش راننده و تاریخ
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // بخش راننده و ماشین
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade50,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Icon(Icons.person, size: 16, color: Colors.blue),
                                              ),
                                              const SizedBox(width: 6),
                                              Flexible(
                                                child: Text(
                                                  cargo.driver.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          // بخش مبدا و مقصد
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Colors.amber.shade50,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Icon(Icons.location_on, size: 16, color: Colors.amber),
                                              ),
                                              const SizedBox(width: 6),
                                              Flexible(
                                                child: Text(
                                                  '${cargo.origin} ➔ ${cargo.destination}',
                                                  style: const TextStyle(fontSize: 12),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          // بخش تاریخ
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.shade50,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Icon(Icons.calendar_today, size: 16, color: Colors.green),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                DateFormat('yyyy/MM/dd').format(cargo.date),
                                                style: TextStyle(color: Colors.grey[700], fontSize: 11),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // بخش قیمت و وضعیت پرداخت
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.purple.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.purple.shade200),
                                          ),
                                          child: Text(
                                            '${formatNumber(totalAmount)} تومان',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Colors.purple,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildPaymentStatusBadge(remaining),
                                      ],
                                    ),
                                  ],
                                ),
                                const Divider(height: 16),
                                // بخش جزئیات مالی
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // نوع بار و وزن
                                          Row(
                                            children: [
                                              const Text('نوع بار: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                              Flexible(
                                                child: Text(
                                                  cargo.cargoType.cargoName, 
                                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Text('وزن: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                              Text(
                                                cargo.weight > 0 
                                                  ? '${formatNumber(cargo.weight)} کیلوگرم'
                                                  : 'مقطوع', 
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          // جزئیات مالی
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'ارزش: ${formatNumber(cargo.totalPrice)} تومان',
                                                style: const TextStyle(fontSize: 11, color: Colors.blue),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.red,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'حمل: ${formatNumber(cargo.totalTransportCost)} تومان',
                                                style: const TextStyle(fontSize: 11, color: Colors.red),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
  
  // ستون خلاصه با گرادیانت
  Widget _buildGradientSummaryColumn(String title, String value, List<Color> colors, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: colors[0].withOpacity(0.8)),
              const SizedBox(width: 4),
              Text(
                title, 
                style: TextStyle(fontSize: 11, color: colors[0].withOpacity(0.8), fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$value تومان',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: colors[0],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  
  // ستون خلاصه ساده
  Widget _buildSummaryColumn(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                title, 
                style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$value تومان',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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
        // محاسبه بدهکاری بر اساس مجموع هزینه حمل و قیمت کل
        final totalAmount = cargo.totalPrice + cargo.totalTransportCost;
        return totalAmount > totalPaid; // فقط آنهایی که بدهی دارند
      }).toList();
    }
    
    return filteredCargos;
  }

  // نمایش نشان وضعیت پرداخت
  Widget _buildPaymentStatusBadge(double remaining) {
    if (remaining <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'پرداخت شده',
          style: TextStyle(
            color: Colors.green,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'بدهی: ${formatNumber(remaining)} تومان',
          style: const TextStyle(
            color: Colors.red,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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

        // محاسبه آمار گزارش
        final reportData = _calculateReportData(cargos);
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // کارت خلاصه مالی اصلی
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
                      _buildSummaryRow('مجموع ارزش بار:', '${formatNumber(reportData.totalPriceSum)} تومان', 
                        color: Colors.blue, 
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                      _buildSummaryRow('مجموع هزینه‌های حمل:', '${formatNumber(reportData.totalTransportCosts)} تومان', 
                        color: Colors.red, 
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                      _buildSummaryRow('مجموع کل (ارزش + هزینه):', '${formatNumber(reportData.totalAmount)} تومان', 
                        color: Colors.purple, 
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                      _buildSummaryRow('سود خالص (ارزش - هزینه حمل):', '${formatNumber(reportData.totalNetProfit)} تومان', 
                        color: reportData.totalNetProfit > 0 ? Colors.green : Colors.red, 
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // کارت وضعیت پرداخت‌ها
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
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  const Text('پرداخت شده', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                  const SizedBox(height: 8),
                                  Text('${reportData.completedPayments}', style: const TextStyle(fontSize: 18, color: Colors.green)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  const Text('جزئی', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                                  const SizedBox(height: 8),
                                  Text('${reportData.partialPayments}', style: const TextStyle(fontSize: 18, color: Colors.orange)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  const Text('بدون پرداخت', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                  const SizedBox(height: 8),
                                  Text('${reportData.pendingPayments}', style: const TextStyle(fontSize: 18, color: Colors.red)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const Text(
                        'نحوه محاسبه بدهکاری:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('مثال:'),
                            Text('- قیمت کل سرویس = 20,000,000 تومان', style: TextStyle(color: Colors.blue)),
                            Text('- هزینه حمل = 10,000,000 تومان', style: TextStyle(color: Colors.red)),
                            Divider(),
                            Text('بدهکاری = قیمت کل سرویس + هزینه حمل = 30,000,000 تومان', 
                              style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      _buildSummaryRow('بدهکاری کل:', '${formatNumber(reportData.totalAmount)} تومان', 
                        color: Colors.purple, 
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                      const SizedBox(height: 2),
                      Text(
                        'بدهکاری = قیمت کل سرویس‌ها (${formatNumber(reportData.totalPriceSum)} تومان) + هزینه حمل کل (${formatNumber(reportData.totalTransportCosts)} تومان)',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow('پرداخت شده:', '${formatNumber(reportData.totalPaidSum)} تومان', 
                        color: Colors.green, 
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                      _buildSummaryRow('باقیمانده:', '${formatNumber(reportData.totalRemainingSum)} تومان', 
                        color: Colors.red, 
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 28,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Row(
                              children: [
                                Container(
                                  width: (reportData.totalAmount > 0 ? (reportData.totalPaidSum / reportData.totalAmount * 100) : 0) * constraints.maxWidth / 100,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                ),
                              ],
                            );
                          }
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'درصد وصول: ${(reportData.totalAmount > 0 ? (reportData.totalPaidSum / reportData.totalAmount * 100) : 0).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // کارت نمودار سود و ارزش
              Card(
                color: Colors.purple.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'نمودار ارزش و هزینه',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: _buildCombinedTransportValueChart(reportData.totalPriceSum, reportData.totalTransportCosts, reportData.totalNetProfit),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildChartLegendItem('ارزش کل بار', Colors.blue),
                          const SizedBox(width: 24),
                          _buildChartLegendItem('هزینه حمل', Colors.red),
                          const SizedBox(width: 24),
                          _buildChartLegendItem('سود خالص', Colors.green),
                        ],
                      ),
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
  
  // نمودار ترکیبی هزینه حمل و ارزش بار
  Widget _buildCombinedTransportValueChart(double totalValue, double transportCost, double profit) {
    return SizedBox(
      height: 200,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          
          // محافظت در برابر صفر یا ارزش منفی
          if (totalValue <= 0) {
            return const Center(
              child: Text('داده‌ای برای نمایش وجود ندارد'),
            );
          }
          
          final valueBarWidth = width * 0.3;
          final valueBarHeight = height * 0.8;
          
          final transportBarWidth = width * 0.3;
          final transportBarHeight = (transportCost / totalValue) * valueBarHeight;
          
          final profitBarWidth = width * 0.3;
          final profitBarHeight = (profit / totalValue) * valueBarHeight;
          
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: valueBarWidth,
                    height: valueBarHeight,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 8),
                  const Text('ارزش کل'),
                  Text('${formatNumber(totalValue)} تومان', style: const TextStyle(fontSize: 10)),
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: transportBarWidth,
                    height: transportBarHeight,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 8),
                  const Text('هزینه حمل'),
                  Text('${formatNumber(transportCost)} تومان', style: const TextStyle(fontSize: 10)),
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: profitBarWidth,
                    height: profitBarHeight > 0 ? profitBarHeight : 2,  // حداقل ارتفاع برای نمایش
                    color: profit > 0 ? Colors.green : Colors.red,
                  ),
                  const SizedBox(height: 8),
                  const Text('سود خالص'),
                  Text('${formatNumber(profit)} تومان', style: const TextStyle(fontSize: 10)),
                ],
              ),
            ],
          );
        },
      ),
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

        // محاسبه آمار گزارش
        final reportData = _calculateReportData(cargos);

        // محاسبه مجموع هزینه‌ها (فرض می‌کنیم 70% از مبلغ کل هزینه است)
        final totalExpenses = reportData.totalPriceSum * 0.7;
        final totalProfit = reportData.totalPriceSum - totalExpenses;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // کارت جدید برای نمایش مجموع هزینه حمل و قیمت کل
              Card(
                color: Colors.purple.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'مجموع هزینه حمل و قیمت کل سرویس',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 200,
                        child: _buildCombinedValueTransportChart(reportData.totalPriceSum, reportData.totalTransportCosts, reportData.totalAmount),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildChartLegendItem('قیمت کل سرویس', Colors.blue),
                          const SizedBox(width: 24),
                          _buildChartLegendItem('هزینه حمل', Colors.red),
                          const SizedBox(width: 24),
                          _buildChartLegendItem('مجموع کل', Colors.purple),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSummaryRow('قیمت کل سرویس:', '${formatNumber(reportData.totalPriceSum)} تومان', color: Colors.blue),
                      _buildSummaryRow('هزینه حمل:', '${formatNumber(reportData.totalTransportCosts)} تومان', color: Colors.red),
                      _buildSummaryRow('مجموع کل:', '${formatNumber(reportData.totalAmount)} تومان', color: Colors.purple),
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
                        'نمودار مبلغ کل به مبلغ بدهکاری',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 200,
                        child: _buildDebtChart(reportData.totalPriceSum, reportData.totalPaidSum, reportData.totalRemainingSum),
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
                      _buildSummaryRow('مبلغ کل:', '${formatNumber(reportData.totalPriceSum)} تومان', color: Colors.blue),
                      _buildSummaryRow('پرداخت شده:', '${formatNumber(reportData.totalPaidSum)} تومان', color: Colors.green),
                      _buildSummaryRow('بدهکاری:', '${formatNumber(reportData.totalRemainingSum)} تومان', color: Colors.red),
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
                        child: _buildExpenseChart(reportData.totalPriceSum, totalExpenses, totalProfit),
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
                      _buildSummaryRow('مبلغ کل:', '${formatNumber(reportData.totalPriceSum)} تومان', color: Colors.blue),
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

  // نمودار ترکیبی قیمت کل سرویس و هزینه حمل
  Widget _buildCombinedValueTransportChart(double serviceValue, double transportCost, double total) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        
        // محافظت در برابر صفر یا ارزش منفی
        if (total <= 0) {
          return const Center(
            child: Text('داده‌ای برای نمایش وجود ندارد'),
          );
        }
        
        // ستون قیمت کل سرویس
        final serviceBarWidth = width * 0.2;
        final serviceBarHeight = (serviceValue / total) * height * 0.8;
        
        // ستون هزینه حمل
        final transportBarWidth = width * 0.2;
        final transportBarHeight = (transportCost / total) * height * 0.8;
        
        // ستون مجموع
        final totalBarWidth = width * 0.2;
        final totalBarHeight = height * 0.8;
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // ستون قیمت کل سرویس
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: serviceBarWidth,
                  height: serviceBarHeight,
                  color: Colors.blue,
                ),
                const SizedBox(height: 8),
                const Text('قیمت کل سرویس'),
                Text('${formatNumber(serviceValue)} تومان', style: const TextStyle(fontSize: 10)),
              ],
            ),
            
            // ستون هزینه حمل
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: transportBarWidth,
                  height: transportBarHeight,
                  color: Colors.red,
                ),
                const SizedBox(height: 8),
                const Text('هزینه حمل'),
                Text('${formatNumber(transportCost)} تومان', style: const TextStyle(fontSize: 10)),
              ],
            ),
            
            // ستون مجموع
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: totalBarWidth,
                  height: totalBarHeight,
                  color: Colors.purple,
                ),
                const SizedBox(height: 8),
                const Text('مجموع کل'),
                Text('${formatNumber(total)} تومان', style: const TextStyle(fontSize: 10)),
              ],
            ),
          ],
        );
      },
    );
  }

  // سطر خلاصه در گزارش مالی
  Widget _buildSummaryRow(String title, String value, {Color? color, double? fontSize, FontWeight? fontWeight}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            value,
            style: TextStyle(
              fontWeight: fontWeight ?? FontWeight.bold,
              color: color,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }

  // بخش گزارش سود و زیان
  Widget _buildProfitLossReport() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Cargo>('cargos').listenable(),
      builder: (context, Box<Cargo> box, _) {
        final cargos = _getFilteredCargos(box);
        
        if (cargos.isEmpty) {
          return const Center(
            child: Text('هیچ سرویس باری در بازه انتخاب شده یافت نشد'),
          );
        }

        // محاسبه آمار گزارش
        final reportData = _calculateReportData(cargos);
        
        // محاسبه سرویس‌های سودده و زیان‌ده
        final profitableCargos = cargos.where((cargo) => cargo.netProfit > 0).toList();
        final unprofitableCargos = cargos.where((cargo) => cargo.netProfit <= 0).toList();
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // کارت خلاصه سود و زیان
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'خلاصه سود و زیان',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  const Text('تعداد کل', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text('${cargos.length}', style: const TextStyle(fontSize: 18)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  const Text('سودده', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                  const SizedBox(height: 8),
                                  Text('${profitableCargos.length}', style: const TextStyle(fontSize: 18, color: Colors.green)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  const Text('زیان‌ده', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                  const SizedBox(height: 8),
                                  Text('${unprofitableCargos.length}', style: const TextStyle(fontSize: 18, color: Colors.red)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      _buildSummaryRow('مجموع ارزش بار:', '${formatNumber(reportData.totalPriceSum)} تومان', 
                        color: Colors.blue,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                      _buildSummaryRow('مجموع هزینه‌های حمل:', '${formatNumber(reportData.totalTransportCosts)} تومان',
                        color: Colors.red, 
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                      _buildSummaryRow('سود خالص:', '${formatNumber(reportData.totalNetProfit)} تومان', 
                        color: reportData.totalNetProfit > 0 ? Colors.green : Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // کارت مقایسه سرویس‌های مقطوع و عادی
              Card(
                color: Colors.amber.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'مقایسه سرویس‌های مقطوع و عادی',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  const Text('مقطوع', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text('${reportData.fixedPriceServices}', style: const TextStyle(fontSize: 18)),
                                  const SizedBox(height: 4),
                                  Text('${formatNumber(reportData.fixedPriceValuesSum)} تومان', style: const TextStyle(fontSize: 12, color: Colors.blue)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  const Text('عادی', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text('${cargos.length - reportData.fixedPriceServices}', style: const TextStyle(fontSize: 18)),
                                  const SizedBox(height: 4),
                                  Text('${formatNumber(reportData.normalServicesValue)} تومان', style: const TextStyle(fontSize: 12, color: Colors.blue)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      _buildSummaryRow('سود سرویس‌های مقطوع:', '${formatNumber(reportData.fixedPriceValuesSum - reportData.fixedPriceTransportSum)} تومان',
                        color: (reportData.fixedPriceValuesSum - reportData.fixedPriceTransportSum) > 0 ? Colors.green : Colors.red),
                      _buildSummaryRow('سود سرویس‌های عادی:', '${formatNumber(reportData.normalServicesValue - reportData.normalServicesTransport)} تومان',
                        color: (reportData.normalServicesValue - reportData.normalServicesTransport) > 0 ? Colors.green : Colors.red),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // کارت نمودار سودآوری
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تحلیل سودآوری',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 160,
                        child: _buildProfitUnprofitChart(profitableCargos.length, unprofitableCargos.length),
                      ),
                      const SizedBox(height: 16),
                      const Text('نسبت سودآوری کلی:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 30,
                        child: LinearProgressIndicator(
                          value: cargos.isNotEmpty ? profitableCargos.length / cargos.length : 0,
                          backgroundColor: Colors.red.shade100,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
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
  
  // نمودار مقایسه سرویس‌های مقطوع و عادی
  Widget _buildFixedVsNormalChart(
    int fixedCount, 
    int normalCount, 
    double fixedValue, 
    double normalValue,
    double fixedTransport,
    double normalTransport
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        
        // دو بخش نمودار داریم
        final sectionWidth = width / 2;
        
        return Row(
          children: [
            // بخش اول: تعداد سرویس‌ها
            SizedBox(
              width: sectionWidth,
              child: Column(
                children: [
                  const Text('تعداد سرویس‌ها', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // ستون سرویس‌های مقطوع
                        if (fixedCount > 0)
                          _buildBarColumn(
                            width: sectionWidth * 0.4,
                            height: fixedCount / (fixedCount + normalCount) * 120,
                            color: Colors.amber,
                            label: 'مقطوع',
                            value: fixedCount.toString(),
                          ),
                          
                        const SizedBox(width: 16),
                        
                        // ستون سرویس‌های عادی
                        if (normalCount > 0)
                          _buildBarColumn(
                            width: sectionWidth * 0.4,
                            height: normalCount / (fixedCount + normalCount) * 120,
                            color: Colors.blue,
                            label: 'عادی',
                            value: normalCount.toString(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // بخش دوم: ارزش و هزینه
            SizedBox(
              width: sectionWidth,
              child: Column(
                children: [
                  const Text('سود خالص', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // ستون سود سرویس‌های مقطوع
                        if (fixedValue > 0 || fixedTransport > 0)
                          _buildBarColumn(
                            width: sectionWidth * 0.4,
                            height: (fixedValue > fixedTransport) ? 120 : (fixedValue / fixedTransport) * 120,
                            color: (fixedValue > fixedTransport) ? Colors.green : Colors.red,
                            label: 'مقطوع',
                            value: formatNumber(fixedValue - fixedTransport),
                          ),
                          
                        const SizedBox(width: 16),
                        
                        // ستون سود سرویس‌های عادی
                        if (normalValue > 0 || normalTransport > 0)
                          _buildBarColumn(
                            width: sectionWidth * 0.4,
                            height: (normalValue > normalTransport) ? 120 : (normalValue / normalTransport) * 120,
                            color: (normalValue > normalTransport) ? Colors.green : Colors.red,
                            label: 'عادی',
                            value: formatNumber(normalValue - normalTransport),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
  
  // نمودار ستونی ساده
  Widget _buildBarColumn({
    required double width,
    required double height,
    required Color color,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: width,
          height: height > 0 ? height : 2, // حداقل ارتفاع
          color: color,
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 9)),
      ],
    );
  }
  
  // نمودار مقایسه سرویس‌های سودده و زیان‌ده
  Widget _buildProfitUnprofitChart(int profitableCount, int unprofitableCount) {
    final total = profitableCount + unprofitableCount;
    
    if (total == 0) {
      return const Center(child: Text('داده‌ای وجود ندارد'));
    }
    
    final profitablePercent = (profitableCount / total) * 100;
    final unprofitablePercent = (unprofitableCount / total) * 100;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        
        return Column(
          children: [
            Container(
              height: 30,
              width: width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Container(
                    width: (profitablePercent / 100) * width,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        bottomLeft: Radius.circular(15),
                        topRight: unprofitableCount == 0 ? Radius.circular(15) : Radius.zero,
                        bottomRight: unprofitableCount == 0 ? Radius.circular(15) : Radius.zero,
                      ),
                    ),
                  ),
                  Container(
                    width: (unprofitablePercent / 100) * width,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(15),
                        bottomRight: Radius.circular(15),
                        topLeft: profitableCount == 0 ? Radius.circular(15) : Radius.zero,
                        bottomLeft: profitableCount == 0 ? Radius.circular(15) : Radius.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('سودده: $profitableCount (${profitablePercent.toStringAsFixed(1)}%)', 
                  style: const TextStyle(color: Colors.green, fontSize: 12)),
                Text('زیان‌ده: $unprofitableCount (${unprofitablePercent.toStringAsFixed(1)}%)', 
                  style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 16),
            const Text('راهنما:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(width: 12, height: 12, color: Colors.green),
                const SizedBox(width: 8),
                const Text('سرویس‌های سودده', style: TextStyle(fontSize: 11)),
                const SizedBox(width: 24),
                Container(width: 12, height: 12, color: Colors.red),
                const SizedBox(width: 8),
                const Text('سرویس‌های زیان‌ده', style: TextStyle(fontSize: 11)),
              ],
            ),
          ],
        );
      },
    );
  }

  // تابع محاسبه آمار مشترک بین گزارش‌ها
  ReportData _calculateReportData(List<Cargo> cargos) {
    // مقادیر پیش‌فرض
    double totalPriceSum = 0;
    double totalTransportCosts = 0;
    double totalPaidSum = 0;
    double totalRemainingSum = 0;
    double totalNetProfit = 0;
    
    int fixedPriceServices = 0;
    double fixedPriceValuesSum = 0;
    double fixedPriceTransportSum = 0;
    
    double normalServicesValue = 0;
    double normalServicesTransport = 0;
    
    int weightBasedServices = 0;
    int transportBasedServices = 0;
    int combinedServices = 0;
    
    double transportBasedValue = 0;
    double weightBasedValue = 0;
    double combinedValue = 0;
    double combinedTransport = 0;
    
    int completedPayments = 0;
    int partialPayments = 0;
    int pendingPayments = 0;
    
    // باکس پرداخت‌ها
    final paymentsBox = Hive.box<Payment>('payments');
    
    // محاسبه مقادیر
    for (final cargo in cargos) {
      // محاسبه جمع کل هر بار
      totalPriceSum += cargo.totalPrice;
      totalTransportCosts += cargo.totalTransportCost;
      totalNetProfit += cargo.netProfit;
      
      // محاسبه پرداخت‌ها
      final cargoPayments = paymentsBox.values.where((p) => p.cargo.key == cargo.key).toList();
      final totalPaid = cargoPayments.fold(0.0, (sum, p) => sum + p.amount);
      totalPaidSum += totalPaid;
      
      // محاسبه مجموع کل (هزینه حمل + قیمت کل)
      final totalCargoAmount = cargo.totalPrice + cargo.totalTransportCost;
      final remaining = totalCargoAmount - totalPaid;
      totalRemainingSum += remaining > 0 ? remaining : 0;
      
      // آمار وضعیت پرداخت
      if (remaining <= 0) {
        completedPayments++;
      } else if (totalPaid > 0) {
        partialPayments++;
      } else {
        pendingPayments++;
      }
      
      // تفکیک آمار سرویس‌های مقطوع و عادی
      if (cargo.weight == 0) {
        fixedPriceServices++;
        fixedPriceValuesSum += cargo.totalPrice;
        fixedPriceTransportSum += cargo.totalTransportCost;
        
        // سرویس بر اساس هزینه حمل
        if (cargo.transportCostPerTon > 0) {
          transportBasedServices++;
          transportBasedValue += cargo.totalPrice;
        }
      } else {
        normalServicesValue += cargo.totalPrice;
        normalServicesTransport += cargo.totalTransportCost;
        
        // سرویس بر اساس وزن
        if (cargo.transportCostPerTon == 0) {
          weightBasedServices++;
          weightBasedValue += cargo.totalPrice;
        } 
        // سرویس ترکیبی
        else if (cargo.transportCostPerTon > 0) {
          combinedServices++;
          combinedValue += cargo.totalPrice;
          combinedTransport += cargo.totalTransportCost;
        }
      }
    }
    
    // محاسبه مجموع کل
    final totalAmount = totalPriceSum + totalTransportCosts;
    
    return ReportData(
      totalPriceSum: totalPriceSum,
      totalTransportCosts: totalTransportCosts,
      totalAmount: totalAmount,
      totalPaidSum: totalPaidSum,
      totalRemainingSum: totalRemainingSum,
      totalNetProfit: totalNetProfit,
      fixedPriceServices: fixedPriceServices,
      fixedPriceValuesSum: fixedPriceValuesSum,
      fixedPriceTransportSum: fixedPriceTransportSum,
      normalServicesValue: normalServicesValue,
      normalServicesTransport: normalServicesTransport,
      weightBasedServices: weightBasedServices,
      transportBasedServices: transportBasedServices,
      combinedServices: combinedServices,
      transportBasedValue: transportBasedValue,
      weightBasedValue: weightBasedValue,
      combinedValue: combinedValue,
      combinedTransport: combinedTransport,
      completedPayments: completedPayments,
      partialPayments: partialPayments,
      pendingPayments: pendingPayments,
    );
  }
} 