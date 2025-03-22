import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:khatooniiii/models/payment.dart';
import 'package:khatooniiii/models/cargo.dart';
import 'package:khatooniiii/models/customer.dart';
import 'package:intl/intl.dart';

class PaymentForm extends StatefulWidget {
  final Payment? payment;

  const PaymentForm({super.key, this.payment});

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

  void _submitForm() async {
    if (_formKey.currentState!.validate() && _validateDropdowns()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final paymentsBox = Hive.box<Payment>('payments');

        // Check if the payment amount is valid
        final amount = double.parse(_amountController.text);
        
        // Update cargo payment status if needed
        final totalPrice = _selectedCargo!.totalPrice;
        final existingPayments = paymentsBox.values
            .where((payment) => payment.cargo.id == _selectedCargo!.id && 
                  (widget.payment == null || payment.key != widget.payment!.key))
            .fold(0.0, (sum, item) => sum + item.amount);
        
        final newTotal = existingPayments + amount;
        
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
                GestureDetector(
                  onTap: () => _selectDate(context, false),
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'تاریخ پرداخت',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      controller: TextEditingController(
                        text: DateFormat('yyyy/MM/dd').format(_selectedDate),
                      ),
                    ),
                  ),
                ),
                if (_selectedPaymentType == PaymentType.check) ...[
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => _selectDate(context, true),
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'تاریخ سررسید چک',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        controller: TextEditingController(
                          text: _checkDueDate == null
                              ? ''
                              : DateFormat('yyyy/MM/dd').format(_checkDueDate!),
                        ),
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'لطفاً مبلغ را وارد کنید';
                    }
                    if (double.tryParse(value) == null) {
                      return 'لطفاً یک عدد معتبر وارد کنید';
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
      return const Text('محموله ای یافت نشد. لطفاً ابتدا یک محموله ایجاد کنید.',
          style: TextStyle(color: Colors.red));
    }

    return DropdownButtonFormField<Cargo>(
      decoration: const InputDecoration(
        labelText: 'محموله',
        border: OutlineInputBorder(),
      ),
      value: _selectedCargo,
      items: cargos.map((cargo) {
        final driver = cargo.driver;
        final origin = cargo.origin;
        final destination = cargo.destination;
        final dateStr = DateFormat('yyyy/MM/dd').format(cargo.date);

        return DropdownMenuItem<Cargo>(
          value: cargo,
          child: Text('${driver.name} - $origin به $destination ($dateStr)'),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCargo = value;
        });
      },
    );
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
          items: customers.map((customer) {
            return DropdownMenuItem<Customer>(
              value: customer,
              child: Text('${customer.firstName} ${customer.lastName}'),
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