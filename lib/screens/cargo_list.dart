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

class CargoList extends StatelessWidget {
  const CargoList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لیست سرویس بار'),
      ),
      body: _buildCargoList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CargoForm()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('افزودن سرویس بار'),
      ),
    );
  }

  Widget _buildCargoList() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Cargo>('cargos').listenable(),
      builder: (context, Box<Cargo> box, _) {
        final cargoes = box.values.toList();
        cargoes.sort((a, b) => b.date.compareTo(a.date));

        if (cargoes.isEmpty) {
          return const Center(
            child: Text(
              'سرویس باری یافت نشد',
              style: TextStyle(fontSize: 18),
            ),
          );
        }

        return ListView.builder(
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
                      children: [
                        Expanded(
                          child: Text(
                            'قیمت کل: ${formatNumber(cargo.totalPrice)} تومان',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildPaymentInfo(cargo),
                      ],
                    ),
                    if (cargo.transportCostPerTon > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              cargo.netProfit > 0 ? Icons.trending_up : Icons.trending_down,
                              size: 16,
                              color: cargo.netProfit > 0 ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'سود خالص: ${formatNumber(cargo.netProfit)} تومان',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: cargo.netProfit > 0 ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
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
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'پرداخت نشده',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          );
        } else if (remaining > 0) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'بدهکار: ${formatNumber(remaining)} تومان',
              style: const TextStyle(color: Colors.deepOrange, fontSize: 12),
            ),
          );
        } else if (remaining == 0) {
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
        } else {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'اضافه‌پرداخت: ${formatNumber(-remaining)} تومان',
              style: const TextStyle(color: Colors.blue, fontSize: 12),
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
          child: Wrap(
            children: [
              Container(
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
                    Text(
                      '${expensesForCargo.length} هزینه (${formatNumber(totalExpenses)} تومان)',
                      style: TextStyle(fontSize: 12, color: Colors.purple.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCargoDetails(BuildContext context, Cargo cargo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('جزئیات سرویس بار'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('راننده', cargo.driver.name),
              _buildDetailRow('وسیله نقلیه', cargo.vehicle.vehicleName),
              _buildDetailRow('نوع سرویس بار', cargo.cargoType.cargoName),
              _buildDetailRow('مسیر', '${cargo.origin} به ${cargo.destination}'),
              _buildDetailRow('تاریخ', DateFormat('yyyy/MM/dd').format(cargo.date)),
              _buildDetailRow('وزن', '${formatNumber(cargo.weight)} کیلوگرم (${formatNumber(cargo.weightInTons, separator: '/')} تن)'),
              _buildDetailRow('قیمت هر تن', '${formatNumber(cargo.pricePerTon)} تومان'),
              if (cargo.transportCostPerTon > 0)
                _buildDetailRow('هزینه حمل هر تن', '${formatNumber(cargo.transportCostPerTon)} تومان'),
              _buildDetailRow('قیمت کل', '${formatNumber(cargo.totalPrice)} تومان'),
              if (cargo.transportCostPerTon > 0) ...[
                _buildDetailRow('هزینه حمل کل', '${formatNumber(cargo.totalTransportCost)} تومان'),
                _buildDetailRow('سود خالص', '${formatNumber(cargo.netProfit)} تومان', 
                  color: cargo.netProfit > 0 ? Colors.green : Colors.red),
              ],
              _buildDetailRow('وضعیت پرداخت', _getPaymentStatusText(cargo.paymentStatus)),
              const Divider(height: 24),
              _buildPaymentsList(context, cargo),
              const Divider(height: 24),
              _buildExpensesList(context, cargo),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Implement edit functionality
              Navigator.pop(context);
            },
            child: const Text('ویرایش'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _addPaymentForCargo(context, cargo);
            },
            child: const Text('افزودن پرداخت', style: TextStyle(color: Colors.green)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _addExpenseForCargo(context, cargo);
            },
            child: const Text('افزودن هزینه', style: TextStyle(color: Colors.orange)),
          ),
          TextButton(
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
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('بستن'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'پرداخت‌ها:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('هیچ پرداختی برای این سرویس بار ثبت نشده است.'),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: const Text('قیمت کل سرویس بار:', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Text(
                            '${formatNumber(totalCargoPrice)} تومان',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: const Text('بدهکاری:', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Text(
                            '${formatNumber(totalCargoPrice)} تومان',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
        
        // محاسبه جمع پرداخت‌ها
        double totalPaid = paymentsForCargo.fold(
            0.0, (sum, payment) => sum + payment.amount);
        double remaining = totalCargoPrice - totalPaid;
        
        // مرتب‌سازی پرداخت‌ها بر اساس تاریخ (جدیدترین در بالا)
        paymentsForCargo.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'پرداخت‌ها:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (var payment in paymentsForCargo)
              Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8.0),
                color: Colors.grey.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('yyyy/MM/dd').format(payment.paymentDate),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _getPaymentTypeText(payment.paymentType),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${formatNumber(payment.amount)} تومان',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            Card(
              elevation: 0,
              color: remaining > 0 ? Colors.red.shade50 : Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: const Text('قیمت کل سرویس بار:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Text(
                          '${formatNumber(totalCargoPrice)} تومان',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: const Text('جمع پرداخت‌ها:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Text(
                          '${formatNumber(totalPaid)} تومان',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            remaining > 0 ? 'بدهکاری:' : (remaining < 0 ? 'اضافه پرداخت:' : 'وضعیت:'), 
                            style: const TextStyle(fontWeight: FontWeight.bold)
                          ),
                        ),
                        Text(
                          remaining > 0 
                              ? '${formatNumber(remaining)} تومان' 
                              : (remaining < 0 
                                  ? '${formatNumber(-remaining)} تومان' 
                                  : 'پرداخت شده'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: remaining > 0 ? Colors.red : (remaining < 0 ? Colors.blue : Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'هزینه‌ها:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('هیچ هزینه‌ای برای این سرویس بار ثبت نشده است.'),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'هزینه‌ها:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (var expense in expensesForCargo)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${expense.title} (${expense.category})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${formatNumber(expense.amount)} تومان',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: const Text('جمع هزینه‌ها:', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Text(
                  '${formatNumber(totalExpenses)} تومان',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: const Text('سود خالص:', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Text(
                  '${formatNumber(cargo.totalPrice - totalExpenses)} تومان',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cargo.totalPrice - totalExpenses > 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
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