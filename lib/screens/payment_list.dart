import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:khatooniiii/models/payment.dart';
import 'package:khatooniiii/screens/payment_form.dart';
import 'package:intl/intl.dart';

class PaymentList extends StatelessWidget {
  const PaymentList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('پرداخت‌ها'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PaymentForm()),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Payment>('payments').listenable(),
        builder: (context, Box<Payment> box, _) {
          if (box.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'هنوز هیچ پرداختی ثبت نشده است',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PaymentForm()),
                      );
                    },
                    child: const Text('ثبت پرداخت جدید'),
                  ),
                ],
              ),
            );
          }

          final payments = box.values.toList();
          
          // Sort by date (most recent first)
          payments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              final customer = payment.customer;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                child: InkWell(
                  onTap: () => _showPaymentDetails(context, payment),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: _getPaymentTypeColor(payment.paymentType),
                              child: Icon(
                                _getPaymentTypeIcon(payment.paymentType),
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${customer.firstName} ${customer.lastName}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_getPayerTypeText(payment.payerType)} - ${DateFormat('yyyy/MM/dd').format(payment.paymentDate)}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${NumberFormat('#,###').format(payment.amount)} تومان',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.edit, size: 20),
                              label: const Text('ویرایش'),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PaymentForm(payment: payment),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                              label: const Text('حذف', style: TextStyle(color: Colors.red)),
                              onPressed: () => _confirmDelete(context, payment),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PaymentForm()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getPaymentTypeColor(int type) {
    switch (type) {
      case PaymentType.cash:
        return Colors.green;
      case PaymentType.check:
        return Colors.blue;
      case PaymentType.cardToCard:
        return Colors.purple;
      case PaymentType.bankTransfer:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getPaymentTypeIcon(int type) {
    switch (type) {
      case PaymentType.cash:
        return Icons.attach_money;
      case PaymentType.check:
        return Icons.receipt_long;
      case PaymentType.cardToCard:
        return Icons.credit_card;
      case PaymentType.bankTransfer:
        return Icons.account_balance;
      default:
        return Icons.payment;
    }
  }

  String _getPaymentTypeText(int type) {
    switch (type) {
      case PaymentType.cash:
        return 'نقدی';
      case PaymentType.check:
        return 'چک';
      case PaymentType.cardToCard:
        return 'کارت به کارت';
      case PaymentType.bankTransfer:
        return 'انتقال بانکی';
      default:
        return 'نامشخص';
    }
  }

  String _getPayerTypeText(int type) {
    switch (type) {
      case PayerType.driverToCompany:
        return 'راننده به شرکت';
      case PayerType.customerToDriver:
        return 'مشتری به راننده';
      default:
        return 'نامشخص';
    }
  }

  void _showPaymentDetails(BuildContext context, Payment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('جزئیات پرداخت'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('مشتری:', '${payment.customer.firstName} ${payment.customer.lastName}'),
              _buildDetailRow('مبلغ:', '${NumberFormat('#,###').format(payment.amount)} تومان'),
              _buildDetailRow('نوع پرداخت:', _getPaymentTypeText(payment.paymentType)),
              _buildDetailRow('نوع پرداخت کننده:', _getPayerTypeText(payment.payerType)),
              _buildDetailRow('تاریخ پرداخت:', DateFormat('yyyy/MM/dd').format(payment.paymentDate)),
              if (payment.checkDueDate != null)
                _buildDetailRow('تاریخ سررسید چک:', DateFormat('yyyy/MM/dd').format(payment.checkDueDate!)),
              _buildDetailRow('بار:', '${payment.cargo.driver.name} - ${payment.cargo.origin} به ${payment.cargo.destination}'),
              _buildDetailRow('تاریخ بار:', DateFormat('yyyy/MM/dd').format(payment.cargo.date)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('بستن'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Payment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف پرداخت'),
        content: const Text('آیا از حذف این پرداخت اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () {
              payment.delete();
              Navigator.of(context).pop();
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
} 