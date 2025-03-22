import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:khatooniiii/models/cargo.dart';
import 'package:khatooniiii/screens/cargo_form.dart';
import 'package:intl/intl.dart';

class CargoList extends StatelessWidget {
  const CargoList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لیست محموله‌ها'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CargoForm()),
              );
            },
          ),
        ],
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
                    'محموله‌ای یافت نشد',
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
                    label: const Text('افزودن محموله'),
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
                  subtitle: Text(
                    '${cargo.origin} به ${cargo.destination} - ${DateFormat('yyyy/MM/dd').format(cargo.date)}',
                  ),
                  trailing: Text(
                    '${cargo.weight} تن\n${NumberFormat.currency(symbol: 'تومان').format(totalPrice)}',
                    textAlign: TextAlign.end,
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
        title: const Text('جزئیات محموله'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('راننده', cargo.driver.name),
              _buildDetailRow('وسیله نقلیه', cargo.vehicle.vehicleName),
              _buildDetailRow('نوع محموله', cargo.cargoType.cargoName),
              _buildDetailRow('مسیر', '${cargo.origin} به ${cargo.destination}'),
              _buildDetailRow('تاریخ', DateFormat('yyyy/MM/dd').format(cargo.date)),
              _buildDetailRow('وزن', '${cargo.weight} تن'),
              _buildDetailRow('قیمت هر تن', NumberFormat.currency(symbol: 'تومان').format(cargo.pricePerTon)),
              _buildDetailRow('قیمت کل', NumberFormat.currency(symbol: 'تومان').format(cargo.totalPrice)),
              _buildDetailRow('وضعیت پرداخت', _getPaymentStatusText(cargo.paymentStatus)),
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
            onPressed: () async {
              final confirmed = await _confirmDelete(context);
              if (confirmed && context.mounted) {
                await cargo.delete();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('محموله با موفقیت حذف شد')),
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

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأیید حذف'),
        content: const Text('آیا از حذف این محموله اطمینان دارید؟ این عمل قابل بازگشت نیست.'),
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