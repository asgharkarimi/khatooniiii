import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:khatooniiii/models/driver.dart';
import 'package:khatooniiii/models/driver_salary.dart';
import 'package:khatooniiii/utils/number_formatter.dart';
import 'package:khatooniiii/utils/date_utils.dart' as date_utils;
import 'package:khatooniiii/models/cargo.dart';
import 'package:khatooniiii/utils/driver_salary_calculator.dart';
import 'package:intl/intl.dart';
import 'package:khatooniiii/models/driver_payment.dart';
import 'package:khatooniiii/utils/app_date_utils.dart';
import 'package:khatooniiii/widgets/persian_date_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:khatooniiii/widgets/account_number_selector.dart';
import 'package:khatooniiii/widgets/account_section.dart';

class DriverSalaryManagement extends StatefulWidget {
  final DriverSalary? driverSalary;
  final Cargo? selectedCargo;
  final Driver? selectedDriver;
  
  const DriverSalaryManagement({
    super.key, 
    this.driverSalary, 
    this.selectedCargo,
    this.selectedDriver,
  });

  @override
  State<DriverSalaryManagement> createState() => _DriverSalaryManagementState();
}

class _DriverSalaryManagementState extends State<DriverSalaryManagement> with SingleTickerProviderStateMixin {
  // Tab controller
  late TabController _tabController;
  
  // Form fields
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _percentageController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  
  int _selectedPaymentMethod = PaymentMethod.cash;
  DateTime _selectedDate = DateTime.now();
  Cargo? _selectedCargo;
  Driver? _selectedDriver;
  
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isPercentageCalculated = false;
  double _calculatedSalary = 0;
  
