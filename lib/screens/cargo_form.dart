import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:khatooniiii/models/cargo.dart';
import 'package:khatooniiii/models/cargo_type.dart';
import 'package:khatooniiii/models/driver.dart';
import 'package:khatooniiii/models/vehicle.dart';
import 'package:khatooniiii/models/freight.dart';
import 'package:khatooniiii/models/address.dart';
import 'package:khatooniiii/models/bank_account.dart';
import 'package:khatooniiii/utils/number_formatter.dart';
import 'package:khatooniiii/utils/date_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:khatooniiii/widgets/persian_date_picker.dart';
import 'package:khatooniiii/widgets/address_selector.dart';
import 'dart:async';

class CargoForm extends StatefulWidget {
  final Cargo? cargo;
  final Freight? preSelectedFreight;

  const CargoForm({super.key, this.cargo, this.preSelectedFreight});

  @override
  State<CargoForm> createState() => _CargoFormState();
}

class _CargoFormState extends State<CargoForm> {
  final _formKey = GlobalKey<FormState>();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _weightController = TextEditingController();
  final _pricePerTonController = TextEditingController();
  final _transportCostPerTonController = TextEditingController();
  final _waybillAmountController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountOwnerNameController = TextEditingController();
  final _loadingAddressController = TextEditingController();
  final _unloadingAddressController = TextEditingController();
  final _recipientContactNumberController = TextEditingController();

  Vehicle? _selectedVehicle;
  Driver? _selectedDriver;
  CargoType? _selectedCargoType;
  Freight? _selectedFreight;
  DateTime _selectedDate = DateTime.now();
  DateTime? _selectedUnloadingDate;
  final TimeOfDay _selectedTime = TimeOfDay.now();
  
  File? _selectedWaybillImage;
  String? _savedWaybillImagePath;

  bool _isLoading = false;
  String _errorMessage = '';

  late List<Driver> _drivers;
  late List<Vehicle> _vehicles;
  late List<CargoType> _cargoTypes;
  late List<Freight> _freightCompanies;
  late List<BankAccount> _bankAccounts;
  late List<Address> _addresses;
  
  BankAccount? _selectedBankAccount;

  @override
  void initState() {
    super.initState();
    
    // Initialize lists to empty arrays first to prevent null references
    _drivers = [];
    _vehicles = [];
    _cargoTypes = [];
    _freightCompanies = [];
    _bankAccounts = [];
    _addresses = [];
    
    // Show loading indicator while initializing
    _isLoading = true;
    
    // Add debug print to track initialization
    print('DEBUG: CargoForm initState started');
    
    // Load data in multiple microtasks to avoid UI blocking
    _loadInitialData();
  }
  
