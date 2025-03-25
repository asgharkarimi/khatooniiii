import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:khatooniiii/models/cargo_type.dart';
import 'package:khatooniiii/utils/date_utils.dart';
import 'package:intl/intl.dart';
import 'package:khatooniiii/screens/cargo_type_form.dart';

class CargoTypeManagement extends StatefulWidget {
  const CargoTypeManagement({super.key});

  @override
  State<CargoTypeManagement> createState() => _CargoTypeManagementState();
}

class _CargoTypeManagementState extends State<CargoTypeManagement> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkCargoTypesBox();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _addCargoType() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final cargoTypesBox = await Hive.openBox<CargoType>('cargoTypes');
        
        final cargoType = CargoType(
          cargoName: _nameController.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await cargoTypesBox.add(cargoType);
        await cargoTypesBox.flush();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('نوع سرویس با موفقیت اضافه شد')),
          );
          _resetForm();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطا در افزودن نوع سرویس: $e')),
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

  Future<void> _deleteCargoType(CargoType cargoType) async {
    try {
      final cargoTypesBox = await Hive.openBox<CargoType>('cargoTypes');
      await cargoType.delete();
      await cargoTypesBox.flush();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('نوع سرویس با موفقیت حذف شد')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در حذف نوع سرویس: $e')),
        );
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _descriptionController.clear();
    setState(() {
      _errorMessage = '';
    });
  }

  Future<void> _checkCargoTypesBox() async {
    try {
      // First try to close the box if it's already open
      if (Hive.isBoxOpen('cargoTypes')) {
        await Hive.box('cargoTypes').close();
      }
      
      try {
        // Try to open the box normally first
        final box = await Hive.openBox<CargoType>('cargoTypes');
        print('\n=== Cargo Types Box Info ===');
        print('Box Name: ${box.name}');
        print('Number of items: ${box.length}');
        print('===========================\n');
      } catch (e) {
        print('Error opening cargo types box: $e');
        print('Attempting to recover by deleting and recreating the box...');
        
        // If opening fails, delete and recreate the box
        await Hive.deleteBoxFromDisk('cargoTypes');
        final box = await Hive.openBox<CargoType>('cargoTypes');
        print('Successfully recreated cargo types box');
        print('Number of items: ${box.length}');
      }
    } catch (e) {
      print('Error checking cargo types box: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت انواع سرویس'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          // Debug button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              try {
                // Close the box if open
                if (Hive.isBoxOpen('cargoTypes')) {
                  await Hive.box('cargoTypes').close();
                }
                // Delete and recreate
                await Hive.deleteBoxFromDisk('cargoTypes');
                await Hive.openBox<CargoType>('cargoTypes');
                
                setState(() {});
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('بازنشانی جعبه با موفقیت انجام شد')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('خطا در بازنشانی: $e')),
                );
              }
            },
            tooltip: 'بازنشانی جعبه',
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<CargoType>('cargoTypes').listenable(),
        builder: (context, Box<CargoType> box, _) {
          final cargoTypes = box.values.toList();

          if (cargoTypes.isEmpty) {
            return const Center(
              child: Text('هیچ نوع سرویسی ثبت نشده است'),
            );
          }

          return ListView.builder(
            itemCount: cargoTypes.length,
            itemBuilder: (context, index) {
              final cargoType = cargoTypes[index];
              return ListTile(
                title: Text(cargoType.cargoName),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CargoTypeForm(cargoType: cargoType),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        await cargoType.delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('نوع سرویس با موفقیت حذف شد')),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
} 