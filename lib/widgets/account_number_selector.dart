import 'package:flutter/material.dart';
import 'package:khatooniiii/models/driver.dart';

class AccountNumberSelector extends StatefulWidget {
  final Driver? selectedDriver;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const AccountNumberSelector({
    super.key,
    required this.controller,
    this.selectedDriver,
    this.onChanged,
  });

  @override
  State<AccountNumberSelector> createState() => _AccountNumberSelectorState();
}

class _AccountNumberSelectorState extends State<AccountNumberSelector> {
  String? _selectedValue;

  @override
  void initState() {
    super.initState();
    // اگر راننده انتخاب شده باشد و شماره حساب داشته باشد، آن را بعنوان مقدار پیش‌فرض انتخاب کن
    if (widget.selectedDriver?.bankAccountNumber != null && 
        widget.selectedDriver!.bankAccountNumber!.isNotEmpty && 
        widget.controller.text.isEmpty) {
      _selectedValue = widget.selectedDriver!.bankAccountNumber;
      widget.controller.text = _selectedValue!;
    } else if (widget.controller.text.isNotEmpty) {
      // اگر مقدار از قبل در کنترلر بوده، آن را حفظ کن
      _selectedValue = widget.controller.text;
    } else {
      _selectedValue = 'manual';
    }
  }

  @override
  void didUpdateWidget(AccountNumberSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // اگر راننده تغییر کرده باشد، به‌روزرسانی مقدار انتخاب شده
    if (widget.selectedDriver != oldWidget.selectedDriver && 
        widget.selectedDriver?.bankAccountNumber != null && 
        widget.selectedDriver!.bankAccountNumber!.isNotEmpty) {
      setState(() {
        _selectedValue = widget.selectedDriver!.bankAccountNumber;
        widget.controller.text = _selectedValue!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDriverAccount = widget.selectedDriver?.bankAccountNumber != null && 
                           widget.selectedDriver!.bankAccountNumber!.isNotEmpty;

    return Container(
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
      child: DropdownButtonFormField<String>(
        value: _selectedValue,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          hintText: 'شماره حساب یا شبای اعلامی راننده',
          prefixIcon: Icon(
            Icons.credit_card,
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
        isExpanded: true,
        icon: Icon(Icons.arrow_drop_down_circle, color: Theme.of(context).colorScheme.primary),
        items: [
          if (hasDriverAccount)
            DropdownMenuItem<String>(
              value: widget.selectedDriver!.bankAccountNumber,
              child: Row(
                children: [
                  Icon(Icons.account_balance_wallet, size: 16, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'شماره حساب راننده: ${widget.selectedDriver!.bankAccountNumber}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          DropdownMenuItem<String>(
            value: 'manual',
            child: Row(
              children: [
                Icon(Icons.edit, size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text('وارد کردن شماره حساب دیگر...'),
              ],
            ),
          ),
        ],
        onChanged: (String? value) {
          setState(() {
            _selectedValue = value;
          });
          
          if (value == 'manual') {
            // نمایش دیالوگ برای ورود شماره حساب
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('وارد کردن شماره حساب'),
                content: TextField(
                  controller: widget.controller,
                  decoration: const InputDecoration(
                    hintText: 'شماره حساب یا شبا را وارد کنید',
                  ),
                  onChanged: (text) {
                    if (widget.onChanged != null) {
                      widget.onChanged!(text);
                    }
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('تایید'),
                  ),
                ],
              ),
            ).then((_) {
              // بعد از بستن دیالوگ، اگر فیلد خالی نباشد، آن را انتخاب کن
              if (widget.controller.text.isNotEmpty) {
                setState(() {
                  _selectedValue = widget.controller.text;
                });
              }
            });
          } else if (value != null) {
            widget.controller.text = value;
            if (widget.onChanged != null) {
              widget.onChanged!(value);
            }
          }
        },
      ),
    );
  }
} 