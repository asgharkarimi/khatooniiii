import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:khatooniiii/utils/app_date_utils.dart';
import 'package:khatooniiii/models/driver_salary.dart';
import 'package:khatooniiii/models/cargo.dart';
import 'package:flutter/material.dart';
import 'package:khatooniiii/screens/driver_salary_form.dart';

class DriverSalaryList extends StatelessWidget {
  const DriverSalaryList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لیست حقوق راننده'),
      ),
      body: _buildSalaryList(),
    );
  }

  Widget _buildSalaryList() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<DriverSalary>('driverSalaries').listenable(),
      builder: (context, Box<DriverSalary> box, _) {
        final salaries = box.values.toList();
        
        if (salaries.isEmpty) {
          return const Center(child: Text('لیست حقوق‌های راننده خالی است'));
        }

        return ListView.builder(
          itemCount: salaries.length,
          itemBuilder: (context, index) {
            final salary = salaries[index];
            return _buildSalaryItem(context, salary);
          },
        );
      },
    );
  }

  Widget _buildSalaryItem(BuildContext context, DriverSalary salary) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text('${salary.driver.firstName} ${salary.driver.lastName}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('مبلغ: ${NumberFormat('#,###').format(salary.amount)} تومان'),
            Text('تاریخ پرداخت: ${AppDateUtils.toPersianDate(salary.paymentDate)}'),
            Text('روش پرداخت: ${_getPaymentMethodText(salary.paymentMethod)}'),
            if (salary.cargo != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'سرویس انجام شده:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('وزن: ${salary.cargo!.weight} کیلوگرم'),
                  Text('هزینه حمل: ${NumberFormat('#,###').format(salary.cargo!.transportCostPerTon)} تومان'),
                  Text('مبلغ بارنامه: ${NumberFormat('#,###').format(salary.cargo!.waybillAmount)} تومان'),
                ],
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => _deleteSalary(salary),
        ),
        onTap: () => _editSalary(context, salary),
      ),
    );
  }

  void _deleteSalary(DriverSalary salary) {
    final box = Hive.box<DriverSalary>('driverSalaries');
    box.delete(salary.key);
  }

  void _editSalary(BuildContext context, DriverSalary salary) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriverSalaryForm(driverSalary: salary),
      ),
    );
  }

  String _getPaymentMethodText(int paymentMethod) {
    switch (paymentMethod) {
      case 0:
        return 'نقدی';
      case 1:
        return 'انتقال بانکی';
      case 2:
        return 'چک';
      default:
        return 'نامشخص';
    }
  }

  Widget _buildDetailItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$title: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  double _calculateTotalSalary(List<DriverSalary> salaries) {
    return salaries.fold(0.0, (sum, salary) => sum + salary.amount);
  }

  double _calculateTotalPayments(List<DriverSalary> salaries) {
    return salaries.fold(0.0, (sum, salary) => sum + salary.amount);
  }

  double _calculateTotalDebt(List<DriverSalary> salaries) {
    final totalSalary = _calculateTotalSalary(salaries);
    final totalPayments = _calculateTotalPayments(salaries);
    return totalSalary - totalPayments;
  }
} 