import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:khatooniiii/models/driver.dart';
import 'package:khatooniiii/models/driver_salary.dart';
import 'package:khatooniiii/utils/number_formatter.dart';
import 'package:khatooniiii/utils/date_utils.dart';
import 'package:khatooniiii/models/cargo.dart';
import 'package:intl/intl.dart';
import 'package:khatooniiii/screens/driver_salary_list.dart';

class DriverSalaryForm extends StatefulWidget {
  final DriverSalary? driverSalary;
  final Cargo? selectedCargo;
  
  const DriverSalaryForm({super.key, this.driverSalary, this.selectedCargo});

  @override
  State<DriverSalaryForm> createState() => _DriverSalaryFormState();
}

class _DriverSalaryFormState extends State<DriverSalaryForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _percentageController = TextEditingController();
  
  int _selectedPaymentMethod = PaymentMethod.cash;
  DateTime _selectedDate = DateTime.now();
  Cargo? _selectedCargo;
  Driver? _selectedDriver;
  
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    if (widget.driverSalary != null) {
      _amountController.text = widget.driverSalary!.amount.toString();
      _selectedPaymentMethod = widget.driverSalary!.paymentMethod;
      _selectedDate = widget.driverSalary!.paymentDate;
      _descriptionController.text = widget.driverSalary!.description ?? '';
      _percentageController.text = widget.driverSalary!.percentage?.toString() ?? '';
      _selectedDriver = widget.driverSalary!.driver;
    }
    if (widget.selectedCargo != null) {
      _selectedCargo = widget.selectedCargo;
      _selectedDriver = widget.selectedCargo!.driver;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _percentageController.dispose();
    super.dispose();
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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _validateDropdowns()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final driverSalariesBox = await Hive.openBox<DriverSalary>('driverSalaries');
        
        // Convert amount from text format to number
        final amount = parseFormattedNumber(_amountController.text);
        
        final percentage = double.tryParse(_percentageController.text) ?? 0;

        // Calculate driver's share
        double totalSalary = _calculateDriverSalary();

        // Create and save driver salary
        final driverSalary = DriverSalary(
          driver: _selectedDriver!,
          amount: amount,
          paymentMethod: _selectedPaymentMethod,
          paymentDate: _selectedDate,
          description: _descriptionController.text.isNotEmpty ? 
            _descriptionController.text : null,
          percentage: percentage,
          cargo: _selectedCargo,
        );

        if (widget.driverSalary != null) {
          await driverSalariesBox.put(widget.driverSalary!.key, driverSalary);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('حقوق راننده با موفقیت بروزرسانی شد')),
            );
            Navigator.pop(context);
          }
        } else {
          await driverSalariesBox.add(driverSalary);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('حقوق راننده با موفقیت ثبت شد')),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const DriverSalaryList(),
              ),
            );
          }
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'خطا در ثبت حقوق راننده: ${e.toString()}';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _validateDropdowns() {
    if (_selectedDriver == null) {
      setState(() {
        _errorMessage = 'لطفاً راننده را انتخاب کنید';
      });
      return false;
    }
    return true;
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _amountController.text = '';
      _selectedPaymentMethod = PaymentMethod.cash;
      _selectedDate = DateTime.now();
      _descriptionController.text = '';
      _percentageController.text = '';
      _errorMessage = '';
    });
  }

  double _calculateDriverSalary() {
    if (_selectedCargo == null) return 0;

    // Calculate total transport cost
    double totalTransportCost = (_selectedCargo!.weight ?? 0) > 0 ? 
      ((_selectedCargo!.weight ?? 0) / 1000) * (_selectedCargo!.transportCostPerTon ?? 0) : 
      (_selectedCargo!.transportCostPerTon ?? 0);
    
    // Subtract waybill amount
    double netAmount = totalTransportCost - (_selectedCargo!.waybillAmount ?? 0);
    
    // Calculate driver's share
    double percentage = double.tryParse(_percentageController.text) ?? 0;
    return netAmount * (percentage / 100);
  }

  double _calculatePreviousPayments() {
    if (_selectedDriver == null) return 0;

    final driverSalariesBox = Hive.box<DriverSalary>('driverSalaries');
    final previousPayments = driverSalariesBox.values
        .where((salary) => salary.driver.key == _selectedDriver!.key)
        .fold(0.0, (sum, salary) => sum + salary.amount);

    return previousPayments;
  }

  void _updateSalaryCalculation() {
    setState(() {
      // This will trigger a rebuild and recalculate the salary
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.driverSalary != null ? 'ویرایش حقوق راننده' : 'ثبت حقوق راننده'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Driver selection
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'راننده',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    TextFormField(
                      readOnly: true, // Make the field read-only
                      initialValue: _selectedDriver?.name ?? 'راننده انتخاب نشده',
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Percentage field
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'درصد حقوق راننده',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    TextFormField(
                      controller: _percentageController,
                      keyboardType: TextInputType.number,
                      readOnly: false,
                      decoration: InputDecoration(
                        hintText: 'مثال: 30 برای 30 درصد',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.percent),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'لطفاً درصد حقوق راننده را وارد کنید';
                        }
                        if (double.tryParse(value) == null) {
                          return 'درصد حقوق راننده باید عدد باشد';
                        }
                        return null;
                      },
                      onChanged: (_) {
                        _updateSalaryCalculation();
                      },
                    ),
                    const SizedBox(height: 16),

                    // Amount field
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'مبلغ حقوق',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        ThousandsFormatter(),
                      ],
                      decoration: InputDecoration(
                        hintText: 'مبلغ حقوق را وارد کنید',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.monetization_on),
                        suffixText: 'تومان',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'لطفاً مبلغ حقوق را وارد کنید';
                        }
                        if (parseFormattedNumber(value) == 0) {
                          return 'مبلغ حقوق نمی‌تواند صفر باشد';
                        }
                        return null;
                      },
                      onChanged: (_) {
                        _updateSalaryCalculation();
                      },
                    ),
                    const SizedBox(height: 16),

                    // Payment method dropdown
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'روش پرداخت',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    DropdownButtonFormField<int>(
                      value: _selectedPaymentMethod,
                      items: [
                        DropdownMenuItem(
                          value: PaymentMethod.cash,
                          child: Text('نقدی'),
                        ),
                        DropdownMenuItem(
                          value: PaymentMethod.bankTransfer,
                          child: Text('کارت'),
                        ),
                        DropdownMenuItem(
                          value: PaymentMethod.check,
                          child: Text('چک'),
                        ),
                      ],
                      onChanged: (int? paymentMethod) {
                        setState(() {
                          _selectedPaymentMethod = paymentMethod!;
                        });
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.payment),
                      ),
                      validator: (value) {
                        if (value == null) {
                          return 'لطفاً روش پرداخت را انتخاب کنید';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Payment date picker
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'تاریخ پرداخت',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectPaymentDate(context),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(Icons.calendar_today),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text(AppDateUtils.formatJalaliDate(_selectedDate)),
                                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Description field
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'توضیحات (اختیاری)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'توضیحات مربوط به حقوق را وارد کنید',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.description),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Calculated Salary Display
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'محاسبه حقوق',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const Divider(height: 20, thickness: 1),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('حقوق قابل پرداخت:'),
                              Text(
                                formatNumber(_calculateDriverSalary()),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('پرداخت‌های قبلی:'),
                              Text(
                                formatNumber(_calculatePreviousPayments()),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('باقی‌مانده:'),
                              Text(
                                formatNumber(_calculateDriverSalary() - _calculatePreviousPayments()), // Corrected calculation
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),


                    // Submit and Reset buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white),
                                )
                              : const Text('ذخیره'),
                        ),
                        TextButton(
                          onPressed: _resetForm,
                          child: const Text('بازنشانی'),
                        ),
                      ],
                    ),

                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<DropdownMenuItem<Driver>> _getDriverItems() {
    final driverBox = Hive.box<Driver>('drivers');
    return driverBox.values.map((driver) {
      return DropdownMenuItem<Driver>(
        value: driver,
        child: Text(driver.name),
      );
    }).toList();
  }
}