import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:khatooniiii/models/cargo.dart';
import 'package:khatooniiii/screens/driver_salary_form.dart';
import 'package:khatooniiii/models/driver_salary.dart';
import 'package:khatooniiii/utils/app_date_utils.dart';

class CargoListWithSalary extends StatelessWidget {
  const CargoListWithSalary({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لیست سرویس‌ها و حقوق'),
      ),
      body: _buildCargoList(),
    );
  }

  Widget _buildCargoList() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Cargo>('cargos').listenable(),
      builder: (context, Box<Cargo> box, _) {
        final cargos = box.values.toList();
        
        if (cargos.isEmpty) {
          return const Center(child: Text('لیست سرویس‌ها خالی است'));
        }

        return ListView.builder(
          itemCount: cargos.length,
          itemBuilder: (context, index) {
            final cargo = cargos[index];
            return _buildCargoItem(context, cargo);
          },
        );
      },
    );
  }

  Widget _buildCargoItem(BuildContext context, Cargo cargo) {
    final salaries = Hive.box<DriverSalary>('driverSalaries')
        .values
        .where((salary) => salary.cargo?.key == cargo.key)
        .toList();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ExpansionTile(
        title: Text('${cargo.origin} به ${cargo.destination}'),
        subtitle: Text('تعداد پرداخت‌ها: ${salaries.length}'),
        children: [
          if (salaries.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('هیچ پرداختی برای این سرویس ثبت نشده است'),
            )
          else
            ...salaries.map((salary) {
              return ListTile(
                title: Text('${salary.driver.firstName} ${salary.driver.lastName}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مبلغ: ${NumberFormat('#,###').format(salary.amount)} تومان'),
                    Text('تاریخ پرداخت: ${AppDateUtils.toPersianDate(salary.paymentDate)}'),
                  ],
                ),
              );
            }).toList(),
          const Divider(),
          ListTile(
            title: const Text('افزودن پرداخت جدید'),
            trailing: const Icon(Icons.add),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DriverSalaryForm(selectedCargo: cargo),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
} 