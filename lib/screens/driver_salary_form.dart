import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:khatooniiii/models/driver.dart';
import 'package:khatooniiii/models/driver_salary.dart';
import 'package:khatooniiii/utils/number_formatter.dart';
import 'package:khatooniiii/utils/date_utils.dart';
import 'package:khatooniiii/models/cargo.dart';
import 'package:khatooniiii/utils/driver_salary_calculator.dart';
import 'package:intl/intl.dart';
import 'package:khatooniiii/screens/driver_salary_list.dart';
import 'package:khatooniiii/models/driver_payment.dart';

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
  bool _isPercentageCalculated = false;
  double _calculatedSalary = 0;

  @override
  void initState() {
    super.initState();
    if (widget.driverSalary != null) {
      _amountController.text = widget.driverSalary!.amount.toString();
      _selectedPaymentMethod = widget.driverSalary!.paymentMethod;
      _selectedDate = widget.driverSalary!.paymentDate;
      _descriptionController.text = widget.driverSalary!.description ?? '';
      _selectedDriver = widget.driverSalary!.driver;
      _calculatedSalary = widget.driverSalary!.amount ?? 0;
      _isPercentageCalculated = true;
    }
    if (widget.selectedCargo != null) {
      _selectedCargo = widget.selectedCargo;
      _selectedDriver = widget.selectedCargo!.driver;
      
      // Calculate salary immediately when cargo is selected
      if (_selectedDriver != null) {
        final calculator = DriverSalaryCalculator.create(
          driver: _selectedDriver!,
          cargo: _selectedCargo!,
        );
        _calculatedSalary = calculator.calculateDriverShare();
        _isPercentageCalculated = true;
        _amountController.text = formatNumber(_calculatedSalary);
      }
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
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final amount = parseFormattedNumber(_amountController.text);
        
        // Ensure the box is opened
        final driverSalariesBox = await Hive.openBox<DriverSalary>('driverSalaries');
        
        // Calculate total paid amount for this cargo
        final previousPayments = driverSalariesBox.values
            .where((salary) => salary.cargo?.key == _selectedCargo!.key)
            .fold(0.0, (sum, salary) => sum + salary.amount);
        
        // Calculate remaining amount
        final remainingAmount = _calculatedSalary - (previousPayments + amount);
        
        // Create and save the driver payment
        final driverPayment = DriverPayment(
          driver: widget.selectedCargo!.driver,
          cargo: widget.selectedCargo!,
          amount: amount,
          paymentDate: _selectedDate ?? DateTime.now(),
          paymentMethod: _selectedPaymentMethod ?? PaymentMethod.cash,
          description: _descriptionController.text.trim(),
          cargoId: widget.selectedCargo!.key,
          driverId: widget.selectedCargo!.driver.key,  // Add driver ID
          calculatedSalary: _calculatedSalary,
          totalPaidAmount: previousPayments + amount,
          remainingAmount: remainingAmount,
        );

        // Create and save the driver salary record
        final driverSalary = DriverSalary(
          driver: widget.selectedCargo!.driver,
          amount: amount,
          paymentDate: _selectedDate ?? DateTime.now(),
          paymentMethod: _selectedPaymentMethod ?? PaymentMethod.cash,
          description: _descriptionController.text.trim(),
          percentage: widget.selectedCargo!.driver.salaryPercentage,
          cargo: widget.selectedCargo,
          cargoId: widget.selectedCargo!.key,  // Store cargo ID
          calculatedSalary: _calculatedSalary,
          totalPaidAmount: previousPayments + amount,
          remainingAmount: remainingAmount,
        );

        // Open driver payments box and save
        final driverPaymentsBox = await Hive.openBox<DriverPayment>('driverPayments');
        await driverPaymentsBox.add(driverPayment);
        await driverPaymentsBox.flush();

        print('\n=== Storing Driver Payment ===');
        print('Driver ID: ${widget.selectedCargo!.driver.key}');
        print('Driver Name: ${widget.selectedCargo!.driver.firstName} ${widget.selectedCargo!.driver.lastName}');
        print('Cargo ID: ${widget.selectedCargo!.key}');
        print('Amount: ${NumberFormat('#,###').format(amount)} toman');
        print('Payment Date: ${AppDateUtils.toPersianDate(_selectedDate ?? DateTime.now())}');
        print('Remaining Amount: ${NumberFormat('#,###').format(remainingAmount)} toman');
        print('============================\n');

        if (widget.driverSalary != null) {
          // Update existing salary
          widget.driverSalary!.amount = amount;
          widget.driverSalary!.paymentDate = _selectedDate;
          widget.driverSalary!.paymentMethod = _selectedPaymentMethod;
          widget.driverSalary!.description = _descriptionController.text;
          widget.driverSalary!.percentage = widget.selectedCargo!.driver.salaryPercentage;
          widget.driverSalary!.calculatedSalary = _calculatedSalary;
          widget.driverSalary!.totalPaidAmount = previousPayments + amount;
          widget.driverSalary!.cargo = _selectedCargo;
          await widget.driverSalary!.save();
        } else {
          // Add new salary
          await driverSalariesBox.add(driverSalary);
        }

        // Ensure the data is written to disk
        await driverSalariesBox.flush();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('پرداخت با موفقیت ثبت شد')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DriverSalaryList(
                selectedCargo: _selectedCargo,
                selectedDriver: _selectedDriver,
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطا در ثبت پرداخت: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
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
      _isPercentageCalculated = false;
      _calculatedSalary = 0;
    });
  }

  void _calculateAndSaveSalary() {
    if (_selectedCargo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً ابتدا سرویس را انتخاب کنید')),
      );
      return;
    }

    if (_selectedDriver != null) {
      setState(() {
        final calculator = DriverSalaryCalculator.create(
          driver: _selectedDriver!,
          cargo: _selectedCargo!,
        );
        
        _calculatedSalary = calculator.calculateDriverShare();
        _isPercentageCalculated = true;
        
        // Set the calculated amount as default in amount field
        _amountController.text = formatNumber(_calculatedSalary);
      });
    }
  }

  double _calculateDriverSalary() {
    if (_selectedCargo == null || _selectedDriver == null) return 0;
    
    // If salary is already calculated, return the stored value
    if (_isPercentageCalculated) {
      return _calculatedSalary;
    }

    final calculator = DriverSalaryCalculator.create(
      driver: _selectedDriver!,
      cargo: _selectedCargo!,
    );
    
    return calculator.calculateDriverShare();
  }

  double _calculatePreviousPayments() {
    if (_selectedCargo == null) return 0;
    
    return DriverSalaryCalculator.getPreviousPaymentsForCargo(_selectedCargo!);
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

                    // Show calculated amount if percentage is calculated
                    if (_isPercentageCalculated && _selectedDriver != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[100]!),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'حقوق محاسبه شده:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '${formatNumber(_calculatedSalary)} تومان',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20, thickness: 1),
                            _buildCalculationRow(
                              'درصد پرداختی حقوق',
                              _selectedDriver!.salaryPercentage,
                              isPercentage: true,
                            ),
                            const SizedBox(height: 8),
                            _buildCalculationRow(
                              'حقوق کاربر از سرویس',
                              _calculatedSalary,
                            ),
                            const SizedBox(height: 8),
                            _buildCalculationRow(
                              'پرداختی‌های قبلی',
                              _calculatePreviousPayments(),
                            ),
                            const SizedBox(height: 8),
                            _buildCalculationRow(
                              'مجموع پرداختی‌ها',
                              _calculatePreviousPayments(),
                              isTotal: true,
                            ),
                            const SizedBox(height: 8),
                            _buildCalculationRow(
                              'مجموع بدهکاری',
                              _calculatedSalary - _calculatePreviousPayments(),
                              isTotal: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Amount field
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'مبلغ پرداختی',
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
                    InkWell(
                      onTap: () => _selectPaymentDate(context),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.calendar_today,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppDateUtils.formatJalaliDate(_selectedDate),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
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
                              Icon(
                                Icons.arrow_drop_down,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
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

  Widget _buildCalculationRow(String title, double value, {bool isPercentage = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$title:',
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
          ),
        ),
        Text(
          isPercentage ? 
            '${NumberFormat('#,##0.##').format(value)}%' :
            '${NumberFormat('#,###').format(value)} تومان',
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
            color: isTotal ? Colors.green[700] : Colors.black87,
          ),
        ),
      ],
    );
  }

  bool _hasPreviousPayments() {
    if (_selectedCargo == null) return false;
    
    return Hive.box<DriverSalary>('driverSalaries')
        .values
        .any((salary) => salary.cargo?.key == _selectedCargo!.key);
  }
}