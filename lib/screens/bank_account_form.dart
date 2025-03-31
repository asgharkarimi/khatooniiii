import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:khatooniiii/models/bank_account.dart';

class BankAccountForm extends StatefulWidget {
  final BankAccount? account;

  const BankAccountForm({super.key, this.account});

  @override
  State<BankAccountForm> createState() => _BankAccountFormState();
}

class _BankAccountFormState extends State<BankAccountForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _shebaController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  bool _isLoading = false;
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    _loadAccountData();
  }

  void _loadAccountData() {
    if (widget.account != null) {
      _titleController.text = widget.account!.title;
      _accountNumberController.text = widget.account!.accountNumber ?? '';
      _cardNumberController.text = widget.account!.cardNumber ?? '';
      _shebaController.text = widget.account!.sheba ?? '';
      _bankNameController.text = widget.account!.bankName;
      _ownerNameController.text = widget.account!.ownerName;
      _isDefault = widget.account!.isDefault;
    }
  }
  
  String? _validateCardNumber(String? value) {
    if (value == null || value.isEmpty) {
      return null; // اختیاری است
    }
    
    // حذف خط تیره‌ها و فاصله‌ها
    final cleanNumber = value.replaceAll(RegExp(r'[\s-]'), '');
    
    // چک کردن طول شماره کارت
    if (cleanNumber.length != 16) {
      return 'شماره کارت باید 16 رقم باشد';
    }
    
    // چک کردن دیجیت بودن تمام کاراکترها
    if (!RegExp(r'^[0-9]+$').hasMatch(cleanNumber)) {
      return 'شماره کارت فقط باید شامل اعداد باشد';
    }
    
    return null;
  }
  
  String? _validateSheba(String? value) {
    if (value == null || value.isEmpty) {
      return null; // اختیاری است
    }
    
    // حذف IR از ابتدا
    String cleanSheba = value.toUpperCase().trim();
    if (cleanSheba.startsWith('IR')) {
      cleanSheba = cleanSheba.substring(2);
    }
    
    // چک کردن طول شبا
    if (cleanSheba.length != 24) {
      return 'شماره شبا باید 24 رقم باشد (بدون IR)';
    }
    
    // چک کردن دیجیت بودن تمام کاراکترها
    if (!RegExp(r'^[0-9]+$').hasMatch(cleanSheba)) {
      return 'شماره شبا فقط باید شامل اعداد باشد';
    }
    
    return null;
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final box = await Hive.openBox<BankAccount>('bankAccounts');
        
        // Find max ID for new account
        int maxId = 0;
        for (final account in box.values) {
          if (account.id != null && account.id! > maxId) {
            maxId = account.id!;
          }
        }
        
        final account = BankAccount(
          id: widget.account?.id ?? maxId + 1,
          title: _titleController.text.trim(),
          accountNumber: _accountNumberController.text.trim().isEmpty ? null : _accountNumberController.text.trim(),
          cardNumber: _cardNumberController.text.trim().isEmpty ? null : _cardNumberController.text.trim().replaceAll(RegExp(r'[\s-]'), ''),
          sheba: _shebaController.text.trim().isEmpty ? null : _shebaController.text.trim().replaceAll(RegExp(r'[\s-]'), '').toUpperCase(),
          bankName: _bankNameController.text.trim(),
          ownerName: _ownerNameController.text.trim(),
          isDefault: _isDefault,
        );
        
        // اگر این حساب به عنوان پیش‌فرض انتخاب شده، سایر حساب‌ها را از حالت پیش‌فرض خارج کنیم
        if (_isDefault) {
          for (var key in box.keys) {
            final existing = box.get(key);
            if (existing != null && existing.isDefault && existing.id != account.id) {
              final updated = BankAccount(
                id: existing.id,
                title: existing.title,
                accountNumber: existing.accountNumber,
                cardNumber: existing.cardNumber,
                sheba: existing.sheba,
                bankName: existing.bankName,
                ownerName: existing.ownerName,
                isDefault: false,
              );
              await box.put(key, updated);
            }
          }
        }
        
        if (widget.account != null) {
          // Update existing account
          await widget.account!.delete();
        }
        
        await box.add(account);
        
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('اطلاعات حساب بانکی با موفقیت ثبت شد')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطا در ثبت اطلاعات: $e')),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _accountNumberController.dispose();
    _cardNumberController.dispose();
    _shebaController.dispose();
    _bankNameController.dispose();
    _ownerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.account == null ? 'ثبت حساب بانکی جدید' : 'ویرایش حساب بانکی'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // عنوان فرم
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          widget.account == null ? Icons.add_card : Icons.edit_note,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          widget.account == null ? 'افزودن حساب بانکی جدید' : 'ویرایش حساب بانکی',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // عنوان حساب
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'عنوان حساب',
                      hintText: 'مثال: حساب شخصی، کارت شرکت',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.title),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'لطفاً عنوان حساب را وارد کنید';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // نام بانک
                  TextFormField(
                    controller: _bankNameController,
                    decoration: InputDecoration(
                      labelText: 'نام بانک',
                      hintText: 'مثال: ملت، ملی، سپه',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.account_balance),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'لطفاً نام بانک را وارد کنید';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // نام صاحب حساب
                  TextFormField(
                    controller: _ownerNameController,
                    decoration: InputDecoration(
                      labelText: 'نام صاحب حساب',
                      hintText: 'نام و نام خانوادگی صاحب حساب',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'لطفاً نام صاحب حساب را وارد کنید';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // شماره کارت
                  TextFormField(
                    controller: _cardNumberController,
                    decoration: InputDecoration(
                      labelText: 'شماره کارت',
                      hintText: 'مثال: 6037-9975-9999-9999',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.credit_card),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(16),
                      // فرمت‌دهی شماره کارت: 4 رقم - 4 رقم - 4 رقم - 4 رقم
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        final text = newValue.text;
                        if (text.isEmpty) return newValue;
                        
                        String formatted = '';
                        for (int i = 0; i < text.length; i++) {
                          if (i > 0 && i % 4 == 0 && i < 16) {
                            formatted += '-';
                          }
                          formatted += text[i];
                        }
                        
                        return TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(offset: formatted.length),
                        );
                      }),
                    ],
                    validator: _validateCardNumber,
                  ),
                  const SizedBox(height: 16),
                  
                  // شماره شبا
                  TextFormField(
                    controller: _shebaController,
                    decoration: InputDecoration(
                      labelText: 'شماره شبا',
                      hintText: 'مثال: IR062174790000001234567890',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.confirmation_number),
                    ),
                    validator: _validateSheba,
                  ),
                  const SizedBox(height: 16),
                  
                  // شماره حساب
                  TextFormField(
                    controller: _accountNumberController,
                    decoration: InputDecoration(
                      labelText: 'شماره حساب',
                      hintText: 'شماره حساب (اختیاری)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.account_box),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // حساب پیش‌فرض
                  SwitchListTile(
                    title: const Text('استفاده به عنوان حساب پیش‌فرض'),
                    subtitle: const Text('این حساب به عنوان پیش‌فرض در فرم‌ها انتخاب شود'),
                    value: _isDefault,
                    onChanged: (value) {
                      setState(() {
                        _isDefault = value;
                      });
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // دکمه ثبت
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'ثبت اطلاعات',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 