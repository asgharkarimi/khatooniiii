import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:khatooniiii/models/cargo.dart';
import 'package:khatooniiii/models/cargo_type.dart';
import 'package:khatooniiii/models/driver.dart';
import 'package:khatooniiii/models/vehicle.dart';
import 'package:intl/intl.dart';
import 'package:khatooniiii/utils/number_formatter.dart';
import 'package:khatooniiii/utils/date_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

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
  final _waybillAmountController = TextEditingController();

  Vehicle? _selectedVehicle;
  Driver? _selectedDriver;
  CargoType? _selectedCargoType;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  
  File? _selectedWaybillImage;
  String? _savedWaybillImagePath;

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
    
    if (widget.cargo != null) {
      _originController.text = widget.cargo!.origin;
      _destinationController.text = widget.cargo!.destination;
      _weightController.text = widget.cargo!.weight.toString();
      _pricePerTonController.text = widget.cargo!.pricePerTon.toString();
      _transportCostPerTonController.text = widget.cargo!.transportCostPerTon.toString();
      _waybillAmountController.text = widget.cargo!.waybillAmount?.toString() ?? '0';
      _selectedVehicle = widget.cargo!.vehicle;
      _selectedDriver = widget.cargo!.driver;
      _selectedCargoType = widget.cargo!.cargoType;
      _selectedDate = widget.cargo!.date;
      _savedWaybillImagePath = widget.cargo!.waybillImagePath;
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
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? picked = await AppDateUtils.showJalaliDatePicker(
      context: context,
      initialDate: _selectedDate,
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
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
        
        // Save waybill image if selected
        final waybillImagePath = await _saveWaybillImage();
  
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
          waybillAmount: waybillAmount,
          waybillImagePath: waybillImagePath,
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
          
          // Handle waybillAmount with special care for existing records
          try {
            widget.cargo!.waybillAmount = cargo.waybillAmount;
          } catch (e) {
            // If the field doesn't exist in old records, this might fail
            // We could recreate the cargo object with all fields or add a migration
            // For now, we'll ignore this error silently
          }
          
          widget.cargo!.waybillImagePath = cargo.waybillImagePath;
          await widget.cargo!.save();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('سرویس بار با موفقیت ویرایش شد')),
          );
        } else {
          // Adding new cargo
          await cargosBox.add(cargo);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('سرویس بار با موفقیت ثبت شد')),
          );
        }
        if (mounted) Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
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
                            InkWell(
                              onTap: () => _selectDateTime(context),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'تاریخ',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  suffixIcon: const Icon(Icons.calendar_today),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
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
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1800,
        maxHeight: 1800,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedWaybillImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در دسترسی به دوربین: ${e.toString()}')),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedWaybillImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در دسترسی به گالری: ${e.toString()}')),
      );
    }
  }

  Future<String?> _saveWaybillImage() async {
    if (_selectedWaybillImage == null) return _savedWaybillImagePath;
    
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'waybill_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await _selectedWaybillImage!.copy('${appDir.path}/$fileName');
      return savedImage.path;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در ذخیره عکس: ${e.toString()}')),
      );
      return null;
    }
  }
} 