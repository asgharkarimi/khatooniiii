import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:khatooniiii/models/expense.dart';
import 'package:khatooniiii/screens/expense_form.dart';
import 'package:intl/intl.dart';
import 'package:khatooniiii/widgets/float_button_style.dart';
import 'dart:io';
import 'package:khatooniiii/utils/date_utils.dart' as date_utils;

class ExpenseList extends StatelessWidget {
  const ExpenseList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لیست هزینه‌ها'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: _buildExpenseList(),
      floatingActionButton: FloatButtonStyle(
        label: 'ثبت هزینه جدید',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ExpenseForm()),
          );
        },
        icon: Icons.add,
        tooltip: 'ثبت هزینه جدید',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildExpenseList() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Expense>('expenses').listenable(),
      builder: (context, expensesBox, _) {
        if (expensesBox.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'هنوز هیچ هزینه‌ای ثبت نشده است',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ExpenseForm()),
                    );
                  },
                  child: const Text('ثبت هزینه جدید'),
                ),
              ],
            ),
          );
        }

        // Sort expenses by date (newest first)
        final expenses = expensesBox.values.toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final expense = expenses[index];
            final hasImage = expense.imagePath != null;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              child: InkWell(
                onTap: () => _showExpenseDetails(context, expense),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image preview if exists
                    if (hasImage)
                      Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                          image: DecorationImage(
                            image: FileImage(File(expense.imagePath!)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ListTile(
                      title: Text(
                        expense.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${expense.category} - ${date_utils.AppDateUtils.toPersianDate(expense.date)}',
                      ),
                      trailing: Text(
                        _formatAmount(expense.amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      leading: _getCategoryIcon(expense.category),
                    ),
                    // Show related cargo info if available
                    if (expense.cargo != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.local_shipping, size: 14, color: Colors.blue.shade700),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${expense.cargo!.driver.name} - ${expense.cargo!.origin} به ${expense.cargo!.destination}',
                                  style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.edit, size: 20),
                            label: const Text('ویرایش'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ExpenseForm(expense: expense),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                            label: const Text('حذف', style: TextStyle(color: Colors.red)),
                            onPressed: () => _confirmDelete(context, expense, expensesBox),
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
      },
    );
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(amount)} تومان';
  }

  Widget _getCategoryIcon(String category) {
    IconData iconData;
    Color color;

    switch (category) {
      case 'سوخت':
        iconData = Icons.local_gas_station;
        color = Colors.red;
        break;
      case 'تعمیرات':
        iconData = Icons.build;
        color = Colors.orange;
        break;
      case 'لاستیک':
        iconData = Icons.tire_repair;
        color = Colors.black;
        break;
      case 'عوارض':
        iconData = Icons.money;
        color = Colors.green;
        break;
      case 'جریمه':
        iconData = Icons.warning;
        color = Colors.red;
        break;
      case 'غذا':
        iconData = Icons.restaurant;
        color = Colors.orange;
        break;
      case 'دستمزد':
        iconData = Icons.people;
        color = Colors.blue;
        break;
      default:
        iconData = Icons.category;
        color = Colors.grey;
        break;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.2),
      child: Icon(iconData, color: color),
    );
  }

  void _showExpenseDetails(BuildContext context, Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(expense.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (expense.imagePath != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(expense.imagePath!),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _buildDetailRow('مبلغ:', _formatAmount(expense.amount)),
              _buildDetailRow('دسته‌بندی:', expense.category),
              _buildDetailRow('تاریخ:', date_utils.AppDateUtils.toPersianDate(expense.date)),
              if (expense.description.isNotEmpty)
                _buildDetailRow('توضیحات:', expense.description),
              
              // نمایش اطلاعات سرویس بار مرتبط
              if (expense.cargo != null) ...[
                const Divider(height: 24),
                const Text(
                  'سرویس بار مرتبط:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDetailRow('راننده:', expense.cargo!.driver.name),
                _buildDetailRow('مسیر:', '${expense.cargo!.origin} به ${expense.cargo!.destination}'),
                _buildDetailRow('تاریخ سرویس:', date_utils.AppDateUtils.toPersianDate(expense.cargo!.date)),
              ],
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

  void _confirmDelete(BuildContext context, Expense expense, Box<Expense> expensesBox) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف هزینه'),
        content: const Text('آیا از حذف این هزینه اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () {
              expense.delete();
              Navigator.of(context).pop();
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
} 