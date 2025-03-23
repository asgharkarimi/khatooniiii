import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:khatooniiii/models/cargo.dart';
import 'package:khatooniiii/models/payment.dart';
import 'package:khatooniiii/models/expense.dart';
import 'package:khatooniiii/screens/cargo_form.dart';
import 'package:khatooniiii/screens/payment_form.dart';
import 'package:khatooniiii/screens/expense_form.dart';
import 'package:khatooniiii/utils/number_formatter.dart';
import 'package:intl/intl.dart';
import 'package:khatooniiii/screens/reports/cargo_report_screen.dart';

class CargoList extends StatelessWidget {
  const CargoList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لیست سرویس بار'),
        actions: [
          // دکمه گزارش گیری
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'گزارش گیری',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CargoReportScreen()),
              );
            },
          ),
          // دکمه فیلتر کردن
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'فیلتر کردن',
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: Stack(
                children: [
          _buildCargoList(),
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CargoForm()),
                      );
                    },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('افزودن سرویس بار', style: TextStyle(color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // نمایش دیالوگ فیلتر کردن سرویس‌ها
  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('فیلتر کردن سرویس‌ها'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // انتخاب تاریخ
              const Text('بازه زمانی:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildFilterOption(context, 'امروز', Icons.today),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFilterOption(context, 'هفته', Icons.date_range),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildFilterOption(context, 'ماه', Icons.calendar_month),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFilterOption(context, 'همه', Icons.all_inclusive),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // فیلترهای دیگر
              _buildFilterSwitch(context, 'فقط سرویس‌های بدهکار', false),
              _buildFilterSwitch(context, 'مرتب‌سازی بر اساس مبلغ', false),
              _buildFilterSwitch(context, 'فقط سرویس‌های امروز', false),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('برای فیلتر پیشرفته‌تر از بخش گزارش گیری استفاده کنید')),
              );
              Navigator.of(context).pop();
            },
            child: const Text('فیلتر پیشرفته'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('بستن'),
          ),
        ],
      ),
    );
  }

  // ساخت دکمه‌های فیلتر
  Widget _buildFilterOption(BuildContext context, String title, IconData icon) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فیلتر $title اعمال شد')),
        );
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

  // ساخت کلیدهای فیلتر
  Widget _buildFilterSwitch(BuildContext context, String title, bool value) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      value: value,
      onChanged: (bool newValue) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فیلتر $title ${newValue ? 'فعال' : 'غیرفعال'} شد')),
        );
      },
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildCargoList() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Cargo>('cargos').listenable(),
      builder: (context, Box<Cargo> box, _) {
        final cargoes = box.values.toList();
        cargoes.sort((a, b) => b.date.compareTo(a.date));

        if (cargoes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'سرویس باری یافت نشد',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        }
          
          return ListView.builder(
          padding: const EdgeInsets.only(bottom: 100), // Add padding to the bottom for the button
          itemCount: cargoes.length,
            itemBuilder: (context, index) {
            final cargo = cargoes[index];
              return Card(
              margin: const EdgeInsets.all(8.0),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${cargo.origin} به ${cargo.destination}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${DateFormat('yyyy/MM/dd').format(cargo.date)} • ${cargo.driver.name}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      '${cargo.vehicle.vehicleName} • نوع: ${cargo.cargoType.cargoName}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'وزن: ${cargo.weight} کیلوگرم',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'قیمت کل: ${formatNumber(cargo.totalPrice)} تومان',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (cargo.transportCostPerTon > 0)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'مجموع هزینه حمل = ${formatNumber(cargo.totalTransportCost)} تومان',
                                      style: TextStyle(
                                        fontSize: 14, 
                                        color: Colors.indigo[700], 
                                        fontWeight: FontWeight.bold
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildPaymentInfo(cargo),
                      ],
                    ),
                    _buildExpenseInfo(cargo),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => _showCargoDetails(context, cargo),
                        child: const Text('مشاهده جزئیات'),
                      ),
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

  // نمایش وضعیت پرداخت
  Widget _buildPaymentInfo(Cargo cargo) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Payment>('payments').listenable(),
      builder: (context, Box<Payment> box, _) {
        final paymentsForCargo = box.values
            .where((payment) => 
              payment.cargo != null && 
              payment.cargo.key != null && 
              cargo.key != null &&
              payment.cargo.key == cargo.key)
            .toList();

        // محاسبه جمع پرداخت‌ها
        double totalPaid = paymentsForCargo.fold(
            0.0, (sum, payment) => sum + payment.amount);
        double remaining = cargo.totalPrice - totalPaid;

        if (paymentsForCargo.isEmpty) {
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 100),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'پرداخت نشده',
                style: TextStyle(color: Colors.red, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          );
        } else if (remaining > 0) {
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'بدهکار: ${formatNumber(remaining)} تومان',
                style: const TextStyle(color: Colors.deepOrange, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          );
        } else if (remaining == 0) {
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 100),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'پرداخت شده',
                style: TextStyle(color: Colors.green, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          );
        } else {
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'اضافه‌پرداخت: ${formatNumber(-remaining)} تومان',
                style: const TextStyle(color: Colors.blue, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
      },
    );
  }

  // نمایش اطلاعات هزینه‌ها
  Widget _buildExpenseInfo(Cargo cargo) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Expense>('expenses').listenable(),
      builder: (context, Box<Expense> box, _) {
        final expensesForCargo = box.values
            .where((expense) => 
              expense.cargo != null && 
              expense.cargo?.key != null && 
              cargo.key != null &&
              expense.cargo!.key == cargo.key)
            .toList();
        
        if (expensesForCargo.isEmpty) {
          return const SizedBox.shrink();
        }
        
        // محاسبه جمع هزینه‌ها
        final totalExpenses = expensesForCargo.fold(
            0.0, (sum, expense) => sum + expense.amount);
        
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 180),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.money_off, size: 14, color: Colors.purple.shade700),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '${expensesForCargo.length} هزینه (${formatNumber(totalExpenses)} تومان)',
                    style: TextStyle(fontSize: 12, color: Colors.purple.shade700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCargoDetails(BuildContext context, Cargo cargo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width - 32,
            maxHeight: MediaQuery.of(context).size.height - 64,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue[800],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${cargo.origin} به ${cargo.destination}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: Colors.white.withOpacity(0.9)),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('yyyy/MM/dd').format(cargo.date),
                            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Driver and vehicle info card
                        Card(
                          color: Colors.blue[50],
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.blue.shade200, width: 1),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.person, size: 20, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'راننده: ${cargo.driver.name}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.local_shipping, size: 20, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'وسیله نقلیه: ${cargo.vehicle.vehicleName}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.category, size: 20, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'نوع سرویس بار: ${cargo.cargoType.cargoName}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Cargo details card
                        Card(
                          color: Colors.grey[50],
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey.shade300, width: 1),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'اطلاعات بار',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.scale, size: 20, color: Colors.grey[700]),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'وزن: ${formatNumber(cargo.weight)} کیلوگرم (${formatNumber(cargo.weightInTons, separator: '/')} تن)',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.attach_money, size: 20, color: Colors.grey[700]),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text('قیمت هر تن: ${formatNumber(cargo.pricePerTon)} تومان'),
                                    ),
                                  ],
                                ),
                                if (cargo.transportCostPerTon > 0) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.local_shipping_outlined, size: 20, color: Colors.indigo),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'هزینه حمل هر تن: ${formatNumber(cargo.transportCostPerTon)} تومان',
                                          style: TextStyle(color: Colors.indigo[700]),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Price summary card
                        Card(
                          color: Colors.green[50],
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.green.shade200, width: 1),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'خلاصه مالی',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: const Text('قیمت کل سرویس بار:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${formatNumber(cargo.totalPrice)} تومان',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                if (cargo.transportCostPerTon > 0) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: const Text(
                                          'هزینه حمل کل:',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${formatNumber(cargo.totalTransportCost)} تومان',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.indigo[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: const Text(
                                        'وضعیت پرداخت:',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getPaymentStatusColor(cargo.paymentStatus).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: _getPaymentStatusColor(cargo.paymentStatus).withOpacity(0.5),
                                        ),
                                      ),
                                      child: Text(
                                        _getPaymentStatusText(cargo.paymentStatus),
                                        style: TextStyle(
                                          color: _getPaymentStatusColor(cargo.paymentStatus),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const Divider(height: 24),
                        _buildPaymentsList(context, cargo),
                        const Divider(height: 24),
                        _buildExpensesList(context, cargo),
                      ],
                    ),
                  ),
                ),
                
                // Action buttons
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          final confirmed = await _confirmDelete(context);
                          if (confirmed && context.mounted) {
                            await cargo.delete();
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('سرویس بار با موفقیت حذف شد')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                        label: const Text('حذف', style: TextStyle(color: Colors.red)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _addExpenseForCargo(context, cargo);
                            },
                            icon: const Icon(Icons.money_off, size: 18),
                            label: const Text('هزینه'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _addPaymentForCargo(context, cargo);
                            },
                            icon: const Icon(Icons.payment, size: 18),
                            label: const Text('پرداخت'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
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
        ),
      ),
    );
  }

  Color _getPaymentStatusColor(int status) {
    switch (status) {
      case PaymentStatus.fullyPaid:
        return Colors.green;
      case PaymentStatus.partiallyPaid:
        return Colors.orange;
      case PaymentStatus.pending:
      default:
        return Colors.red;
    }
  }

  Widget _buildPaymentsList(BuildContext context, Cargo cargo) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Payment>('payments').listenable(),
      builder: (context, Box<Payment> box, _) {
        final paymentsForCargo = box.values
            .where((payment) => 
              payment.cargo != null && 
              payment.cargo.key != null && 
              cargo.key != null &&
              payment.cargo.key == cargo.key)
            .toList();
        
        // قیمت کل بر اساس وزن و قیمت هر تن
        final totalCargoPrice = cargo.totalPrice;
        
        if (paymentsForCargo.isEmpty) {
          return Card(
            elevation: 0,
            color: Colors.red[50],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.red.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.payment, size: 20, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'پرداخت‌ها',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('هیچ پرداختی برای این سرویس بار ثبت نشده است.'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: const Text('قیمت کل سرویس بار:', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${formatNumber(totalCargoPrice)} تومان',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: const Text('بدهکاری:', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${formatNumber(totalCargoPrice)} تومان',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
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
        }
        
        // محاسبه جمع پرداخت‌ها
        double totalPaid = paymentsForCargo.fold(
            0.0, (sum, payment) => sum + payment.amount);
        double remaining = totalCargoPrice - totalPaid;
        
        // مرتب‌سازی پرداخت‌ها بر اساس تاریخ (جدیدترین در بالا)
        paymentsForCargo.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
        
        return Card(
          elevation: 0,
          color: remaining > 0 ? Colors.orange[50] : Colors.green[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: remaining > 0 ? Colors.orange.shade200 : Colors.green.shade200
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.payment, 
                      size: 20,
                      color: remaining > 0 ? Colors.orange[700] : Colors.green[700]
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'پرداخت‌ها',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: remaining > 0 
                            ? Colors.orange.withOpacity(0.2) 
                            : Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${paymentsForCargo.length} پرداخت',
                        style: TextStyle(
                          fontSize: 12,
                          color: remaining > 0 ? Colors.orange[800] : Colors.green[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // لیست پرداخت‌ها
                ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: paymentsForCargo.length,
                  separatorBuilder: (context, index) => const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final payment = paymentsForCargo[index];
                    final paymentIcon = payment.paymentType == PaymentType.cash
                        ? Icons.money
                        : payment.paymentType == PaymentType.cardToCard
                            ? Icons.credit_card
                            : payment.paymentType == PaymentType.check
                                ? Icons.note
                                : Icons.account_balance;
                    
                    return Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Icon(paymentIcon, size: 18, color: Colors.grey[700]),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _getPaymentTypeText(payment.paymentType),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${formatNumber(payment.amount)} تومان',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('yyyy/MM/dd').format(payment.paymentDate),
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                
                const SizedBox(height: 16),
                
                // خلاصه پرداخت
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: remaining > 0 
                          ? Colors.orange.shade300 
                          : Colors.green.shade300
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: const Text('قیمت کل:', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${formatNumber(totalCargoPrice)} تومان',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: const Text('جمع پرداخت‌ها:', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${formatNumber(totalPaid)} تومان',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              remaining > 0 ? 'بدهکاری:' : (remaining < 0 ? 'اضافه پرداخت:' : 'وضعیت:'), 
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: remaining > 0
                                  ? Colors.red.withOpacity(0.1)
                                  : (remaining < 0 
                                      ? Colors.blue.withOpacity(0.1) 
                                      : Colors.green.withOpacity(0.1)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              remaining > 0 
                                  ? '${formatNumber(remaining)} تومان' 
                                  : (remaining < 0 
                                      ? '${formatNumber(-remaining)} تومان' 
                                      : 'پرداخت شده'),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: remaining > 0 
                                    ? Colors.red 
                                    : (remaining < 0 ? Colors.blue : Colors.green),
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
          ),
        );
      },
    );
  }

  Widget _buildExpensesList(BuildContext context, Cargo cargo) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Expense>('expenses').listenable(),
      builder: (context, Box<Expense> box, _) {
        final expensesForCargo = box.values
            .where((expense) => 
              expense.cargo != null && 
              expense.cargo?.key != null && 
              cargo.key != null &&
              expense.cargo!.key == cargo.key)
            .toList();
        
        // محاسبه جمع هزینه‌ها
        final totalExpenses = expensesForCargo.fold(
            0.0, (sum, expense) => sum + expense.amount);
        
        if (expensesForCargo.isEmpty) {
          return Card(
            elevation: 0,
            color: Colors.purple[50],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.purple.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.money_off, size: 20, color: Colors.purple[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'هزینه‌ها',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('هیچ هزینه‌ای برای این سرویس بار ثبت نشده است.'),
                ],
              ),
            ),
          );
        }

        // مرتب‌سازی هزینه‌ها بر اساس تاریخ (جدیدترین در بالا)
        expensesForCargo.sort((a, b) => b.date.compareTo(a.date));

        return Card(
          elevation: 0,
          color: Colors.purple[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.purple.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.money_off, size: 20, color: Colors.purple[700]),
                    const SizedBox(width: 8),
                    const Text(
                      'هزینه‌ها',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${expensesForCargo.length} هزینه',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.purple[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // لیست هزینه‌ها
                ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: expensesForCargo.length,
                  separatorBuilder: (context, index) => const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final expense = expensesForCargo[index];
                    
                    // تعیین آیکون مناسب برای دسته‌بندی هزینه
                    IconData categoryIcon;
                    switch (expense.category.toLowerCase()) {
                      case 'سوخت':
                        categoryIcon = Icons.local_gas_station;
                        break;
                      case 'تعمیرات':
                        categoryIcon = Icons.build;
                        break;
                      case 'عوارض':
                        categoryIcon = Icons.toll;
                        break;
                      case 'جریمه':
                        categoryIcon = Icons.assignment_late;
                        break;
                      default:
                        categoryIcon = Icons.attach_money;
                    }
                    
                    return Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Icon(categoryIcon, size: 18, color: Colors.purple),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      expense.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${formatNumber(expense.amount)} تومان',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      expense.category,
                                      style: TextStyle(fontSize: 10, color: Colors.purple[800]),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      DateFormat('yyyy/MM/dd').format(expense.date),
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                
                const SizedBox(height: 16),
                
                // خلاصه هزینه
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: const Text('جمع کل هزینه‌ها:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${formatNumber(totalExpenses)} تومان',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _addPaymentForCargo(BuildContext context, Cargo cargo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentForm(cargo: cargo),
      ),
    );
  }

  void _addExpenseForCargo(BuildContext context, Cargo cargo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpenseForm(
          expense: Expense(
            title: '', 
            amount: 0,
            date: DateTime.now(),
            category: 'سوخت',
            cargo: cargo
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأیید حذف'),
        content: const Text('آیا از حذف این سرویس بار اطمینان دارید؟ این عمل قابل بازگشت نیست.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('لغو'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  String _getPaymentStatusText(int status) {
    switch (status) {
      case PaymentStatus.fullyPaid:
        return 'پرداخت شده';
      case PaymentStatus.partiallyPaid:
        return 'پرداخت جزئی';
      case PaymentStatus.pending:
      default:
        return 'در انتظار پرداخت';
    }
  }

  String _getPaymentTypeText(int paymentType) {
    switch (paymentType) {
      case PaymentType.cash:
        return 'نقدی';
      case PaymentType.check:
        return 'چک';
      case PaymentType.cardToCard:
        return 'کارت به کارت';
      case PaymentType.bankTransfer:
        return 'واریز بانکی';
      default:
        return 'سایر';
    }
  }
} 