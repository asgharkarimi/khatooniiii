import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:khatooniiii/models/payment.dart';
import 'package:khatooniiii/models/cargo.dart';
import 'package:khatooniiii/models/customer.dart';
import 'package:khatooniiii/utils/number_formatter.dart';
import 'package:intl/intl.dart';
import 'package:khatooniiii/utils/date_utils.dart';

class PaymentForm extends StatefulWidget {
  final Payment? payment;
  final Cargo? cargo;

  const PaymentForm({super.key, this.payment, this.cargo});

  @override
  State<PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<PaymentForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  Cargo? _selectedCargo;
  Customer? _selectedCustomer;
  int _selectedPaymentType = PaymentType.cash;
  int _selectedPayerType = PayerType.customerToDriver;
  DateTime _selectedDate = DateTime.now();
  DateTime? _checkDueDate;

  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    if (widget.payment != null) {
      _selectedCargo = widget.payment!.cargo;
      _selectedCustomer = widget.payment!.customer;
      _selectedPaymentType = widget.payment!.paymentType;
      _selectedPayerType = widget.payment!.payerType;
      _selectedDate = widget.payment!.paymentDate;
      _checkDueDate = widget.payment!.checkDueDate;
      _amountController.text = widget.payment!.amount.toString();
    } else if (widget.cargo != null) {
      _selectedCargo = widget.cargo;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isCheckDueDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isCheckDueDate ? (_checkDueDate ?? DateTime.now()) : _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    
    if (picked != null) {
      setState(() {
        if (isCheckDueDate) {
          _checkDueDate = picked;
        } else {
          _selectedDate = picked;
        }
      });
    }
  }

  Future<void> _selectPaymentDate(BuildContext context) async {
    final DateTime? picked = await AppDateUtils.showJalaliDatePicker(
      context: context,
      initialDate: _selectedDate,
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectCheckDueDate(BuildContext context) async {
    final DateTime? picked = await AppDateUtils.showJalaliDatePicker(
      context: context,
      initialDate: _checkDueDate ?? DateTime.now().add(const Duration(days: 30)),
    );
    
    if (picked != null) {
      setState(() {
        _checkDueDate = picked;
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate() && _validateDropdowns()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final paymentsBox = Hive.box<Payment>('payments');

        // تبدیل مبلغ از فرمت متنی به عدد
        final amount = parseFormattedNumber(_amountController.text);
        
        // بررسی کل پرداخت‌ها و به روزرسانی وضعیت پرداخت سرویس بار
        final existingPayments = paymentsBox.values
            .where((payment) => payment.cargo.key == _selectedCargo!.key && 
                  (widget.payment == null || payment.key != widget.payment!.key))
            .fold(0.0, (sum, item) => sum + item.amount);
        
        final newTotal = existingPayments + amount;
        final totalPrice = _selectedCargo!.totalPrice;
        
        // تعیین وضعیت پرداخت سرویس بار
        int paymentStatus = PaymentStatus.pending;
        if (newTotal >= totalPrice) {
          paymentStatus = PaymentStatus.fullyPaid;
        } else if (newTotal > 0) {
          paymentStatus = PaymentStatus.partiallyPaid;
        }
        
        _selectedCargo!.paymentStatus = paymentStatus;
        await _selectedCargo!.save();

        // Create and save the payment
        final payment = Payment(
          paymentType: _selectedPaymentType,
          payerType: _selectedPayerType,
          customer: _selectedCustomer!,
          cargo: _selectedCargo!,
          amount: amount,
          checkDueDate: _selectedPaymentType == PaymentType.check ? _checkDueDate : null,
          paymentDate: _selectedDate,
        );

        if (widget.payment != null) {
          await paymentsBox.put(widget.payment!.key, payment);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('پرداخت با موفقیت بروزرسانی شد')),
            );
          }
        } else {
          await paymentsBox.add(payment);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('پرداخت با موفقیت اضافه شد')),
            );
          }
        }

        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'خطا در ذخیره پرداخت: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  bool _validateDropdowns() {
    String errorMsg = '';
    
