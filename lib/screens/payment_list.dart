import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:khatooniiii/models/payment.dart';
import 'package:khatooniiii/screens/payment_form.dart';
import 'package:khatooniiii/utils/number_formatter.dart';
import 'package:intl/intl.dart';
import 'package:khatooniiii/widgets/float_button_style.dart';

class PaymentList extends StatelessWidget {
  const PaymentList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لیست پرداخت‌ها'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Payment>('payments').listenable(),
        builder: (context, Box<Payment> box, _) {
          final payments = box.values.toList();
          
          if (payments.isEmpty) {
            return const Center(
              child: Text('هیچ پرداختی ثبت نشده است'),
            );
          }
          
          // مرتب‌سازی پرداخت‌ها بر اساس تاریخ (جدیدترین اول)
          payments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
          
          return ListView.builder(
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              
              return Dismissible(
                key: Key(payment.key.toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                onDismissed: (direction) {
                  // حذف پرداخت
                  box.delete(payment.key);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('پرداخت با موفقیت حذف شد')),
                  );
                },
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('حذف پرداخت'),
                        content: const Text('آیا از حذف این پرداخت اطمینان دارید؟'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('انصراف'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('حذف'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(
                      '${formatNumber(payment.amount)} تومان',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('تاریخ: ${DateFormat('yyyy/MM/dd').format(payment.paymentDate)}'),
                        Text('پرداخت کننده: ${payment.customer.firstName} ${payment.customer.lastName}'),
                        Text('برای سرویس: از ${payment.cargo.origin} به ${payment.cargo.destination}'),
                      ],
                    ),
                    trailing: const Icon(Icons.payment),
                    onTap: () {
                      // نمایش جزئیات پرداخت
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('جزئیات پرداخت'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('مبلغ: ${formatNumber(payment.amount)} تومان'),
                              Text('تاریخ: ${DateFormat('yyyy/MM/dd').format(payment.paymentDate)}'),
                              Text('پرداخت کننده: ${payment.customer.firstName} ${payment.customer.lastName}'),
                              Text('شماره تماس: ${payment.customer.phone}'),
                              Text('سرویس: از ${payment.cargo.origin} به ${payment.cargo.destination}'),
                              Text('راننده: ${payment.cargo.driver.name}'),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('بستن'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatButtonStyle(
        label: 'ثبت پرداخت جدید',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PaymentForm()),
          );
        },
        icon: Icons.add,
        tooltip: 'ثبت پرداخت جدید',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
} 