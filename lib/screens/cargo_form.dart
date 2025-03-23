import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:khatooniiii/models/cargo.dart';
import 'package:khatooniiii/models/cargo_type.dart';
import 'package:khatooniiii/models/driver.dart';
import 'package:khatooniiii/models/vehicle.dart';
import 'package:intl/intl.dart';
import 'package:khatooniiii/utils/number_formatter.dart';

class CargoForm extends StatefulWidget {
  final Cargo? cargo;

  const CargoForm({super.key, this.cargo});

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

  Vehicle? _selectedVehicle;
  Driver? _selectedDriver;
  CargoType? _selectedCargoType;
  DateTime _selectedDate = DateTime.now();

  bool _isLoading = false;
  String _errorMessage = '';

  late List<Driver> _drivers;
  late List<Vehicle> _vehicles;
  late List<CargoType> _cargoTypes;

  @override
  void initState() {
    super.initState();
    _drivers = Hive.box<Driver>('drivers').values.toList();
    _vehicles = Hive.box<Vehicle>('vehicles').values.toList();
    _cargoTypes = Hive.box<CargoType>('cargoTypes').values.toList();
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _weightController.dispose();
    _pricePerTonController.dispose();
    _transportCostPerTonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Default values for numeric fields
      double pricePerTon = 0;
      double weight = 0;
      double transportCost = 0;

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

      final cargo = Cargo(
        id: widget.cargo?.id,
        vehicle: _selectedVehicle!,
        driver: _selectedDriver!,
        cargoType: _selectedCargoType!,
        origin: _originController.text,
        destination: _destinationController.text,
        date: _selectedDate,
        weight: weight,
        pricePerTon: pricePerTon,
        paymentStatus: widget.cargo?.paymentStatus ?? PaymentStatus.pending,
        transportCostPerTon: transportCost,
      );

      final cargosBox = Hive.box<Cargo>('cargos');
      if (widget.cargo != null) {
        // Editing existing cargo
        widget.cargo!.vehicle = cargo.vehicle;
        widget.cargo!.driver = cargo.driver;
        widget.cargo!.cargoType = cargo.cargoType;
        widget.cargo!.origin = cargo.origin;
        widget.cargo!.destination = cargo.destination;
        widget.cargo!.date = cargo.date;
        widget.cargo!.weight = cargo.weight;
        widget.cargo!.pricePerTon = cargo.pricePerTon;
        widget.cargo!.transportCostPerTon = cargo.transportCostPerTon;
        widget.cargo!.save();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('سرویس بار با موفقیت ویرایش شد')),
        );
      } else {
        // Adding new cargo
        cargosBox.add(cargo);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('سرویس بار با موفقیت ثبت شد')),
        );
      }
      Navigator.pop(context);
    }
  }

  bool _validateDropdowns() {
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
                              decoration: InputDecoration(
                                labelText: 'راننده',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              value: _selectedDriver,
                              items: _drivers.map((driver) {
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
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<Vehicle>(
                              decoration: InputDecoration(
                                labelText: 'وسیله نقلیه',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              value: _selectedVehicle,
                              items: _vehicles.map((vehicle) {
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
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<CargoType>(
                              decoration: InputDecoration(
                                labelText: 'نوع سرویس بار',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              value: _selectedCargoType,
                              items: _cargoTypes.map((cargoType) {
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
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _originController,
                              decoration: InputDecoration(
                                labelText: 'مبدأ',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'لطفاً مبدأ را وارد کنید';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _destinationController,
                              decoration: InputDecoration(
                                labelText: 'مقصد',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'لطفاً مقصد را وارد کنید';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () => _selectDate(context),
                              child: AbsorbPointer(
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'تاریخ',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    suffixIcon: const Icon(Icons.calendar_today),
                                  ),
                                  controller: TextEditingController(
                                    text: DateFormat('yyyy/MM/dd').format(_selectedDate),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _weightController,
                              decoration: InputDecoration(
                                labelText: 'وزن (کیلوگرم)',
                                hintText: 'برای محاسبه مقطوع، وزن را صفر وارد کنید',
                                helperText: 'وزن صفر به معنای محاسبه مقطوع است',
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
                                  return 'لطفاً وزن را وارد کنید (برای محاسبه مقطوع، مقدار 0 وارد کنید)';
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
                                  hintText: 'برای وزن صفر، این مقدار قیمت کل خواهد بود',
                                  helperText: 'در صورت وزن صفر، مقدار کل را وارد کنید',
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
                                  hintText: 'برای وزن صفر، این مقدار هزینه کل خواهد بود',
                                  helperText: 'در صورت وزن صفر، هزینه کل را وارد کنید (اختیاری)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
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
        );
      },
    );
  }
} 