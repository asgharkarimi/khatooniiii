import 'package:flutter/material.dart';
import 'package:khatooniiii/models/driver.dart';
import 'package:khatooniiii/widgets/account_number_selector.dart';

class BankInformationSection extends StatelessWidget {
  final Driver? selectedDriver;
  final TextEditingController accountNumberController;
  final TextEditingController bankNameController;

  const BankInformationSection({
    super.key,
    required this.selectedDriver,
    required this.accountNumberController,
    required this.bankNameController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12.0),
          child: Row(
            children: [
              Icon(Icons.account_balance_outlined, size: 20),
              SizedBox(width: 8),
              Text(
                'اطلاعات بانکی',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        // شماره حساب با استفاده از ویجت جدید
        AccountNumberSelector(
          selectedDriver: selectedDriver,
          controller: accountNumberController,
        ),
        const SizedBox(height: 16),
        // نام بانک
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextFormField(
            controller: bankNameController,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              hintText: 'نام بانک',
              prefixIcon: Icon(
                Icons.account_balance,
                color: Theme.of(context).colorScheme.primary,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
} 