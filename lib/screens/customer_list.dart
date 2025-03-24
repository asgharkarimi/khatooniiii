import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:khatooniiii/models/customer.dart';
import 'package:khatooniiii/screens/customer_form.dart';
import 'package:khatooniiii/widgets/float_button_style.dart';

class CustomerList extends StatelessWidget {
  const CustomerList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لیست مشتریان'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Customer>('customers').listenable(),
        builder: (context, Box<Customer> box, _) {
          if (box.isEmpty) {
            return const Center(
              child: Text(
                'هیچ مشتری‌ای ثبت نشده است',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final customers = box.values.toList();
          
          return ListView.builder(
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      customer.firstName.isNotEmpty ? customer.firstName[0] : '?',
                      style: TextStyle(color: Colors.blue[800]),
                    ),
                  ),
                  title: Text('${customer.firstName} ${customer.lastName}'),
                  subtitle: Text(customer.phone),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CustomerForm(customer: customer),
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
        label: 'افزودن مشتری جدید',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CustomerForm()),
          );
        },
        icon: Icons.add,
        tooltip: 'ثبت مشتری جدید',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
} 