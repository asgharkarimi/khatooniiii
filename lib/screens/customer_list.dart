import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:khatooniiii/models/customer.dart';
import 'package:khatooniiii/screens/customer_form.dart';

class CustomerList extends StatelessWidget {
  const CustomerList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لیست مشتریان'),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Customer>('customers').listenable(),
        builder: (context, box, child) {
          if (box.isEmpty) {
            return const Center(
              child: Text('هیچ مشتری ثبت نشده است'),
            );
          }

          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              final customer = box.getAt(index);
              return ListTile(
                title: Text('${customer?.firstName} ${customer?.lastName}'),
                subtitle: Text(customer?.phone ?? 'بدون شماره تماس'),
                // می‌توانید اطلاعات بیشتری از مشتری را اینجا نمایش دهید
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CustomerForm()),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.add),
        label: const Text('افزودن مشتری'),
      ),
    );
  }
} 