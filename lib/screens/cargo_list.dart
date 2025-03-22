import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:khatooniiii/models/cargo.dart';
import 'package:khatooniiii/models/payment.dart';
import 'package:khatooniiii/screens/cargo_form.dart';
import 'package:khatooniiii/screens/payment_form.dart';
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
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Cargo>('cargos').listenable(),
        builder: (context, Box<Cargo> box, _) {
          if (box.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 60,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'سرویس باری یافت نشد',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CargoForm()),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('افزودن سرویس بار'),
                  ),
                ],
              ),
            );
          }

          final cargos = box.values.toList();
          
          // Sort by date (most recent first)
          cargos.sort((a, b) => b.date.compareTo(a.date));
          
          return ListView.builder(
            itemCount: cargos.length,
            itemBuilder: (context, index) {
              final cargo = cargos[index];
              final driver = cargo.driver;
              final totalPrice = cargo.totalPrice;
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getPaymentStatusColor(cargo.paymentStatus),
                    child: Icon(
                      _getPaymentStatusIcon(cargo.paymentStatus),
                      color: Colors.white,
                    ),
                  ),
                  title: Text('${driver.name} - ${cargo.cargoType.cargoName}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${cargo.origin} به ${cargo.destination}'),
                      Text('وزن: ${formatNumber(cargo.weight)} کیلوگرم (${formatNumber(cargo.weightInTons, separator: '/')} تن)'),
                      Text('قیمت هر تن: ${formatNumber(cargo.pricePerTon)} تومان'),
                      Text('قیمت کل: ${formatNumber(totalPrice)} تومان'),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getPaymentStatusColor(cargo.paymentStatus).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getPaymentStatusText(cargo.paymentStatus),
                      style: TextStyle(
                        color: _getPaymentStatusColor(cargo.paymentStatus),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  onTap: () {
                    _showCargoDetails(context, cargo);
                  },
                ),
              );
            },
          );
        },
      ),
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

  IconData _getPaymentStatusIcon(int status) {
    switch (status) {
      case PaymentStatus.fullyPaid:
        return Icons.check_circle;
      case PaymentStatus.partiallyPaid:
        return Icons.pending;
      case PaymentStatus.pending:
      default:
        return Icons.money_off;
    }
  }

  String _getPaymentStatusText(int status) {
    switch (status) {
      case PaymentStatus.fullyPaid:
        return 'پرداخت کامل';
      case PaymentStatus.partiallyPaid:
        return 'پرداخت جزئی';
      case PaymentStatus.pending:
      default:
        return 'در انتظار پرداخت';
    }
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
              _buildDetailRow('قیمت کل', '${formatNumber(cargo.totalPrice)} تومان'),
              _buildDetailRow('وضعیت پرداخت', _getPaymentStatusText(cargo.paymentStatus)),
              const Divider(height: 24),
              _buildPaymentsList(context, cargo),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('قیمت کل سرویس بار:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${formatNumber(totalCargoPrice)} تومان',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          );
        }
        
        // محاسبه جمع پرداخت‌ها
        double totalPaid = paymentsForCargo.fold(
            0, (sum, payment) => sum + payment.amount);
        double remaining = totalCargoPrice - totalPaid;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'پرداخت‌ها:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (var payment in paymentsForCargo)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('yyyy/MM/dd').format(payment.paymentDate),
                    ),
                    Text(
                      '${formatNumber(payment.amount)} تومان',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('قیمت کل سرویس بار:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                const Text('جمع پرداخت‌ها:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                const Text('مانده قابل پرداخت:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '${formatNumber(remaining)} تومان',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: remaining > 0 ? Colors.red : Colors.green,
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
} 