  // Load data in separate async operations to prevent UI blocking
  Future<void> _loadInitialData() async {
    try {
      print('DEBUG: Starting initial data loading process');
      
      // Create a map to track loading status
      Map<String, bool> dataLoaded = {
        'drivers': false,
        'vehicles': false,
        'cargoTypes': false,
        'freights': false,
        'bankAccounts': false,
        'addresses': false,
      };
      
      // Use a single timer for overall timeout instead of multiple timers
      bool hasTimedOut = false;
      Timer? timeoutTimer = Timer(const Duration(seconds: 5), () {
        hasTimedOut = true;
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          // Log which data items didn't load
          String notLoaded = dataLoaded.entries
              .where((entry) => !entry.value)
              .map((entry) => entry.key)
              .join(', ');
              
          print('DEBUG: Initial data loading timed out. Not loaded: $notLoaded');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('بارگذاری اطلاعات با تاخیر مواجه شد. برخی از اطلاعات ممکن است در دسترس نباشند.'),
              duration: Duration(seconds: 5),
            ),
          );
        }
      });
      
      // Load critical data first with individual try-catches and parallel execution
      await Future.wait([
        // Load drivers
        Future(() async {
          try {
            _drivers = await _loadBoxValues<Driver>('drivers');
            print('DEBUG: Loaded ${_drivers.length} drivers');
            if (mounted && !hasTimedOut) {
              setState(() {
                dataLoaded['drivers'] = true;
              });
            }
          } catch (e) {
            print('ERROR loading drivers: $e');
            _drivers = [];
          }
        }),
        
        // Load vehicles 
        Future(() async {
          try {
            _vehicles = await _loadBoxValues<Vehicle>('vehicles');
            print('DEBUG: Loaded ${_vehicles.length} vehicles');
            if (mounted && !hasTimedOut) {
              setState(() {
                dataLoaded['vehicles'] = true;
              });
            }
          } catch (e) {
            print('ERROR loading vehicles: $e');
            _vehicles = [];
          }
        }),
        
        // Load cargo types
        Future(() async {
          try {
            _cargoTypes = await _loadBoxValues<CargoType>('cargoTypes');
            print('DEBUG: Loaded ${_cargoTypes.length} cargo types');
            if (mounted && !hasTimedOut) {
              setState(() {
                dataLoaded['cargoTypes'] = true;
              });
            }
          } catch (e) {
            print('ERROR loading cargo types: $e');
            _cargoTypes = [];
          }
        }),
      ]);
      
      // Update UI after critical data is loaded
      if (mounted && !hasTimedOut) {
        setState(() {
          _isLoading = false;
        });
      }
      
      // Load non-critical data in the background
      Future.wait([
        // Load freight companies
        Future(() async {
          try {
            _freightCompanies = await _loadBoxValues<Freight>('freights');
            print('DEBUG: Loaded ${_freightCompanies.length} freight companies');
            
            // Set preselected freight if available
            if (widget.preSelectedFreight != null && mounted && !hasTimedOut) {
              setState(() {
                _selectedFreight = widget.preSelectedFreight;
                print('DEBUG: Preselected freight set: ${_selectedFreight?.name}');
              });
            }
            
            if (mounted) {
              setState(() {
                dataLoaded['freights'] = true;
              });
            }
          } catch (e) {
            print('ERROR loading freight companies: $e');
            _freightCompanies = [];
          }
        }),
        
        // Load bank accounts
        Future(() async {
          try {
            final accounts = await _loadBoxValues<BankAccount>('bankAccounts');
            _bankAccounts = _removeDuplicateBankAccounts(accounts);
            print('DEBUG: Loaded ${_bankAccounts.length} bank accounts');
            
            if (mounted) {
              setState(() {
                dataLoaded['bankAccounts'] = true;
              });
            }
          } catch (e) {
            print('ERROR loading bank accounts: $e');
            _bankAccounts = [];
          }
        }),
        
        // Load addresses
        Future(() async {
          try {
            final addresses = await _loadBoxValues<Address>('addresses');
            _addresses = _removeDuplicateAddresses(addresses);
            print('DEBUG: Loaded ${_addresses.length} addresses');
            
            if (mounted) {
              setState(() {
                dataLoaded['addresses'] = true;
              });
            }
          } catch (e) {
            print('ERROR loading addresses: $e');
            _addresses = [];
          }
        }),
      ]);
      
      // Set cargo data if editing
      if (widget.cargo != null && mounted) {
        print('DEBUG: Loading existing cargo data');
        try {
          _originController.text = widget.cargo!.origin;
          _destinationController.text = widget.cargo!.destination;
          _weightController.text = widget.cargo!.weight.toString();
          _pricePerTonController.text = widget.cargo!.pricePerTon.toString();
          _transportCostPerTonController.text = widget.cargo!.transportCostPerTon.toString();
          _waybillAmountController.text = widget.cargo!.waybillAmount?.toString() ?? '0';
          _bankAccountController.text = widget.cargo!.bankAccount ?? '';
          _bankNameController.text = widget.cargo!.bankName ?? '';
          _accountOwnerNameController.text = widget.cargo!.accountOwnerName ?? '';
          _loadingAddressController.text = widget.cargo!.loadingAddress ?? '';
          _unloadingAddressController.text = widget.cargo!.unloadingAddress ?? '';
          _recipientContactNumberController.text = widget.cargo!.recipientContactNumber ?? '';
          _selectedVehicle = widget.cargo!.vehicle;
          _selectedDriver = widget.cargo!.driver;
          _selectedCargoType = widget.cargo!.cargoType;
          _selectedDate = widget.cargo!.date;
          _selectedUnloadingDate = widget.cargo!.unloadingDate;
          _savedWaybillImagePath = widget.cargo!.waybillImagePath;
        } catch (e) {
          print('ERROR loading existing cargo data: $e');
        }
        
        // This needs to run after bank accounts are loaded
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _setBankAccountFromExistingCargo();
          }
        });
      }
      
      // Print debug info after initial load
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _printDropdownsDebugInfo();
          _checkEmptyDropdowns();
        }
      });
      
      // Cancel the timeout timer if everything loaded properly
      if (!hasTimedOut && timeoutTimer != null && timeoutTimer.isActive) {
        timeoutTimer.cancel();
      }
      
      print('DEBUG: Initial data loading complete');
    } catch (e) {
      print('ERROR in _loadInitialData: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Helper method to load Hive box values with timeout protection
  Future<List<T>> _loadBoxValues<T>(String boxName) async {
    try {
      return await Future<List<T>>(() {
        final box = Hive.box<T>(boxName);
        return box.values.toList();
      }).timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          print('WARNING: Loading $boxName timed out');
          return <T>[];
        }
      );
    } catch (e) {
      print('ERROR in _loadBoxValues for $boxName: $e');
      return <T>[];
    }
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _weightController.dispose();
    _pricePerTonController.dispose();
    _transportCostPerTonController.dispose();
    _waybillAmountController.dispose();
    _bankAccountController.dispose();
    _bankNameController.dispose();
    _accountOwnerNameController.dispose();
    _loadingAddressController.dispose();
    _unloadingAddressController.dispose();
    _recipientContactNumberController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    print('DEBUG: _submitForm method called');
    
    // ابتدا بررسی کنیم آیا داده‌های لازم برای ثبت وجود دارند
    if (_drivers.isEmpty || _vehicles.isEmpty || _cargoTypes.isEmpty) {
      print('DEBUG: Required data missing for form submission');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('برای ثبت سرویس بار، باید ابتدا راننده، وسیله نقلیه و نوع سرویس بار را در سیستم ثبت کنید.'),
          duration: Duration(seconds: 5),
        ),
      );
      // بررسی کنیم و نوتیفیکیشن‌های مناسب را نمایش دهیم
      _checkEmptyDropdowns();
      return;
    }
    
    // Ensure selected values are not null
    if (_selectedDriver == null || _selectedVehicle == null || _selectedCargoType == null) {
      print('DEBUG: Required selections are missing');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لطفاً راننده، وسیله نقلیه و نوع سرویس بار را انتخاب کنید.'),
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }
    
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      // Add a timeout to prevent infinite loading
      bool isTimeoutOccurred = false;
      Future.delayed(const Duration(seconds: 10), () {
        if (_isLoading && mounted) {
          print('DEBUG: Form submission timed out');
          setState(() {
            _isLoading = false;
          });
          isTimeoutOccurred = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('عملیات با خطای زمانی مواجه شد. لطفاً دوباره تلاش کنید.'),
              duration: Duration(seconds: 5),
            ),
          );
        }
      });
      
      try {
        print('DEBUG: Processing form data');
        // Default values for numeric fields
        double pricePerTon = 0;
        double weight = 0;
        double transportCost = 0;
        double? waybillAmount;
  
        // Parse weight with proper null checking
        if (_weightController.text.isNotEmpty) {
          weight = parseFormattedNumber(_weightController.text);
        }
  
        // Parse price per ton with proper null checking
        if (_pricePerTonController.text.isNotEmpty) {
          pricePerTon = parseFormattedNumber(_pricePerTonController.text);
        }
  
        // Parse transport cost per ton with proper null checking
        if (_transportCostPerTonController.text.isNotEmpty) {
          transportCost = parseFormattedNumber(_transportCostPerTonController.text);
        }
        
        // Parse waybill amount with proper null checking
        if (_waybillAmountController.text.isNotEmpty) {
          waybillAmount = parseFormattedNumber(_waybillAmountController.text);
        }
        
        print('DEBUG: Saving waybill image if any');
        // Save waybill image if selected
        final waybillImagePath = await _saveWaybillImage();
        
        // استفاده از اطلاعات حساب بانکی انتخاب شده
        String? bankAccount = _bankAccountController.text.isNotEmpty ? _bankAccountController.text : null;
        String? bankName = _bankNameController.text.isNotEmpty ? _bankNameController.text : null;
        String? accountOwnerName = _accountOwnerNameController.text.isNotEmpty ? _accountOwnerNameController.text : null;
        
        // استفاده از آدرس‌های انتخاب شده
        String? loadingAddress = _loadingAddressController.text.isNotEmpty ? _loadingAddressController.text : null;
        String? unloadingAddress = _unloadingAddressController.text.isNotEmpty ? _unloadingAddressController.text : null;
  
        // Get next cargo ID if creating a new cargo
        int? cargoId = widget.cargo?.id;
        if (cargoId == null) {
          print('DEBUG: Creating new cargo ID');
          try {
            final cargosBox = Hive.box<Cargo>('cargos');
            // Find the highest current ID
            int maxId = 0;
            for (int i = 0; i < cargosBox.length; i++) {
              final cargo = cargosBox.getAt(i);
              if (cargo != null && cargo.id != null && cargo.id! > maxId) {
                maxId = cargo.id!;
              }
            }
            cargoId = maxId + 1;
            print('DEBUG: New cargo ID: $cargoId');
          } catch (e) {
            print('ERROR generating cargo ID: $e');
            cargoId = DateTime.now().millisecondsSinceEpoch; // Fallback to timestamp
          }
        }
  
        print('DEBUG: Creating cargo object');
        // Null safety checks before creating Cargo
        if (_selectedVehicle == null || _selectedDriver == null || _selectedCargoType == null) {
          throw Exception("Required selections (driver, vehicle, or cargo type) are missing");
        }
        
        final cargo = Cargo(
          id: cargoId,
          vehicle: _selectedVehicle!,
          driver: _selectedDriver!,
          cargoType: _selectedCargoType!,
          origin: _originController.text,
          destination: _destinationController.text,
          date: _selectedDate,
          unloadingDate: _selectedUnloadingDate,
          weight: weight,
          pricePerTon: pricePerTon,
          paymentStatus: widget.cargo?.paymentStatus ?? PaymentStatus.pending,
          transportCostPerTon: transportCost,
          waybillAmount: waybillAmount,
          waybillImagePath: waybillImagePath,
          bankAccount: bankAccount,
          bankName: bankName,
          accountOwnerName: accountOwnerName,
          loadingAddress: loadingAddress,
          unloadingAddress: unloadingAddress,
          recipientContactNumber: _recipientContactNumberController.text.isNotEmpty ? _recipientContactNumberController.text : null,
          freight: _selectedFreight,
        );
  
        print('DEBUG: Saving cargo to Hive');
        try {
          final cargosBox = Hive.box<Cargo>('cargos');
          if (widget.cargo != null) {
            // Editing existing cargo
            print('DEBUG: Updating existing cargo');
            widget.cargo!.vehicle = cargo.vehicle;
            widget.cargo!.driver = cargo.driver;
            widget.cargo!.cargoType = cargo.cargoType;
            widget.cargo!.origin = cargo.origin;
            widget.cargo!.destination = cargo.destination;
            widget.cargo!.date = cargo.date;
            widget.cargo!.unloadingDate = cargo.unloadingDate;
            widget.cargo!.weight = cargo.weight;
            widget.cargo!.pricePerTon = cargo.pricePerTon;
            widget.cargo!.transportCostPerTon = cargo.transportCostPerTon;
            
            // Handle waybillAmount with special care for existing records
            try {
              widget.cargo!.waybillAmount = cargo.waybillAmount;
            } catch (e) {
              print('ERROR updating waybill amount: $e');
              // If the field doesn't exist in old records, this might fail
              // We could recreate the cargo object with all fields or add a migration
              // For now, we'll ignore this error silently
            }
            
            widget.cargo!.waybillImagePath = cargo.waybillImagePath;
            
            // Update bank account and bank name fields
            try {
              widget.cargo!.bankAccount = cargo.bankAccount;
              widget.cargo!.bankName = cargo.bankName;
              widget.cargo!.accountOwnerName = cargo.accountOwnerName;
              widget.cargo!.loadingAddress = cargo.loadingAddress;
              widget.cargo!.unloadingAddress = cargo.unloadingAddress;
              widget.cargo!.recipientContactNumber = cargo.recipientContactNumber;
            } catch (e) {
              print('ERROR updating additional fields: $e');
              // Handle potential errors for older records
            }
            
            await widget.cargo!.save();
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('سرویس بار با موفقیت ویرایش شد')),
            );
          } else {
            // Adding new cargo
            print('DEBUG: Adding new cargo');
            await cargosBox.add(cargo);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('سرویس بار با موفقیت ثبت شد')),
            );
          }
          
          if (mounted && !isTimeoutOccurred) Navigator.pop(context);
        } catch (e) {
          print('ERROR saving cargo: $e');
          throw e; // Re-throw to be caught by outer catch block
        }
      } catch (e) {
        print('ERROR in form submission: $e');
        if (mounted && !isTimeoutOccurred) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطا: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted && !isTimeoutOccurred) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      print('DEBUG: Form validation failed');
    }
  }

  bool _validateDropdowns() {
    // اگر لیست‌ها خالی باشند، نوتیفیکیشن نمایش داده می‌شود
    if (_drivers.isEmpty || _vehicles.isEmpty || _cargoTypes.isEmpty) {
      _checkEmptyDropdowns();
      return false;
    }
    
    String errorMsg = '';
    
    if (_selectedVehicle == null) {
      errorMsg = 'لطفاً وسیله نقلیه را انتخاب کنید';
    } else if (_selectedDriver == null) {
      errorMsg = 'لطفاً راننده را انتخاب کنید';
    } else if (_selectedCargoType == null) {
      errorMsg = 'لطفاً نوع سرویس بار را انتخاب کنید';
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
    print('DEBUG: CargoForm build method called');
    
    // Return a basic scaffold immediately if there's a critical error (null values)
    if (_drivers == null || _vehicles == null || _cargoTypes == null) {
      print('DEBUG: Critical error - null collections detected');
      _drivers = [];
      _vehicles = [];
      _cargoTypes = [];
      _freightCompanies = [];
      _bankAccounts = [];
      _addresses = [];
      
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.cargo == null ? 'ثبت سرویس بار جدید' : 'ویرایش سرویس بار'),
          backgroundColor: Colors.blue[800],
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'خطا در بارگذاری اطلاعات',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('لطفاً برنامه را مجدداً راه‌اندازی کنید'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('بازگشت'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cargo == null ? 'ثبت سرویس بار جدید' : 'ویرایش سرویس بار'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show notification panel if required data is missing
                    if (_drivers.isEmpty || _vehicles.isEmpty || _cargoTypes.isEmpty)
                      Card(
                        color: Colors.amber.shade100,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.warning_amber_rounded, color: Colors.orange),
                                  SizedBox(width: 8),
                                  Text(
                                    'اطلاعات پایه ناقص است',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (_drivers.isEmpty)
                                const Text('• راننده ثبت نشده است'),
                              if (_vehicles.isEmpty)
                                const Text('• وسیله نقلیه ثبت نشده است'),
                              if (_cargoTypes.isEmpty)
                                const Text('• نوع سرویس بار ثبت نشده است'),
                              const SizedBox(height: 8),
                              const Text('لطفاً ابتدا اطلاعات پایه را ثبت کنید'),
                            ],
                          ),
                        ),
                      ),
                    
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            DropdownButtonFormField<Driver>(
                              key: UniqueKey(),
                              decoration: InputDecoration(
                                labelText: 'راننده',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              value: _drivers.isEmpty ? null : _selectedDriver,
                              items: _drivers.isEmpty
                                ? []
                                : _drivers.map((driver) {
                                    // چاپ اطلاعات بیشتر برای دیباگ
                                    print('Adding driver to dropdown: ID=${driver.id}, Name=${driver.name}, Key=${driver.key}');
                                    return DropdownMenuItem<Driver>(
                                      key: ValueKey('driver_${driver.id ?? driver.key}'),
                                      value: driver,
                                      child: Text(driver.name),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedDriver = value;
                                });
                                // چاپ اطلاعات بعد از انتخاب راننده
                                _printDropdownsDebugInfo();
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'لطفاً راننده را انتخاب کنید';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<Freight>(
                              key: UniqueKey(),
                              decoration: InputDecoration(
                                labelText: 'شرکت باربری',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              value: _freightCompanies.isEmpty ? null : _selectedFreight,
                              items: _freightCompanies.isEmpty
                                ? []
                                : _freightCompanies.map((freight) {
                                    // چاپ اطلاعات بیشتر برای دیباگ
                                    print('Adding freight to dropdown: ID=${freight.id}, Name=${freight.name}, Key=${freight.key}');
                                    return DropdownMenuItem<Freight>(
                                      key: ValueKey('freight_${freight.id ?? freight.key}'),
                                      value: freight,
                                      child: Text(freight.name),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedFreight = value;
                                });
                                // چاپ اطلاعات بعد از انتخاب باربری
                                _printDropdownsDebugInfo();
                              },
                              hint: const Text('انتخاب شرکت باربری'),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<Vehicle>(
                              key: UniqueKey(),
                              decoration: InputDecoration(
                                labelText: 'وسیله نقلیه',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              value: _vehicles.isEmpty ? null : _selectedVehicle,
                              items: _vehicles.isEmpty
                                ? []
                                : _vehicles.map((vehicle) {
                                    // چاپ اطلاعات بیشتر برای دیباگ
                                    print('Adding vehicle to dropdown: ID=${vehicle.id}, Name=${vehicle.vehicleName}, Key=${vehicle.key}');
                                    return DropdownMenuItem<Vehicle>(
                                      key: ValueKey('vehicle_${vehicle.id ?? vehicle.key}'),
                                      value: vehicle,
                                      child: Text(vehicle.vehicleName),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedVehicle = value;
                                });
                                // چاپ اطلاعات بعد از انتخاب وسیله نقلیه
                                _printDropdownsDebugInfo();
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'لطفاً وسیله نقلیه را انتخاب کنید';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<CargoType>(
                              key: UniqueKey(),
                              decoration: InputDecoration(
                                labelText: 'نوع سرویس بار',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              value: _cargoTypes.isEmpty ? null : _selectedCargoType,
                              items: _cargoTypes.isEmpty
                                ? []
                                : _cargoTypes.map((cargoType) {
                                    return DropdownMenuItem<CargoType>(
                                      key: ValueKey('cargoType_${cargoType.cargoName}'),
                                      value: cargoType,
                                      child: Text(cargoType.cargoName),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCargoType = value;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'لطفاً نوع سرویس بار را انتخاب کنید';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            AddressSelector(
                              title: 'مبدأ',
                              hint: 'شهر مبدأ را انتخاب یا وارد کنید',
                              controller: _originController,
                              initialValue: _originController.text,
                              onChanged: (value) {
                                _originController.text = value;
                              },
                              icon: Icons.location_on_outlined,
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: TextFormField(
                                controller: _loadingAddressController,
                                decoration: InputDecoration(
                                  labelText: 'محل بارگیری',
                                  hintText: 'آدرس دقیق محل بارگیری را وارد کنید',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: const Icon(Icons.location_on),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            AddressSelector(
                              title: 'مقصد',
                              hint: 'شهر مقصد را انتخاب یا وارد کنید',
                              controller: _destinationController,
                              initialValue: _destinationController.text,
                              onChanged: (value) {
                                _destinationController.text = value;
                              },
                              icon: Icons.pin_drop_outlined,
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: TextFormField(
                                controller: _unloadingAddressController,
                                decoration: InputDecoration(
                                  labelText: 'محل تخلیه',
                                  hintText: 'آدرس دقیق محل تخلیه را وارد کنید',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: const Icon(Icons.location_on),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: TextFormField(
                                controller: _recipientContactNumberController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText: 'شماره تماس تحویل گیرنده بار',
                                  hintText: 'مثال: 09123456789',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: const Icon(Icons.phone),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            PersianDateFormField(
                              selectedDate: _selectedDate,
                              onDateChanged: (date) {
                                setState(() {
                                  _selectedDate = date;
                                });
                              },
                              labelText: 'تاریخ بارگیری',
                              prefixIcon: Icon(Icons.calendar_today),
                              showWeekDay: true,
                              validator: (date) {
                                if (date == null) {
                                  return 'لطفاً تاریخ بارگیری را انتخاب کنید';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            PersianDateFormField(
                              selectedDate: _selectedUnloadingDate ?? DateTime.now(),
                              onDateChanged: (date) {
                                setState(() {
                                  _selectedUnloadingDate = date;
                                });
                              },
                              labelText: 'تاریخ تخلیه',
                              prefixIcon: Icon(Icons.calendar_today),
                              showWeekDay: true,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _weightController,
                              decoration: InputDecoration(
                                labelText: 'وزن (کیلوگرم)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: false),
                              inputFormatters: [
                                ThousandsFormatter(separator: '.'),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'لطفاً وزن را وارد کنید';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: TextFormField(
                                controller: _pricePerTonController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [ThousandsFormatter()],
                                decoration: const InputDecoration(
                                  labelText: 'قیمت هر تن بار به تومان',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: TextFormField(
                                controller: _transportCostPerTonController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [ThousandsFormatter()],
                                decoration: const InputDecoration(
                                  labelText: 'هزینه حمل هر تن بار به تومان',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: TextFormField(
                                controller: _waybillAmountController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [ThousandsFormatter()],
                                decoration: const InputDecoration(
                                  labelText: 'مبلغ بارنامه به تومان',
                                  hintText: 'مبلغ بارنامه را وارد کنید',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // اطلاعات بانکی و حساب
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              key: UniqueKey(),
                              decoration: InputDecoration(
                                labelText: 'اطلاعات حساب بانکی',
                                hintText: 'انتخاب حساب بانکی',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.account_balance),
                              ),
                              value: _bankAccounts.isEmpty ? null : _selectedBankAccount?.key.toString(),
                              isExpanded: true,
                              items: _bankAccounts.isEmpty 
                                ? [const DropdownMenuItem<String>(value: null, child: Text('-- انتخاب حساب بانکی --'))]
                                : [
                                    const DropdownMenuItem<String>(
                                      value: null,
                                      child: Text('-- انتخاب حساب بانکی --'),
                                    ),
                                    ..._bankAccounts.map((account) {
                                      String displayText = account.title;
                                      if (account.isDefault) {
                                        displayText += ' (پیش‌فرض)';
                                      }
                                      print('Adding bank account to dropdown: ID=${account.id}, Title=${account.title}, Key=${account.key}');
                                      return DropdownMenuItem<String>(
                                        value: account.key.toString(),
                                        child: Text(
                                          displayText, 
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }),
                                  ],
                              onChanged: (String? value) {
                                setState(() {
                                  if (value != null && _bankAccounts.isNotEmpty) {
                                    // پیدا کردن حساب بانکی بر اساس key به عنوان شناسه یکتا
                                    _selectedBankAccount = _bankAccounts.firstWhere(
                                      (account) => account.key.toString() == value,
                                      orElse: () => _bankAccounts.first,
                                    );
                                    
                                    // تنظیم مقادیر فیلدهای حساب بانکی
                                    _bankAccountController.text = _selectedBankAccount!.cardNumber ?? 
                                                            _selectedBankAccount!.sheba ?? 
                                                            _selectedBankAccount!.accountNumber ?? '';
                                    _bankNameController.text = _selectedBankAccount!.bankName;
                                    _accountOwnerNameController.text = _selectedBankAccount!.ownerName;
                                  } else {
                                    _selectedBankAccount = null;
                                    _bankAccountController.text = '';
                                    _bankNameController.text = '';
                                    _accountOwnerNameController.text = '';
                                  }
                                });
                                // چاپ اطلاعات بعد از انتخاب حساب بانکی
                                _printDropdownsDebugInfo();
                              },
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: TextFormField(
                                controller: _bankAccountController,
                                keyboardType: TextInputType.text,
                                readOnly: _selectedBankAccount != null,
                                decoration: InputDecoration(
                                  labelText: 'شماره شبا یا حساب اعلامی جهت واریز هزینه سرویس',
                                  hintText: 'مثال: IR062174790000001234567890 یا 1234-5678-9101-1121',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: const Icon(Icons.credit_card),
                                  suffixIcon: _selectedBankAccount != null 
                                    ? const Icon(Icons.lock_outline, color: Colors.grey)
                                    : null,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: TextFormField(
                                controller: _bankNameController,
                                keyboardType: TextInputType.text,
                                readOnly: _selectedBankAccount != null,
                                decoration: InputDecoration(
                                  labelText: 'نام بانک',
                                  hintText: 'مثال: بانک ملی ایران',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: const Icon(Icons.business),
                                  suffixIcon: _selectedBankAccount != null 
                                    ? const Icon(Icons.lock_outline, color: Colors.grey)
                                    : null,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: TextFormField(
                                controller: _accountOwnerNameController,
                                keyboardType: TextInputType.text,
                                readOnly: _selectedBankAccount != null,
                                decoration: InputDecoration(
                                  labelText: 'نام صاحب حساب',
                                  hintText: 'نام و نام خانوادگی صاحب حساب را وارد کنید',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: const Icon(Icons.person),
                                  suffixIcon: _selectedBankAccount != null 
                                    ? const Icon(Icons.lock_outline, color: Colors.grey)
                                    : null,
                                ),
                              ),
                            ),
                            
                            // آدرس‌های بارگیری و تخلیه
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: Colors.red),
                                const SizedBox(width: 8),
                                Text(
                                  'آدرس‌های بارگیری و تخلیه',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // عکس بارنامه
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'عکس بارنامه',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: _takePicture,
                                          icon: const Icon(Icons.camera_alt),
                                          label: const Text('گرفتن عکس'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: _pickImage,
                                          icon: const Icon(Icons.photo_library),
                                          label: const Text('از گالری'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (_selectedWaybillImage != null)
                                    Container(
                                      height: 200,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey.shade400),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          _selectedWaybillImage!,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    )
                                  else if (_savedWaybillImagePath != null)
                                    Container(
                                      height: 200,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey.shade400),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          File(_savedWaybillImagePath!),
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => const Center(
                                            child: Text('خطا در بارگذاری تصویر'),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 30),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[800],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            widget.cargo == null ? 'ثبت سرویس بار' : 'ذخیره تغییرات',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildVehicleDropdown() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Vehicle>('vehicles').listenable(),
      builder: (context, Box<Vehicle> box, _) {
        final vehicles = box.values.toList();
        
        if (vehicles.isEmpty) {
          return const Card(
            color: Colors.amber,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No vehicles found. Please add a vehicle first.'),
            ),
          );
        }
        
        return DropdownButtonFormField<Vehicle>(
          decoration: const InputDecoration(
            labelText: 'Select Vehicle',
            border: OutlineInputBorder(),
          ),
          value: _selectedVehicle,
          items: vehicles.map((vehicle) {
            return DropdownMenuItem<Vehicle>(
              value: vehicle,
              child: Text(vehicle.vehicleName),
            );
          }).toList(),
          onChanged: (value) {
      setState(() {
              _selectedVehicle = value;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'لطفاً وسیله نقلیه را انتخاب کنید';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildDriverDropdown() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Driver>('drivers').listenable(),
      builder: (context, Box<Driver> box, _) {
        final drivers = box.values.toList();
        
        if (drivers.isEmpty) {
          return const Card(
            color: Colors.amber,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No drivers found. Please add a driver first.'),
            ),
          );
        }
        
        return DropdownButtonFormField<Driver>(
          decoration: const InputDecoration(
            labelText: 'Select Driver',
            border: OutlineInputBorder(),
          ),
          value: _selectedDriver,
          items: drivers.map((driver) {
            return DropdownMenuItem<Driver>(
              value: driver,
              child: Text(driver.name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedDriver = value;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'لطفاً راننده را انتخاب کنید';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildCargoTypeDropdown() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<CargoType>('cargoTypes').listenable(),
      builder: (context, Box<CargoType> box, _) {
        final cargoTypes = box.values.toList();
        
        if (cargoTypes.isEmpty) {
          return const Card(
            color: Colors.amber,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('نوع سرویس باری یافت نشد. لطفاً ابتدا یک نوع سرویس بار ایجاد کنید.'),
            ),
          );
        }
        
        return DropdownButtonFormField<CargoType>(
          decoration: const InputDecoration(
            labelText: 'انتخاب نوع سرویس بار',
            border: OutlineInputBorder(),
          ),
          value: _selectedCargoType,
          items: cargoTypes.map((cargoType) {
            return DropdownMenuItem<CargoType>(
              value: cargoType,
              child: Text(cargoType.cargoName),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCargoType = value;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'لطفاً نوع سرویس بار را انتخاب کنید';
            }
            return null;
          },
        );
      },
    );
  }

  Future<void> _takePicture() async {
    print('DEBUG: Starting camera capture');
    try {
      // Set loading state to show feedback
      setState(() {
        _isLoading = true;
      });
      
      // Add timeout protection
      final pickedFile = await Future<XFile?>(() async {
        try {
          return await ImagePicker().pickImage(
            source: ImageSource.camera,
            maxWidth: 1800,
            maxHeight: 1800,
            imageQuality: 80, // Slightly reduce quality for faster processing
          );
        } catch (e) {
          print('ERROR in camera access: $e');
          throw e;
        }
      }).timeout(
        const Duration(seconds: 15), // Camera may take longer to initialize
        onTimeout: () {
          print('WARNING: Camera access timed out');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('دسترسی به دوربین با تاخیر مواجه شد. لطفاً دوباره تلاش کنید.')),
            );
          }
          return null;
        }
      );
      
      if (pickedFile != null) {
        print('DEBUG: Image captured from camera: ${pickedFile.path}');
        if (mounted) {
          setState(() {
            _selectedWaybillImage = File(pickedFile.path);
          });
        }
      } else {
        print('DEBUG: Camera capture canceled or failed');
      }
    } catch (e) {
      print('ERROR in _takePicture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در دسترسی به دوربین: ${e.toString()}')),
        );
      }
    } finally {
      // Reset loading state
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    print('DEBUG: Starting gallery picker');
    try {
      // Set loading state to show feedback
      setState(() {
        _isLoading = true;
      });
      
      // Add timeout protection
      final pickedFile = await Future<XFile?>(() async {
        try {
          return await ImagePicker().pickImage(
            source: ImageSource.gallery,
            maxWidth: 1800,
            maxHeight: 1800,
            imageQuality: 80, // Slightly reduce quality for faster processing
          );
        } catch (e) {
          print('ERROR in gallery access: $e');
          throw e;
        }
      }).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('WARNING: Gallery access timed out');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('دسترسی به گالری با تاخیر مواجه شد. لطفاً دوباره تلاش کنید.')),
            );
          }
          return null;
        }
      );
      
      if (pickedFile != null) {
        print('DEBUG: Image selected from gallery: ${pickedFile.path}');
        if (mounted) {
          setState(() {
            _selectedWaybillImage = File(pickedFile.path);
          });
        }
      } else {
        print('DEBUG: Gallery selection canceled or failed');
      }
    } catch (e) {
      print('ERROR in _pickImage: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در دسترسی به گالری: ${e.toString()}')),
        );
      }
    } finally {
      // Reset loading state
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String?> _saveWaybillImage() async {
    if (_selectedWaybillImage == null) return _savedWaybillImagePath;
    
    print('DEBUG: Starting to save waybill image');
    try {
      // Add a timeout to prevent hanging
      return await Future<String?>(() async {
        try {
          final appDir = await getApplicationDocumentsDirectory();
          final fileName = 'waybill_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final savedImage = await _selectedWaybillImage!.copy('${appDir.path}/$fileName');
          print('DEBUG: Waybill image saved successfully to ${savedImage.path}');
          return savedImage.path;
        } catch (e) {
          print('ERROR in file saving operation: $e');
          throw e; // Re-throw to be caught by the outer try-catch
        }
      }).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('WARNING: Waybill image saving timed out');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ذخیره تصویر بارنامه با تاخیر مواجه شد.')),
            );
          }
          return null;
        }
      );
    } catch (e) {
      print('ERROR saving waybill image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در ذخیره عکس: ${e.toString()}')),
        );
      }
      return null;
    }
  }

  // تنظیم حساب بانکی از اطلاعات موجود بار
  void _setBankAccountFromExistingCargo() {
    if (widget.cargo?.bankAccount != null && _bankAccounts.isNotEmpty) {
      // ابتدا _selectedBankAccount را null قرار می‌دهیم
      _selectedBankAccount = null;
      
      for (var account in _bankAccounts) {
        if (account.cardNumber == widget.cargo!.bankAccount || 
            account.sheba == widget.cargo!.bankAccount ||
            account.accountNumber == widget.cargo!.bankAccount) {
          setState(() {
            _selectedBankAccount = account;
          });
          
          // چاپ اطلاعات تطبیق حساب بانکی
          print('MATCHING BANK ACCOUNT:');
          print('  Cargo Bank Account: ${widget.cargo!.bankAccount}');
          print('  Selected Account: ${_selectedBankAccount?.title} (Key: ${_selectedBankAccount?.key})');
          print('  Account Card Number: ${account.cardNumber}');
          print('  Account Sheba: ${account.sheba}');
          print('  Account Number: ${account.accountNumber}');
          
          break;
        }
      }
      
      // چاپ اطلاعات بعد از تطبیق حساب بانکی
      _printDropdownsDebugInfo();
    }
  }
  
  // حذف حساب‌های بانکی تکراری
  List<BankAccount> _removeDuplicateBankAccounts(List<BankAccount> accounts) {
    final Map<String, BankAccount> uniqueAccounts = {};
    final Map<int?, List<BankAccount>> accountsById = {};
    
    print('\nCHECKING FOR DUPLICATE BANK ACCOUNTS:');
    // گروه‌بندی حساب‌ها بر اساس ID
    for (var account in accounts) {
      if (account.id == null) {
        print('WARNING: Bank account with null ID found: ${account.title}');
      }
      
      if (accountsById[account.id] == null) {
        accountsById[account.id] = [];
      }
      accountsById[account.id]!.add(account);
    }
    
    // چاپ حساب‌های با ID تکراری
    accountsById.forEach((id, accountsList) {
      if (accountsList.length > 1) {
        print('DUPLICATE BANK ACCOUNTS WITH ID: $id');
        for (var account in accountsList) {
          print('  - Title: ${account.title}, Card: ${account.cardNumber}, Key: ${account.key}');
        }
      }
    });
    
    for (var account in accounts) {
      // استفاده از کلید حساب به عنوان شناسه یکتا
      String uniqueKey = account.key.toString();
      uniqueAccounts[uniqueKey] = account;
    }
    
    return uniqueAccounts.values.toList();
  }
  
  // حذف آدرس‌های تکراری
  List<Address> _removeDuplicateAddresses(List<Address> addresses) {
    print('تعداد کل آدرس‌ها: ${addresses.length}');
    Map<String, Address> uniqueMap = {};
    
    for (var address in addresses) {
      String key = address.key.toString();
      if (!uniqueMap.containsKey(key)) {
        uniqueMap[key] = address;
      } else {
        print('آدرس تکراری پیدا شد: ${address.title}');
      }
    }
    
    print('تعداد آدرس‌های منحصربفرد: ${uniqueMap.length}');
    return uniqueMap.values.toList();
  }
  
  // بررسی خالی بودن لیست‌های کامبوباکس
  void _checkEmptyDropdowns() {
    if (_drivers.isEmpty) {
      _showEmptyDropdownNotification('راننده', 'لطفاً ابتدا راننده‌ای را در سیستم ثبت کنید.');
    }
    
    if (_vehicles.isEmpty) {
      _showEmptyDropdownNotification('وسیله نقلیه', 'لطفاً ابتدا وسیله نقلیه‌ای را در سیستم ثبت کنید.');
    }
    
    if (_cargoTypes.isEmpty) {
      _showEmptyDropdownNotification('نوع سرویس بار', 'لطفاً ابتدا نوع سرویس باری را در سیستم ثبت کنید.');
    }
    
    if (_bankAccounts.isEmpty) {
      _showEmptyDropdownNotification('حساب بانکی', 'لطفاً ابتدا اطلاعات حساب بانکی را در سیستم ثبت کنید.');
    }
    
    if (_addresses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('هیچ آدرسی ثبت نشده است. پیشنهاد می‌شود آدرس‌های بارگیری و تخلیه را ثبت کنید.'),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }
  
  // نمایش نوتیفیکیشن برای لیست خالی
  void _showEmptyDropdownNotification(String itemType, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'افزودن $itemType',
          onPressed: () {
            // مسیریابی به صفحه مربوطه بر اساس نوع آیتم
            switch (itemType) {
              case 'راننده':
                Navigator.pushNamed(context, '/driver_form');
                break;
              case 'وسیله نقلیه':
                Navigator.pushNamed(context, '/vehicle_form');
                break;
              case 'نوع سرویس بار':
                Navigator.pushNamed(context, '/cargo_type_form');
                break;
              case 'حساب بانکی':
                Navigator.pushNamed(context, '/bank_account_form');
                break;
              case 'آدرس':
                Navigator.pushNamed(context, '/address_screen');
                break;
            }
          },
        ),
      ),
    );
  }
  
  // چاپ اطلاعات تمام کامبوباکس‌ها در کنسول دیباگ
  void _printDropdownsDebugInfo() {
    print('============ CARGO FORM DROPDOWN DEBUG INFO ============');
    
    // چاپ اطلاعات راننده‌ها
    print('DRIVERS (${_drivers.length}):');
    for (var driver in _drivers) {
      print('  - ID: ${driver.id}, Name: ${driver.name}, Key: ${driver.key}');
    }
    print('Selected Driver: ${_selectedDriver?.name} (ID: ${_selectedDriver?.id})');
    
    // چاپ اطلاعات وسایل نقلیه
    print('\nVEHICLES (${_vehicles.length}):');
    for (var vehicle in _vehicles) {
      print('  - ID: ${vehicle.id}, Name: ${vehicle.vehicleName}, Key: ${vehicle.key}');
    }
    print('Selected Vehicle: ${_selectedVehicle?.vehicleName} (ID: ${_selectedVehicle?.id})');
    
    // چاپ اطلاعات انواع بار
    print('\nCARGO TYPES (${_cargoTypes.length}):');
    for (var cargoType in _cargoTypes) {
      print('  - Name: ${cargoType.cargoName}, Key: ${cargoType.key}');
    }
    print('Selected Cargo Type: ${_selectedCargoType?.cargoName}');
    
    // چاپ اطلاعات باربری‌ها
    print('\nFREIGHT COMPANIES (${_freightCompanies.length}):');
    for (var freight in _freightCompanies) {
      print('  - ID: ${freight.id}, Name: ${freight.name}, Key: ${freight.key}');
    }
    print('Selected Freight: ${_selectedFreight?.name} (ID: ${_selectedFreight?.id})');
    
    // چاپ اطلاعات حساب‌های بانکی
    print('\nBANK ACCOUNTS (${_bankAccounts.length}):');
    for (var account in _bankAccounts) {
      print('  - ID: ${account.id}, Title: ${account.title}, Card: ${account.cardNumber}, Key: ${account.key}');
    }
    print('Selected Bank Account: ${_selectedBankAccount?.title} (ID: ${_selectedBankAccount?.id})');
    
    // چاپ اطلاعات آدرس‌ها
    print('*** اطلاعات آدرس‌ها ***');
    for (var address in _addresses) {
      print('آدرس: ${address.id} | ${address.title} | کلید: ${address.key}');
    }
    
    print('=========================================================\n');
  }
} 