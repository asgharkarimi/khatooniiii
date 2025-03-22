import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:khatooniiii/models/cargo_type.dart';

class CargoTypeForm extends StatefulWidget {
  final CargoType? cargoType;

  const CargoTypeForm({super.key, this.cargoType});

  @override
  State<CargoTypeForm> createState() => _CargoTypeFormState();
}

class _CargoTypeFormState extends State<CargoTypeForm> {
  final _formKey = GlobalKey<FormState>();
  final _cargoNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.cargoType != null) {
      _cargoNameController.text = widget.cargoType!.cargoName;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cargoType == null ? 'ثبت نوع سرویس بار جدید' : 'ویرایش نوع سرویس بار'),
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
                controller: _cargoNameController,
                decoration: const InputDecoration(
                  labelText: 'نام نوع سرویس بار',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'لطفاً نام نوع سرویس بار را وارد کنید';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(
                  widget.cargoType == null ? 'ثبت نوع سرویس بار' : 'ذخیره تغییرات',
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
        final cargoTypesBox = Hive.box<CargoType>('cargoTypes');
        final cargoType = CargoType(
          id: widget.cargoType?.id,
          cargoName: _cargoNameController.text.trim(),
        );

        if (widget.cargoType != null) {
          await cargoTypesBox.put(widget.cargoType!.key, cargoType);
        } else {
          await cargoTypesBox.add(cargoType);
        }

        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در ذخیره نوع سرویس بار: ${e.toString()}')),
        );
      }
    }
  }
} 