    if (_selectedCargo == null) {
      errorMsg = 'لطفاً یک محموله را انتخاب کنید';
    } else if (_selectedCustomer == null) {
      errorMsg = 'لطفاً یک مشتری را انتخاب کنید';
    } else if (_selectedPaymentType == PaymentType.check && _checkDueDate == null) {
      errorMsg = 'لطفاً تاریخ سررسید چک را انتخاب کنید';
    }
    
    if (errorMsg.isNotEmpty) {
      setState(() {
        _errorMessage = errorMsg;
      });
      return false;
    }
    
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.payment == null ? 'ثبت پرداخت جدید' : 'ویرایش پرداخت'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      color: Colors.red.shade100,
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                    ),
                  ),
                _buildCargoDropdown(),
                const SizedBox(height: 16),
                _buildCustomerDropdown(),
                const SizedBox(height: 16),
                _buildPaymentTypeDropdown(),
                const SizedBox(height: 16),
                _buildPayerTypeDropdown(),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => _selectPaymentDate(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'تاریخ پرداخت',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppDateUtils.toPersianDate(_selectedDate),
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          AppDateUtils.getPersianWeekDay(_selectedDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_selectedPaymentType == PaymentType.check) ...[
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _selectCheckDueDate(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'تاریخ سررسید چک',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _checkDueDate != null
                              ? AppDateUtils.toPersianDate(_checkDueDate!)
                              : 'انتخاب تاریخ',
                            style: const TextStyle(fontSize: 16),
                          ),
                          if (_checkDueDate != null)
                            Text(
                              AppDateUtils.getPersianWeekDay(_checkDueDate!),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'مبلغ (تومان)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    ThousandsFormatter(separator: '.'),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'لطفاً مبلغ را وارد کنید';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: Text(
                    widget.payment == null ? 'ثبت پرداخت' : 'ذخیره تغییرات',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCargoDropdown() {
    final box = Hive.box<Cargo>('cargos');
    final cargos = box.values.toList();

    if (cargos.isEmpty) {
      return const Text('سرویس باری یافت نشد. لطفاً ابتدا یک سرویس بار ایجاد کنید.',
          style: TextStyle(color: Colors.red));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<Cargo>(
          decoration: const InputDecoration(
            labelText: 'سرویس بار',
            border: OutlineInputBorder(),
          ),
          value: _selectedCargo,
          isExpanded: true,
          items: cargos.map((cargo) {
            final driver = cargo.driver;
            final origin = cargo.origin;
            final destination = cargo.destination;
            final dateStr = DateFormat('yyyy/MM/dd').format(cargo.date);

            return DropdownMenuItem<Cargo>(
              value: cargo,
              child: Text('${driver.name} - $origin به $destination ($dateStr)', overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCargo = value;
              
              // اگر سرویس بار انتخاب شده، مبلغ باقیمانده را پیشنهاد بده
              if (value != null) {
                _updatePaymentSuggestion();
              }
            });
          },
        ),
        if (_selectedCargo != null) 
          _buildCargoPaymentInfo(),
      ],
    );
  }

  // نمایش اطلاعات مالی سرویس بار
  Widget _buildCargoPaymentInfo() {
    final paymentsBox = Hive.box<Payment>('payments');
    final existingPayments = paymentsBox.values
        .where((payment) => payment.cargo.key == _selectedCargo!.key && 
              (widget.payment == null || payment.key != widget.payment!.key))
        .fold(0.0, (sum, item) => sum + item.amount);
    
    final totalPrice = _selectedCargo!.totalPrice;
    final remaining = totalPrice - existingPayments;
    
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Card(
        elevation: 0,
        color: Colors.blue.shade50,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('قیمت کل:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${formatNumber(totalPrice)} تومان',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('پرداخت شده:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${formatNumber(existingPayments)} تومان',
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('باقیمانده:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${formatNumber(remaining)} تومان',
                    style: TextStyle(
                      color: remaining > 0 ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (remaining <= 0)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'این سرویس بار پرداخت شده است. پرداخت بیشتر به عنوان اضافه پرداخت ثبت خواهد شد.',
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  // به روزرسانی پیشنهاد مبلغ پرداخت
  void _updatePaymentSuggestion() {
    if (_selectedCargo == null) return;
    
    final paymentsBox = Hive.box<Payment>('payments');
    final existingPayments = paymentsBox.values
        .where((payment) => payment.cargo.key == _selectedCargo!.key && 
              (widget.payment == null || payment.key != widget.payment!.key))
        .fold(0.0, (sum, item) => sum + item.amount);
    
    final totalPrice = _selectedCargo!.totalPrice;
    final remaining = totalPrice - existingPayments;
    
    // فقط اگر فرم جدید است و مقدار قبلاً تنظیم نشده، مقدار باقیمانده را پیشنهاد کن
    if (widget.payment == null && _amountController.text.isEmpty && remaining > 0) {
      _amountController.text = formatNumber(remaining).toString();
    }
  }
  
  // تبدیل عدد به فرمت خوانا
  String formatNumber(double number) {
    return NumberFormat('#,###').format(number);
  }
  
  // تبدیل متن به عدد و حذف کاراکترهای فرمت
  double parseFormattedNumber(String formattedNumber) {
    if (formattedNumber.isEmpty) return 0;
    return double.parse(formattedNumber.replaceAll(',', '').replaceAll('.', ''));
  }

  Widget _buildCustomerDropdown() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Customer>('customers').listenable(),
      builder: (context, Box<Customer> box, _) {
        final customers = box.values.toList();
        
        if (customers.isEmpty) {
          return const Card(
            color: Colors.amber,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('مشتری یافت نشد. لطفاً ابتدا یک مشتری ایجاد کنید.'),
            ),
          );
        }
        
        return DropdownButtonFormField<Customer>(
          decoration: const InputDecoration(
            labelText: 'مشتری',
            border: OutlineInputBorder(),
          ),
          value: _selectedCustomer,
          isExpanded: true,
          items: customers.map((customer) {
            return DropdownMenuItem<Customer>(
              value: customer,
              child: Text('${customer.firstName} ${customer.lastName}', overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCustomer = value;
            });
          },
        );
      },
    );
  }

  Widget _buildPaymentTypeDropdown() {
    return DropdownButtonFormField<int>(
      decoration: const InputDecoration(
        labelText: 'نوع پرداخت',
        border: OutlineInputBorder(),
      ),
      value: _selectedPaymentType,
      isExpanded: true,
      items: const [
        DropdownMenuItem<int>(
          value: PaymentType.cash,
          child: Text('نقدی'),
        ),
        DropdownMenuItem<int>(
          value: PaymentType.check,
          child: Text('چک'),
        ),
        DropdownMenuItem<int>(
          value: PaymentType.cardToCard,
          child: Text('کارت به کارت'),
        ),
        DropdownMenuItem<int>(
          value: PaymentType.bankTransfer,
          child: Text('انتقال بانکی'),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedPaymentType = value!;
        });
      },
    );
  }

  Widget _buildPayerTypeDropdown() {
    return DropdownButtonFormField<int>(
      decoration: const InputDecoration(
        labelText: 'نوع پرداخت کننده',
        border: OutlineInputBorder(),
      ),
      value: _selectedPayerType,
      isExpanded: true,
      items: const [
        DropdownMenuItem<int>(
          value: PayerType.driverToCompany,
          child: Text('راننده به شرکت'),
        ),
        DropdownMenuItem<int>(
          value: PayerType.customerToDriver,
          child: Text('مشتری به راننده'),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedPayerType = value!;
        });
      },
    );
  }
} 