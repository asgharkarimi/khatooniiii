import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:khatooniiii/models/expense.dart';
import 'package:khatooniiii/screens/expense_form.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class ExpenseList extends StatelessWidget {
  const ExpenseList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('هزینه‌ها'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ExpenseForm()),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
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
                          '${expense.category} - ${DateFormat('yyyy/MM/dd').format(expense.date)}',
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ExpenseForm()),
          );
        },
        child: const Icon(Icons.add),
      ),
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
              _buildDetailRow('تاریخ:', DateFormat('yyyy/MM/dd').format(expense.date)),
              if (expense.description.isNotEmpty)
                _buildDetailRow('توضیحات:', expense.description),
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