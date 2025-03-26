import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:khatooniiii/models/vehicle.dart';

class VehicleForm extends StatefulWidget {
  final Vehicle? vehicle;

  const VehicleForm({super.key, this.vehicle});

  @override
  State<VehicleForm> createState() => _VehicleFormState();
}

class _VehicleFormState extends State<VehicleForm> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleNameController = TextEditingController();
  final _smartCardNumberController = TextEditingController();
  final _healthCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.vehicle != null) {
      _vehicleNameController.text = widget.vehicle!.vehicleName;
      _smartCardNumberController.text = widget.vehicle!.smartCardNumber ?? '';
      _healthCodeController.text = widget.vehicle!.healthCode ?? '';
    }
  }

  @override
  void dispose() {
    _vehicleNameController.dispose();
    _smartCardNumberController.dispose();
    _healthCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vehicle == null ? 'ثبت وسیله نقلیه جدید' : 'ویرایش وسیله نقلیه'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _vehicleNameController,
                decoration: const InputDecoration(
                  labelText: 'نام وسیله نقلیه',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'لطفاً نام وسیله نقلیه را وارد کنید';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _smartCardNumberController,
                decoration: const InputDecoration(
                  labelText: 'شماره هوشمند خودرو',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'لطفاً شماره هوشمند خودرو را وارد کنید';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _healthCodeController,
                decoration: const InputDecoration(
                  labelText: 'کد بهداشتی خودرو',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'لطفاً کد بهداشتی خودرو را وارد کنید';
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
                  widget.vehicle == null ? 'ثبت وسیله نقلیه' : 'ذخیره تغییرات',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final vehiclesBox = Hive.box<Vehicle>('vehicles');
        final vehicle = Vehicle(
          id: widget.vehicle?.id,
          vehicleName: _vehicleNameController.text.trim(),
          smartCardNumber: _smartCardNumberController.text.trim(),
          healthCode: _healthCodeController.text.trim(),
        );

        if (widget.vehicle != null) {
          await vehiclesBox.put(widget.vehicle!.key, vehicle);
        } else {
          await vehiclesBox.add(vehicle);
        }

        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در ذخیره وسیله نقلیه: ${e.toString()}')),
        );
      }
    }
  }
} 