  // List view fields
  late Box<DriverSalary> _driverSalariesBox;
  double _totalPaid = 0;
  bool _isLoadingList = true;
  String _cargoIdFilter = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Initialize form data
    if (widget.driverSalary != null) {
      _selectedPaymentMethod = widget.driverSalary!.paymentMethod;
      _selectedDate = widget.driverSalary!.paymentDate;
      _descriptionController.text = widget.driverSalary!.description ?? '';
      _selectedDriver = widget.driverSalary!.driver;
      _calculatedSalary = widget.driverSalary!.calculatedSalary ?? 0;
      _isPercentageCalculated = true;
      
      // Set the remaining amount instead of the actual payment amount
      _amountController.text = formatNumber(widget.driverSalary!.remainingAmount!);
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
        
        // Calculate the remaining debt amount
        final totalPaid = _selectedCargo!.totalDriverPayments;
        final remainingDebt = _calculatedSalary - totalPaid;
        
        // Set the remaining debt as the default payment amount
        _amountController.text = formatNumber(remainingDebt);
        
        // Set cargo ID filter to the selected cargo's ID for list view
        String cargoId = _selectedCargo!.id?.toString() ?? _selectedCargo!.key.toString();
        _cargoIdFilter = cargoId;
        
        // Pre-load the list tab with this cargo's payments
        Future.delayed(Duration.zero, () {
          _loadCargoPayments(cargoId);
        });
      }
    }
    
    // Initialize list data
    _initializeBox();
  }
  
  // Load payments for a specific cargo ID
  Future<void> _loadCargoPayments(String cargoId) async {
    try {
      setState(() {
        _isLoadingList = true;
      });
      
      // Set the filter
      _cargoIdFilter = cargoId;
      
      // Print debug info
      if (kDebugMode) {
        _debugPrintFilteredPayments(cargoId: cargoId);
      }
      
      setState(() {
        _isLoadingList = false;
      });
      
      // Switch to the list tab if not already there
      if (_tabController.index != 1) {
        _tabController.animateTo(1);
      }
    } catch (e) {
      print('Error loading cargo payments: $e');
      setState(() {
        _isLoadingList = false;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _percentageController.dispose();
    _accountNumberController.dispose();
    _bankNameController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeBox() async {
    try {
      _driverSalariesBox = await Hive.openBox<DriverSalary>('driverSalaries');
      final driverPaymentsBox = await Hive.openBox<DriverPayment>('driverPayments');
      
      _debugPrintAllDriverPayments();
      
      // Filter driver payments with Cargo ID: 1
      _debugPrintFilteredPayments(cargoId: "1");
      
      print('\n========== لیست سرویس‌ها و حقوق راننده ==========');
      
      if (widget.selectedDriver != null) {
        print('\nمشخصات راننده:');
        print('شناسه راننده: ${widget.selectedDriver!.key}');
        print('نام راننده: ${widget.selectedDriver!.firstName} ${widget.selectedDriver!.lastName}');
        print('درصد حقوق: ${widget.selectedDriver!.salaryPercentage}%');
      }
      
      if (widget.selectedCargo != null) {
        print('\nاطلاعات سرویس:');
        print('شناسه سرویس: ${widget.selectedCargo!.key}');
        print('نوع سرویس: ${widget.selectedCargo!.cargoType.cargoName}');
        print('مسیر: ${widget.selectedCargo!.origin} -> ${widget.selectedCargo!.destination}');
        print('وزن: ${widget.selectedCargo!.weight} کیلوگرم');
        
        // Get payments for this cargo directly from cargo or box
        final cargoPayments = _getPaymentsForCargo(driverPaymentsBox);
            
        print('\nپرداختی‌های سرویس:');
        print('تعداد پرداختی‌ها: ${cargoPayments.length}');
        print('مجموع پرداختی‌ها: ${NumberFormat('#,###').format(widget.selectedCargo!.totalDriverPayments)} تومان');
        
        if (cargoPayments.isNotEmpty) {
          print('\nجزئیات پرداختی‌ها:');
          for (var payment in cargoPayments) {
            print('-------------------');
            print('شناسه راننده: ${payment.driverId}');
            print('مبلغ: ${NumberFormat('#,###').format(payment.amount)} تومان');
            print('تاریخ: ${date_utils.AppDateUtils.toPersianDate(payment.paymentDate)}');
            print('روش پرداخت: ${PaymentMethod.getTitle(payment.paymentMethod)}');
            if (payment.description?.isNotEmpty ?? false) {
              print('توضیحات: ${payment.description}');
            }
          }
          print('-------------------');
        } else {
          print('هیچ پرداختی برای این سرویس ثبت نشده است');
        }
      }
      
      if (mounted) {
        setState(() {
          _isLoadingList = false;
        });
      }
    } catch (e) {
      print('Error initializing box: $e');
      if (mounted) {
        setState(() {
          _isLoadingList = false;
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Check if cargo is selected
      if (_selectedCargo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لطفاً ابتدا یک سرویس انتخاب کنید')),
        );
        return;
      }
      
      setState(() {
        _isLoading = true;
      });

      try {
        final amount = parseFormattedNumber(_amountController.text);
        
        // Ensure the boxes are opened
        final driverSalariesBox = await Hive.openBox<DriverSalary>('driverSalaries');
        final driverPaymentsBox = await Hive.openBox<DriverPayment>('driverPayments');
        final cargosBox = await Hive.openBox<Cargo>('cargos');
        
        // Process bank account information if payment method is bank transfer
        String description = _descriptionController.text.trim();
        if (_selectedPaymentMethod == PaymentMethod.bankTransfer) {
          final accountNumber = _accountNumberController.text.trim();
          final bankName = _bankNameController.text.trim();
          
          if (accountNumber.isNotEmpty || bankName.isNotEmpty) {
            String bankInfo = '';
            
            if (accountNumber.isNotEmpty) {
              bankInfo += 'شماره حساب/شبا: $accountNumber';
            }
            
            if (bankName.isNotEmpty) {
              if (bankInfo.isNotEmpty) bankInfo += ' - ';
              bankInfo += 'بانک: $bankName';
            }
            
            if (description.isNotEmpty) {
              description += '\n$bankInfo';
            } else {
              description = bankInfo;
            }
          }
        }
        
        // Get cargo from the box to ensure it's the latest version
        Cargo? cargo = cargosBox.values.firstWhere(
          (c) => c.key == _selectedCargo!.key,
          orElse: () => _selectedCargo!
        );
        
        // Debug log to check cargo key
        print('\n==== CARGO DETAILS FOR PAYMENT ====');
        print('Cargo Key: ${cargo.key}');
        print('Cargo ID: ${cargo.id}');
        print('Driver Key: ${cargo.driver.key}');
        print('Driver ID: ${cargo.driver.id}');
        print('================================\n');
        
        // Calculate total paid amount for this cargo - use String key comparison
        final previousPayments = driverSalariesBox.values
            .where((salary) => salary.cargo?.key == cargo.key)
            .fold(0.0, (sum, salary) => sum + salary.amount);
        
        // Calculate remaining amount
        final maxRemainingAmount = _calculatedSalary - previousPayments;
        
        // Ensure payment amount doesn't exceed remaining debt
        double finalAmount = amount;
        bool wasAdjusted = false;
        if (amount > maxRemainingAmount) {
          wasAdjusted = true;
          finalAmount = maxRemainingAmount;
          print('Payment amount adjusted from ${formatNumber(amount)} to ${formatNumber(finalAmount)} to match remaining debt');
        }
        
        // Final remaining amount after this payment
        final remainingAmount = _calculatedSalary - (previousPayments + finalAmount);
        
        // Get cargo and driver keys as strings, with explicit conversion from any type
        final String cargoKey = cargo.key != null ? cargo.key.toString() : '';
        final String driverKey = cargo.driver.key != null ? cargo.driver.key.toString() : '';
        
        print('\n==== KEYS FOR PAYMENT ====');
        print('Cargo Key (original): ${cargo.key}');
        print('Cargo Key (converted): $cargoKey');
        print('Driver Key (original): ${cargo.driver.key}');
        print('Driver Key (converted): $driverKey');
        print('================================\n');
        
        // Make sure we have valid cargo and driver IDs
        final String safeCargoId = cargo.id != null ? 
            cargo.id.toString() : 
            (cargo.key != null ? cargo.key.toString() : "0");
            
        final String safeDriverId = cargo.driver.id != null ? 
            cargo.driver.id.toString() : 
            (cargo.driver.key != null ? cargo.driver.key.toString() : "0");
            
        // Verify IDs are not empty
        if (safeCargoId.isEmpty || safeDriverId.isEmpty) {
          throw Exception('Invalid cargo ID or driver ID. Please make sure cargo and driver have valid IDs.');
        }
        
        print('Safe CargoId: $safeCargoId');
        print('Safe DriverId: $safeDriverId');
        
        // Create the driver payment
        final driverPayment = DriverPayment(
          driver: cargo.driver,
          cargo: cargo,
          amount: finalAmount,
          paymentDate: _selectedDate ?? DateTime.now(),
          paymentMethod: _selectedPaymentMethod ?? PaymentMethod.cash,
          description: description,
          cargoId: safeCargoId,  // Use safe cargo ID 
          driverId: safeDriverId, // Use safe driver ID
          calculatedSalary: _calculatedSalary,
          totalPaidAmount: previousPayments + finalAmount,
          remainingAmount: remainingAmount,
        );

        // Debug log to check driver payment fields
        print('\n==== DRIVER PAYMENT CREATED ====');
        print('Payment ID: ${driverPayment.id}');
        print('Cargo ID field: ${driverPayment.cargoId}');
        print('Driver ID field: ${driverPayment.driverId}');
        print('Cargo Key in object: ${driverPayment.cargo.key}');
        print('Driver Key in object: ${driverPayment.driver.key}');
        print('================================\n');

        // Save the payment to the box
        await driverPaymentsBox.add(driverPayment);
        await driverPaymentsBox.flush();
        
        // Add the payment to the cargo's payment list
        cargo.addDriverPayment(driverPayment, driverPaymentsBox);

        // Create and save the driver salary record
        final driverSalary = DriverSalary(
          driver: cargo.driver,
          amount: finalAmount,
          paymentDate: _selectedDate ?? DateTime.now(),
          paymentMethod: _selectedPaymentMethod ?? PaymentMethod.cash,
          description: description,
          percentage: cargo.driver.salaryPercentage,
          cargo: cargo,
          cargoId: safeCargoId, // Use the same safe cargo ID
          calculatedSalary: _calculatedSalary,
          totalPaidAmount: previousPayments + finalAmount,
          remainingAmount: remainingAmount,
        );

        print('\n=== Storing Driver Payment ===');
        print('Driver ID: ${cargo.driver.key}');
        print('Driver Name: ${cargo.driver.firstName} ${cargo.driver.lastName}');
        print('Cargo ID: ${cargo.key}');
        print('Amount: ${NumberFormat('#,###').format(finalAmount)} toman');
        print('Payment Date: ${date_utils.AppDateUtils.toPersianDate(_selectedDate ?? DateTime.now())}');
        print('Remaining Amount: ${NumberFormat('#,###').format(remainingAmount)} toman');
        print('Total Driver Payments: ${NumberFormat('#,###').format(cargo.totalDriverPayments)} toman');
        print('============================\n');

        if (widget.driverSalary != null) {
          // Update existing salary
          widget.driverSalary!.amount = finalAmount;
          widget.driverSalary!.paymentDate = _selectedDate;
          widget.driverSalary!.paymentMethod = _selectedPaymentMethod;
          widget.driverSalary!.description = description;
          widget.driverSalary!.percentage = cargo.driver.salaryPercentage;
          widget.driverSalary!.calculatedSalary = _calculatedSalary;
          widget.driverSalary!.totalPaidAmount = previousPayments + finalAmount;
          widget.driverSalary!.cargo = cargo;
          widget.driverSalary!.remainingAmount = remainingAmount;
          await widget.driverSalary!.save();
        } else {
          // Add new salary
          await driverSalariesBox.add(driverSalary);
        }

        // Ensure the data is written to disk
        await driverSalariesBox.flush();
        
        // Update cargo status based on payment
        final totalDriverPayments = previousPayments + finalAmount;
        
        // Check if this payment completes or exceeds the required amount
        if (remainingAmount <= 0) {
          // Driver is fully paid
          cargo.paymentStatus = PaymentStatus.fullyPaid;
          
          // Add completion message to description if not already present
          final completionMessage = 'تسویه حساب کامل با راننده';
          if (_descriptionController.text.isEmpty) {
            driverSalary.description = completionMessage;
            if (widget.driverSalary != null) {
              widget.driverSalary!.description = completionMessage;
              await widget.driverSalary!.save();
            }
          }
          
          await cargo.save();
          
          // Show success message for full payment
          if (mounted) {
            String successMessage = 'پرداخت با موفقیت ثبت شد. حساب راننده تسویه شد.';
            if (wasAdjusted) {
              successMessage = 'مبلغ پرداختی به ${formatNumber(finalAmount)} تومان تنظیم شد. حساب راننده تسویه شد.';
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(successMessage),
                backgroundColor: Colors.green,
              ),
            );
          }
        } 
        else if (cargo.paymentStatus == PaymentStatus.pending) {
          // Update to partially paid if at least one payment is made
          cargo.paymentStatus = PaymentStatus.partiallyPaid;
          await cargo.save();
          
          // Show regular success message
          if (mounted) {
            String successMessage = 'پرداخت با موفقیت ثبت شد';
            if (wasAdjusted) {
              successMessage = 'مبلغ پرداختی به ${formatNumber(finalAmount)} تومان تنظیم شد و با موفقیت ثبت شد';
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(successMessage)),
            );
          }
        }
        else {
          // Just show regular success message
          if (mounted) {
            String successMessage = 'پرداخت با موفقیت ثبت شد';
            if (wasAdjusted) {
              successMessage = 'مبلغ پرداختی به ${formatNumber(finalAmount)} تومان تنظیم شد و با موفقیت ثبت شد';
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(successMessage)),
            );
          }
        }

        if (mounted) {
          // Switch to the list tab after successful form submission
          _tabController.animateTo(1); 
          
          // Refresh the list data
          setState(() {
            _isLoadingList = true;
            _selectedCargo = cargo; // Update with the latest cargo
            
            // Set cargo ID filter to the cargo ID that was just paid
            String cargoId = cargo.id?.toString() ?? cargo.key.toString();
            _cargoIdFilter = cargoId;
          });
          await _initializeBox();
        }
      } catch (e) {
        print('Error submitting form: $e');
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
        
        // Get the remaining debt amount
        final previousPayments = _calculatePreviousPayments();
        final remainingDebt = _calculatedSalary - previousPayments;
        
        // Set the remaining debt as the default amount
        _amountController.text = formatNumber(remainingDebt);
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
    
    // Use the direct connection between cargo and payments
    return _selectedCargo!.totalDriverPayments;
  }

  // Add this method to get all payments for the current cargo
  List<DriverPayment> _getPaymentsForCargo(Box<DriverPayment> box) {
    if (_selectedCargo == null) return [];
    
    print('\n==== Getting payments for cargo ====');
    print('Selected cargo key: ${_selectedCargo!.key}');
    print('Selected cargo id: ${_selectedCargo!.id}');
    print('Selected cargo type: ${_selectedCargo!.cargoType.cargoName}');
    
    // Try multiple ID variants for matching
    final String cargoKey = _selectedCargo!.key != null ? _selectedCargo!.key.toString() : '';
    final String cargoId = _selectedCargo!.id != null ? _selectedCargo!.id.toString() : '';
    
    print('Cargo key converted to string: $cargoKey');
    print('Cargo id converted to string: $cargoId');
    
    // First try to get payments from the cargo's driverPayments list
    if (_selectedCargo!.driverPayments != null && _selectedCargo!.driverPayments!.isNotEmpty) {
      print('Found ${_selectedCargo!.driverPayments!.length} payments in cargo.driverPayments list');
      return _selectedCargo!.driverPayments!.toList();
    }
    
    // Fallback to searching in the box
    print('No payments in cargo.driverPayments list, searching in box by cargoId');
    final payments = box.values
        .where((payment) {
          // Check all possible ID forms for matching
          String paymentCargoId = payment.cargoId != null ? payment.cargoId.toString() : '';
          
          print('Checking payment - cargoId: $paymentCargoId, cargo.key: $cargoKey, cargo.id: $cargoId');
          
          // Try to match against cargo key or cargo id
          bool matchesKey = paymentCargoId == cargoKey && cargoKey.isNotEmpty;
          bool matchesId = paymentCargoId == cargoId && cargoId.isNotEmpty;
          
          // Also check direct cargo reference (object equality)
          bool matchesObject = false;
          if (_selectedCargo != null) {
            // Try to match by key if both are present
            if (payment.cargo.key != null && _selectedCargo!.key != null) {
              matchesObject = payment.cargo.key == _selectedCargo!.key;
            }
            
            // Try to match by id if both are present
            if (!matchesObject && payment.cargo.id != null && _selectedCargo!.id != null) {
              matchesObject = payment.cargo.id == _selectedCargo!.id;
            }
          }
          
          bool matches = matchesKey || matchesId || matchesObject;
          print('Match result: $matches (key: $matchesKey, id: $matchesId, obj: $matchesObject)');
          
          return matches;
        })
        .toList();
    
    print('Found ${payments.length} payments in box for cargo: $cargoKey');
    
    // If we found payments, try to link them to the cargo
    if (payments.isNotEmpty && _selectedCargo!.driverPayments == null) {
      try {
        print('Attempting to link found payments to cargo');
        _selectedCargo!.driverPayments = HiveList<DriverPayment>(box);
        for (final payment in payments) {
          _selectedCargo!.driverPayments!.add(payment);
        }
        _selectedCargo!.save();
        print('Successfully linked payments to cargo');
      } catch (e) {
        print('Error linking payments to cargo: $e');
      }
    }
    
    return payments;
  }

  void _updateSalaryCalculation() {
    setState(() {
      // This will trigger a rebuild and recalculate the salary
    });
  }

  // Main build method with tabbed interface
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.selectedCargo != null ? 'مدیریت حقوق سرویس' : 'مدیریت حقوق راننده',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withBlue(255),
              ],
            ),
          ),
        ),
        elevation: 0,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.add_circle_outline),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'ثبت حقوق',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Tab(
              icon: Icon(Icons.list_alt_rounded),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'لیست پرداختی‌ها',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Form Tab
          _buildFormTab(),
          
          // List Tab
          _isLoadingList 
              ? const Center(child: CircularProgressIndicator())
              : _buildListTab(),
        ],
      ),
    );
  }

  // Form tab builder
  Widget _buildFormTab() {
    // Calculate the remaining amount first
    double remainingAmount = 0;
    if (_isPercentageCalculated && _selectedCargo != null && _selectedDriver != null) {
      remainingAmount = _calculatedSalary - _calculatePreviousPayments();
    }
    
    // Show payment form only if there's a remaining amount to pay
    bool isPaymentComplete = _isPercentageCalculated && remainingAmount <= 0;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.15),
            Colors.white.withOpacity(0.9),
          ],
          stops: const [0.0, 0.6],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: isPaymentComplete 
            ? _buildPaymentCompleteCard()
            : Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 4,
                shadowColor: Colors.black26,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cargo selection (only show when accessed directly from home screen)
                        if (_selectedCargo == null) ...[
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12.0, top: 8.0),
                            child: Row(
                              children: [
                                Icon(Icons.local_shipping_outlined, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'انتخاب سرویس',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FutureBuilder<Box<Cargo>>(
                            future: Hive.openBox<Cargo>('cargos'),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              final cargos = snapshot.data!.values.toList();
                              
                              if (cargos.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.red[100]!),
                                  ),
                                  child: const Text(
                                    'هیچ سرویسی یافت نشد. لطفاً ابتدا یک سرویس ثبت کنید.',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                );
                              }

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
                                width: MediaQuery.of(context).size.width - 64,
                                child: DropdownButtonFormField<Cargo>(
                                  hint: const Text('سرویس را انتخاب کنید'),
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    prefixIcon: Icon(
                                      Icons.local_shipping,
                                      size: 20,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
                                  items: cargos.map((cargo) {
                                    return DropdownMenuItem<Cargo>(
                                      value: cargo,
                                      child: SizedBox(
                                        width: MediaQuery.of(context).size.width * 0.65,
                                        child: Text(
                                          '${cargo.cargoType.cargoName}: ${cargo.origin} → ${cargo.destination}',
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (Cargo? value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedCargo = value;
                                        _selectedDriver = value.driver;
                                        
                                        // Calculate salary when cargo is selected
                                        final calculator = DriverSalaryCalculator.create(
                                          driver: _selectedDriver!,
                                          cargo: _selectedCargo!,
                                        );
                                        _calculatedSalary = calculator.calculateDriverShare();
                                        _isPercentageCalculated = true;
                                        
                                        // Calculate the remaining debt amount
                                        final totalPaid = _selectedCargo!.totalDriverPayments;
                                        final remainingDebt = _calculatedSalary - totalPaid;
                                        
                                        // Set the remaining debt as the default payment amount
                                        _amountController.text = formatNumber(remainingDebt);
                                        
                                        // Set cargo ID filter to the selected cargo's ID
                                        String cargoId = value.id?.toString() ?? value.key.toString();
                                        _cargoIdFilter = cargoId;
                                        
                                        // Fetch payment data for this cargo
                                        if (kDebugMode) {
                                          _debugPrintFilteredPayments(cargoId: cargoId);
                                        }
                                      });
                                      
                                      // Switch to the list tab to show filtered payments
                                      _tabController.animateTo(1);
                                    }
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'لطفاً یک سرویس انتخاب کنید';
                                    }
                                    return null;
                                  },
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Display the payment form
                        // Driver selection
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            children: [
                              Icon(Icons.person_outline, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'راننده',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                            readOnly: true, // Make the field read-only
                            initialValue: _selectedDriver?.name ?? 'راننده انتخاب نشده',
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: Icon(
                                Icons.person,
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
                        
                        // Amount field
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            children: [
                              Icon(Icons.monetization_on_outlined, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'مبلغ پرداخت',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              // Format as we type
                              TextInputFormatter.withFunction((oldValue, newValue) {
                                final plainText = newValue.text.replaceAll(RegExp('[^0-9]'), '');
                                String formatted = plainText.isEmpty ? '' : formatNumber(double.parse(plainText));
                                return TextEditingValue(
                                  text: formatted,
                                  selection: TextSelection.collapsed(offset: formatted.length),
                                );
                              }),
                            ],
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'مبلغ به تومان',
                              suffixText: 'تومان',
                              prefixIcon: Icon(
                                Icons.monetization_on,
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
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'لطفاً مبلغ را وارد کنید';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Payment method
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            children: [
                              Icon(Icons.payment_outlined, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'روش پرداخت',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            children: [
                              RadioListTile<int>(
                                title: Row(
                                  children: [
                                    Icon(Icons.money, color: Theme.of(context).colorScheme.primary, size: 20),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'نقدی',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                value: PaymentMethod.cash,
                                groupValue: _selectedPaymentMethod,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedPaymentMethod = value!;
                                  });
                                },
                                activeColor: Theme.of(context).colorScheme.primary,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              const Divider(height: 1),
                              RadioListTile<int>(
                                title: Row(
                                  children: [
                                    Icon(Icons.credit_card, color: Theme.of(context).colorScheme.primary, size: 20),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'کارت به کارت',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                value: PaymentMethod.bankTransfer,
                                groupValue: _selectedPaymentMethod,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedPaymentMethod = value!;
                                  });
                                },
                                activeColor: Theme.of(context).colorScheme.primary,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              const Divider(height: 1),
                              RadioListTile<int>(
                                title: Row(
                                  children: [
                                    Icon(Icons.note, color: Theme.of(context).colorScheme.primary, size: 20),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'چک',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                value: PaymentMethod.check,
                                groupValue: _selectedPaymentMethod,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedPaymentMethod = value!;
                                  });
                                },
                                activeColor: Theme.of(context).colorScheme.primary,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Bank Information (only show for bank transfer)
                        if (_selectedPaymentMethod == PaymentMethod.bankTransfer) ...[
                          BankInformationSection(
                            selectedDriver: _selectedDriver,
                            accountNumberController: _accountNumberController,
                            bankNameController: _bankNameController,
                          ),
                        ],
                        
                        // Payment date
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_outlined, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'تاریخ پرداخت',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            final pickedDate = await showDialog<DateTime>(
                              context: context,
                              builder: (context) => Dialog(
                                child: PersianDatePicker(
                                  selectedDate: _selectedDate,
                                  onDateChanged: (newDate) {},
                                ),
                              ),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                _selectedDate = pickedDate;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  date_utils.AppDateUtils.toPersianDate(_selectedDate),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Description
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            children: [
                              Icon(Icons.description_outlined, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'توضیحات (اختیاری)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                            controller: _descriptionController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'توضیحات اضافی در مورد این پرداخت...',
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(bottom: 64),
                                child: Icon(
                                  Icons.description,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
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
                        const SizedBox(height: 32),
                        
                        // Submit button
                        if (_isPercentageCalculated) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade100),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildCalculationRow('حقوق محاسبه شده', _calculatedSalary, isTotal: true),
                                const SizedBox(height: 8),
                                _buildCalculationRow('پرداخت‌های قبلی', _calculatePreviousPayments()),
                                const SizedBox(height: 8),
                                _buildCalculationRow(
                                  'مانده قابل پرداخت', 
                                  _calculatedSalary - _calculatePreviousPayments(),
                                  isTotal: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.save),
                                      SizedBox(width: 8),
                                      Text(
                                        'ثبت پرداخت',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        
                        if (_errorMessage.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage,
                                    style: TextStyle(color: Colors.red.shade700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
        ),
      ),
    );
  }
  
  // Widget to show when payment is complete
  Widget _buildPaymentCompleteCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 4,
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'پرداخت تکمیل شده',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'حقوق راننده برای این سرویس به طور کامل پرداخت شده است',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.monetization_on, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  'مجموع پرداختی: ${formatNumber(_calculatedSalary)} تومان',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  'راننده: ${_selectedDriver?.name ?? ""}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                _tabController.animateTo(1); // Switch to list tab
              },
              icon: const Icon(Icons.list_alt),
              label: const Text('مشاهده لیست پرداخت‌ها'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Debug function to print all driver payments data
  void _debugPrintAllDriverPayments() async {
    try {
      print('\n==== DEBUG: ALL DRIVER PAYMENTS ====');
      
      // Get all driver payments first
      final driverPaymentsBox = await Hive.openBox<DriverPayment>('driverPayments');
      final driverPayments = driverPaymentsBox.values.toList();
      
      print('\n--- DRIVER PAYMENTS DATA ---');
      print('Total Driver Payments Records: ${driverPayments.length}');
      
      // Sort by date (newest first)
      driverPayments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
      
      for (var i = 0; i < driverPayments.length; i++) {
        final payment = driverPayments[i];
        print('\nPayment #${i+1}:');
        print('  ID: ${payment.id}');
        print('  Driver ID: ${payment.driverId}');
        print('  Cargo ID: ${payment.cargoId}');
        
        try {
          print('  Driver: ${payment.driver.firstName} ${payment.driver.lastName} (Key: ${payment.driver.key})');
                } catch (e) {
          print('  Driver: Error accessing driver data - $e');
        }
        
        print('  Amount: ${NumberFormat('#,###').format(payment.amount)} تومان');
        print('  Payment Date: ${date_utils.AppDateUtils.toPersianDate(payment.paymentDate)}');
        print('  Payment Method: ${PaymentMethod.getTitle(payment.paymentMethod)}');
        
        if (payment.description != null && payment.description!.isNotEmpty) {
          print('  Description: ${payment.description}');
        }
        
        // Print cargo information if available
        try {
          print('  Cargo Info:');
          print('    Cargo ID: ${payment.cargo.id ?? "Not set"}');
          print('    Cargo Key: ${payment.cargo.key}');
          print('    Cargo Type: ${payment.cargo.cargoType.cargoName}');
          print('    Route: ${payment.cargo.origin} -> ${payment.cargo.destination}');
          print('    Cargo Price: ${NumberFormat('#,###').format(payment.cargo.totalPrice)} تومان');
                } catch (e) {
          print('  Error accessing cargo data: $e');
        }
        
        // Print financial calculations
        try {
          print('  Calculated Total Salary: ${payment.calculatedSalary != null ? NumberFormat('#,###').format(payment.calculatedSalary) : "Not set"} تومان');
          print('  Total Paid: ${payment.totalPaidAmount != null ? NumberFormat('#,###').format(payment.totalPaidAmount) : "Not set"} تومان');
          print('  Remaining: ${payment.remainingAmount != null ? NumberFormat('#,###').format(payment.remainingAmount) : "Not set"} تومان');
        } catch (e) {
          print('  Error accessing payment calculations: $e');
        }
      }
      
      // Get all driver salaries
      final driverSalariesBox = await Hive.openBox<DriverSalary>('driverSalaries');
      final driverSalaries = driverSalariesBox.values.toList();
      
      print('\n--- DRIVER SALARY RECORDS ---');
      print('Total Driver Salary Records: ${driverSalaries.length}');
      
      // Sort by date (newest first)
      driverSalaries.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
      
      for (var i = 0; i < driverSalaries.length; i++) {
        final salary = driverSalaries[i];
        print('\nSalary Record #${i+1}:');
        print('  ID: ${salary.id}');
        print('  Driver: ${salary.driver.firstName} ${salary.driver.lastName} (Key: ${salary.driver.key})');
              print('  Amount: ${NumberFormat('#,###').format(salary.amount)} تومان');
        print('  Payment Date: ${date_utils.AppDateUtils.toPersianDate(salary.paymentDate)}');
        print('  Payment Method: ${_getPaymentMethodName(salary.paymentMethod)}');
        
        if (salary.description != null && salary.description!.isNotEmpty) {
          print('  Description: ${salary.description}');
        }
        
        // Print cargo information if available
        if (salary.cargo != null) {
          print('  Cargo Info:');
          print('    Cargo ID: ${salary.cargo!.id ?? "Not set"}');
          print('    Cargo Key: ${salary.cargo!.key}');
          print('    Cargo Type: ${salary.cargo!.cargoType.cargoName}');
          print('    Route: ${salary.cargo!.origin} -> ${salary.cargo!.destination}');
        } else if (salary.cargoId != null) {
          print('  Cargo ID: ${salary.cargoId} (no cargo reference)');
        } else {
          print('  Cargo: None');
        }
        
        // Print financial calculations
        print('  Calculated Total Salary: ${salary.calculatedSalary != null ? NumberFormat('#,###').format(salary.calculatedSalary!) : "Not calculated"} تومان');
        print('  Total Paid: ${salary.totalPaidAmount != null ? NumberFormat('#,###').format(salary.totalPaidAmount!) : "Not recorded"} تومان');
        print('  Remaining: ${salary.remainingAmount != null ? NumberFormat('#,###').format(salary.remainingAmount) : "Not recorded"} تومان');
      }
      
      print('\n==== END DEBUG DATA ====\n');
    } catch (e) {
      print('Error in debug print: $e');
    }
  }
  
  String _getPaymentMethodName(int method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.check:
        return 'Check';
      default:
        return 'Unknown';
    }
  }

  // Debug function to print filtered driver payments
  Future<void> _debugPrintFilteredPayments({String? cargoId, String? driverId}) async {
    try {
      print('\n==== DEBUG: FILTERED DRIVER PAYMENTS ====');
      print('Filtering criteria - Cargo ID: ${cargoId ?? "None"}, Driver ID: ${driverId ?? "None"}');
      
      // Get all driver payments
      final driverPaymentsBox = await Hive.openBox<DriverPayment>('driverPayments');
      final allPayments = driverPaymentsBox.values.toList();
      
      // Apply filters
      final filteredPayments = allPayments.where((payment) {
        bool matchesCargo = cargoId == null;
        bool matchesDriver = driverId == null;
        
        if (cargoId != null && payment.cargoId != null) {
          // Convert both to strings for comparison
          String paymentCargoId = payment.cargoId.toString().trim();
          String filterCargoId = cargoId.trim();
          
          // Log the comparison for debugging
          print('Comparing cargo IDs: "$paymentCargoId" == "$filterCargoId"');
          
          // Match if the IDs are equal (ignoring type)
          matchesCargo = paymentCargoId == filterCargoId;
          
          // Special case for "0" which is our default fallback ID
          if (paymentCargoId == "0" && !matchesCargo) {
            print('Payment has default cargo ID (0), checking cargo object directly');
            // If the payment has a default ID but an actual cargo object, check that
            // Try cargo.id first
            if (payment.cargo.id != null) {
              String cargoObjectId = payment.cargo.id.toString().trim();
              print('Comparing cargo.id: "$cargoObjectId" == "$filterCargoId"');
              matchesCargo = cargoObjectId == filterCargoId;
            }
            
            // If still no match, try cargo.key
            if (!matchesCargo && payment.cargo.key != null) {
              String cargoObjectKey = payment.cargo.key.toString().trim();
              print('Comparing cargo.key: "$cargoObjectKey" == "$filterCargoId"');
              matchesCargo = cargoObjectKey == filterCargoId;
            }
                    }
          
          // Also check against cargo.id if available
          if (!matchesCargo && payment.cargo.id != null) {
            String cargoObjectId = payment.cargo.id.toString().trim();
            print('Comparing against cargo.id: "$cargoObjectId" == "$filterCargoId"');
            matchesCargo = cargoObjectId == filterCargoId;
          }
        }
        
        if (driverId != null && payment.driverId != null) {
          // Convert both to strings for comparison
          String paymentDriverId = payment.driverId.toString().trim();
          String filterDriverId = driverId.trim();
          
          // Log the comparison for debugging
          print('Comparing driver IDs: "$paymentDriverId" == "$filterDriverId"');
          
          // Match if the IDs are equal (ignoring type)
          matchesDriver = paymentDriverId == filterDriverId;
          
          // Also check against driver.id if available
          if (!matchesDriver) {
            String driverObjectId = payment.driver.id.toString().trim();
            print('Comparing against driver.id: "$driverObjectId" == "$filterDriverId"');
            matchesDriver = driverObjectId == filterDriverId;
          }
        }
        
        return matchesCargo && matchesDriver;
      }).toList();
      
      print('Found ${filteredPayments.length} matching payments from total ${allPayments.length} payments');
      
      // Sort by date (newest first)
      filteredPayments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
      
      // Print each matching payment
      for (var i = 0; i < filteredPayments.length; i++) {
        final payment = filteredPayments[i];
        print('\nFiltered Payment #${i+1}:');
        print('  ID: ${payment.id}');
        print('  Driver ID: ${payment.driverId}');
        print('  Cargo ID: ${payment.cargoId}');
        
        try {
          print('  Driver: ${payment.driver.firstName} ${payment.driver.lastName} (Key: ${payment.driver.key})');
                } catch (e) {
          print('  Driver: Error accessing driver data - $e');
        }
        
        print('  Amount: ${NumberFormat('#,###').format(payment.amount)} تومان');
        print('  Payment Date: ${date_utils.AppDateUtils.toPersianDate(payment.paymentDate)}');
        print('  Payment Method: ${PaymentMethod.getTitle(payment.paymentMethod)}');
        
        if (payment.description != null && payment.description!.isNotEmpty) {
          print('  Description: ${payment.description}');
        }
        
        // Print cargo information if available
        try {
          print('  Cargo Info:');
          print('    Cargo ID: ${payment.cargo.id ?? "Not set"}');
          print('    Cargo Key: ${payment.cargo.key}');
          print('    Cargo Type: ${payment.cargo.cargoType.cargoName}');
          print('    Route: ${payment.cargo.origin} -> ${payment.cargo.destination}');
          print('    Cargo Price: ${NumberFormat('#,###').format(payment.cargo.totalPrice)} تومان');
                } catch (e) {
          print('  Error accessing cargo data: $e');
        }
        
        // Print financial calculations
        try {
          print('  Calculated Total Salary: ${payment.calculatedSalary != null ? NumberFormat('#,###').format(payment.calculatedSalary) : "Not set"} تومان');
          print('  Total Paid: ${payment.totalPaidAmount != null ? NumberFormat('#,###').format(payment.totalPaidAmount) : "Not set"} تومان');
          print('  Remaining: ${payment.remainingAmount != null ? NumberFormat('#,###').format(payment.remainingAmount) : "Not set"} تومان');
        } catch (e) {
          print('  Error accessing payment calculations: $e');
        }
      }
      
      if (filteredPayments.isEmpty) {
        print('\nNo payments found matching the specified criteria.');
      }
      
      print('\n==== END FILTERED PAYMENTS DEBUG DATA ====\n');
    } catch (e) {
      print('Error in debug filtered print: $e');
    }
  }
  
  // Helper for empty list view
  Widget _buildEmptyListView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.payment_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            widget.selectedCargo != null 
                ? 'هیچ پرداختی برای این سرویس ثبت نشده است'
                : 'لیست حقوق‌های راننده خالی است',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Add a method to fetch cargo based on ID
  Future<void> _fetchCargoDetailsById(String cargoId) async {
    try {
      if (cargoId.isEmpty) return;
      
      setState(() {
        _isLoading = true;
      });
      
      final cargosBox = await Hive.openBox<Cargo>('cargos');
      
      // Try to find cargo by its ID or key
      Cargo? foundCargo;
      
      // First try literal matching with key
      for (var cargo in cargosBox.values) {
        if (cargo.key.toString() == cargoId) {
          foundCargo = cargo;
          break;
        }
      }
      
      // If not found, try matching with ID field
      if (foundCargo == null) {
        for (var cargo in cargosBox.values) {
          if (cargo.id != null && cargo.id.toString() == cargoId) {
            foundCargo = cargo;
            break;
          }
        }
      }
      
      if (foundCargo != null) {
        setState(() {
          _selectedCargo = foundCargo;
          _selectedDriver = foundCargo!.driver; // Use null assertion
          
          // Calculate salary for this cargo
          if (_selectedDriver != null) {
            final calculator = DriverSalaryCalculator.create(
              driver: _selectedDriver!,
              cargo: _selectedCargo!,
            );
            _calculatedSalary = calculator.calculateDriverShare();
            _isPercentageCalculated = true;
            
            // Calculate the remaining debt amount
            final totalPaid = _selectedCargo!.totalDriverPayments;
            final remainingDebt = _calculatedSalary - totalPaid;
            
            // Set the remaining debt as the default payment amount
            _amountController.text = formatNumber(remainingDebt);
          }
          
          // Success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('اطلاعات سرویس با شناسه $cargoId بارگذاری شد'),
              backgroundColor: Colors.green,
            ),
          );
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('سرویسی با شناسه $cargoId یافت نشد'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error fetching cargo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در بارگذاری اطلاعات سرویس: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildCalculationRow(String title, double value, {bool isPercentage = false, bool isTotal = false}) {
    String displayText;
    if (isPercentage) {
      // Convert decimal to percentage and format
      displayText = '${value.toInt()}%';
    } else {
      // Format currency
      displayText = '${NumberFormat('#,###').format(value)} تومان';
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 3,
          child: Text(
            '$title:',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 15 : 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            displayText,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 15 : 14,
              color: isTotal ? Colors.green[700] : Colors.black87,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Helper method to build the salary list
  Widget _buildSalaryList() {
    return ValueListenableBuilder(
      valueListenable: _driverSalariesBox.listenable(),
      builder: (context, Box<DriverSalary> box, _) {
        final List<DriverSalary> allSalaries = box.values.toList();
        
        // Apply cargo ID filter
        List<DriverSalary> filteredSalaries = allSalaries;
        if (_cargoIdFilter.isNotEmpty) {
          filteredSalaries = allSalaries.where((salary) {
            // Check if cargoId matches the filter (as string comparison)
            bool matchesCargoId = false;
            
            // Try matching against cargoId field
            if (salary.cargoId != null) {
              matchesCargoId = salary.cargoId.toString().contains(_cargoIdFilter);
            }
            
            // Also try matching against cargo object if available
            if (!matchesCargoId && salary.cargo != null) {
              if (salary.cargo!.key != null) {
                matchesCargoId = salary.cargo!.key.toString().contains(_cargoIdFilter);
              }
              if (!matchesCargoId && salary.cargo!.id != null) {
                matchesCargoId = salary.cargo!.id.toString().contains(_cargoIdFilter);
              }
            }
            
            return matchesCargoId;
          }).toList();
        }
        
        // Sort salaries by date (newest first)
        filteredSalaries.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
        
        if (filteredSalaries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.payment_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  _cargoIdFilter.isNotEmpty
                      ? 'هیچ پرداختی با شناسه سرویس "$_cargoIdFilter" یافت نشد'
                      : (widget.selectedCargo != null 
                          ? 'هیچ پرداختی برای این سرویس ثبت نشده است'
                          : 'لیست حقوق‌های راننده خالی است'),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }
        
        // Group salaries by cargo ID for better organization
        final Map<String, List<DriverSalary>> salariesByCargoId = {};
        for (var salary in filteredSalaries) {
          // Use cargo object info if available, otherwise use string ID
          String cargoId = "نامشخص";
          if (salary.cargo != null) {
            cargoId = salary.cargo!.key.toString();
          } else if (salary.cargoId != null && salary.cargoId!.isNotEmpty) {
            cargoId = salary.cargoId!;
          }
          
          // Create entry if it doesn't exist
          if (!salariesByCargoId.containsKey(cargoId)) {
            salariesByCargoId[cargoId] = [];
          }
          
          // Add this salary to the group
          salariesByCargoId[cargoId]!.add(salary);
        }
        
        return ListView(
          padding: const EdgeInsets.all(8),
          children: [
            if (_cargoIdFilter.isEmpty)
              _buildPaymentSummary(),
              
            const SizedBox(height: 16),
            
            // List payments grouped by cargo
            for (var entry in salariesByCargoId.entries) ...[
              _buildCargoGroupHeader(entry.key, entry.value),
              ...entry.value.map((salary) => _buildSalaryItem(salary)),
              const SizedBox(height: 16),
            ],
          ],
        );
      },
    );
  }
  
  // Helper to build a cargo group header
  Widget _buildCargoGroupHeader(String cargoId, List<DriverSalary> salaries) {
    // Get cargo info from the first salary that has cargo data
    final hasCargo = salaries.any((s) => s.cargo != null);
    
    // If there's no cargo info, just show minimal header
    if (!hasCargo) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'سرویس: $cargoId',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
    }
    
    // Find first salary with cargo data
    final salary = salaries.firstWhere((s) => s.cargo != null);
    final cargo = salary.cargo!;
    
    // Calculate total paid for this cargo
    double totalPaid = salaries.fold(0.0, (total, s) => total + s.amount);
    
    // Get total service amount and calculate remaining if available
    double? totalSalary = salary.calculatedSalary;
    double? remaining;
    if (totalSalary != null) {
      remaining = totalSalary - totalPaid;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping, color: Colors.blue.shade800, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cargo.cargoType.cargoName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.route, color: Colors.grey.shade700, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${cargo.origin}    <-----    ${cargo.destination}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Row(
          //   children: [
          //     Icon(Icons.numbers, color: Colors.grey.shade700, size: 16),
          //     const SizedBox(width: 8),
          //     Text(
          //       'سرویس: ${cargo.key}',
          //       style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          //     ),
          //   ],
          // ),
          if (totalSalary != null) ...[
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'مجموع حقوق:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  '${NumberFormat('#,###').format(totalSalary)} تومان',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'پرداخت شده:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  '${NumberFormat('#,###').format(totalPaid)} تومان',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            if (remaining != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'باقیمانده:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    '${NumberFormat('#,###').format(remaining)} تومان',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: remaining > 0 ? Colors.red.shade600 : Colors.green.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  // Helper method to build a salary item
  Widget _buildSalaryItem(DriverSalary salary) {
    final locale = Localizations.localeOf(context);
    final formatter = NumberFormat('#,###', locale.languageCode);
    final dateFormatter = date_utils.AppDateUtils.toPersianDate;
    
    // محاسبه درصد پرداختی نسبت به کل حقوق
    String calculatedPercentage = '';
    if (salary.calculatedSalary != null && salary.calculatedSalary! > 0) {
      double percentage = (salary.amount / salary.calculatedSalary!) * 100;
      calculatedPercentage = '${percentage.toStringAsFixed(1)}%';
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.money, 
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${formatter.format(salary.amount.abs())} تومان',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Text(
                dateFormatter(salary.paymentDate),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // نوع بار را نمایش می‌دهیم (بدون مبدأ، مقصد و شماره سرویس)
          if (salary.cargo != null) 
            Container(
              margin: const EdgeInsets.only(bottom: 8, top: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_shipping, color: Colors.blue.shade700, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          salary.cargo!.cargoType.cargoName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.route, color: Colors.grey.shade600, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${salary.cargo!.origin}    <-----    ${salary.cargo!.destination}',
                          style: TextStyle(color: Colors.grey.shade700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Row(
                  //   children: [
                  //     Icon(Icons.numbers, color: Colors.grey.shade600, size: 16),
                  //     const SizedBox(width: 6),
                  //     Text(
                  //       'سرویس: ${salary.cargo!.key}',
                  //       style: TextStyle(color: Colors.grey.shade700),
                  //     ),
                  //   ],
                  // ),
                ],
              ),
            ),
          Wrap( // استفاده از Wrap به جای Row
            spacing: 4, // فاصله افقی بین عناصر
            runSpacing: 2, // فاصله عمودی بین خطوط
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(
                Icons.payment, 
                color: Colors.grey[600],
                size: 16,
              ),
              Text(
                PaymentMethod.getTitle(salary.paymentMethod),
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              if (salary.calculatedSalary != null && salary.calculatedSalary! > 0) ...[
                Text(
                  ' - ${((salary.amount / salary.calculatedSalary!) * 100).toStringAsFixed(1)}% از حقوق کل',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
          if (salary.description != null && salary.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              salary.description!,
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // List tab builder
  Widget _buildListTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.05),
            Colors.white,
          ],
          stops: const [0.0, 0.3],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.payments_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'لیست پرداختی‌ها',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            
            // List of salaries
            Expanded(
              child: Card(
                elevation: 4,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _buildSalaryList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper method to build payment summary
  Widget _buildPaymentSummary() {
    if (widget.selectedCargo != null) {
      // Calculate total driver salary
      final calculator = DriverSalaryCalculator.create(
        driver: widget.selectedCargo!.driver,
        cargo: widget.selectedCargo!,
      );
      final totalSalary = calculator.calculateDriverShare();
      final totalPaid = widget.selectedCargo!.totalDriverPayments;
      final remaining = totalSalary - totalPaid;
      
      // Get number of payments
      final paymentCount = widget.selectedCargo!.driverPayments?.length ?? 0;
      
      // Calculate payment progress
      final paymentProgress = totalSalary > 0 ? (totalPaid / totalSalary).clamp(0.0, 1.0) : 0.0;
      
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'حقوق کل:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${NumberFormat('#,###').format(totalSalary)} تومان',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'مجموع پرداختی‌ها:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${NumberFormat('#,###').format(totalPaid)} تومان',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.green[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'مانده حساب:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${NumberFormat('#,###').format(remaining)} تومان',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: remaining > 0 ? Colors.red[600] : Colors.green[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Payment progress indicator
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: paymentProgress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                paymentProgress >= 1.0 ? Colors.green : Colors.orange,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'پیشرفت پرداخت: ${(paymentProgress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                paymentProgress >= 1.0 ? 'تسویه شده' : 'در حال پرداخت',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: paymentProgress >= 1.0 ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'تعداد پرداختی‌ها:',
                  style: TextStyle(
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$paymentCount مورد',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      // Fallback to using value listenable for non-cargo specific view
      return ValueListenableBuilder(
        valueListenable: _driverSalariesBox.listenable(),
        builder: (context, Box<DriverSalary> box, _) {
          final salaries = box.values.where((salary) {
            if (widget.selectedCargo != null) {
              return salary.cargo?.key == widget.selectedCargo!.key;
            }
            return true;
          }).toList();

          _totalPaid = salaries.fold(0.0, (sum, salary) => sum + salary.amount);
          
          // Calculate total salary and remaining amount
          double totalSalary = 0;
          double remaining = 0;
          
          if (salaries.isNotEmpty) {
            // Get the calculated salary from the most recent record if available
            // This is an approximation since we don't have the cargo here
            final mostRecentSalary = salaries.reduce((a, b) => 
                a.paymentDate.isAfter(b.paymentDate) ? a : b);
            
            final calculatedSalary = mostRecentSalary.calculatedSalary;
            if (calculatedSalary != null && calculatedSalary > 0) {
              totalSalary = calculatedSalary;
              remaining = totalSalary - _totalPaid;
            }
          }
          
          // Calculate payment progress
          final paymentProgress = totalSalary > 0 ? (_totalPaid / totalSalary).clamp(0.0, 1.0) : 0.0;

          return Column(
            children: [
              if (totalSalary > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'حقوق محاسبه شده:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${NumberFormat('#,###').format(totalSalary)} تومان',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'مجموع پرداختی‌ها:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${NumberFormat('#,###').format(_totalPaid.abs())} تومان',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.green[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (totalSalary > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'مجموع بدهکاری:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${NumberFormat('#,###').format(remaining)} تومان',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: remaining > 0 ? Colors.red[600] : Colors.green[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Payment progress indicator
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: paymentProgress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      paymentProgress >= 1.0 ? Colors.green : Colors.orange,
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'پیشرفت پرداخت: ${(paymentProgress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      paymentProgress >= 1.0 ? 'تسویه شده' : 'در حال پرداخت',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: paymentProgress >= 1.0 ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'تعداد پرداختی‌ها:',
                      style: TextStyle(
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${salaries.length} مورد',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );
    }
  }
} 