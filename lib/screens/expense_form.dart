import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:khatooniiii/models/expense.dart';
import 'package:khatooniiii/models/cargo.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:khatooniiii/utils/number_formatter.dart';

class ExpenseForm extends StatefulWidget {
  final Expense? expense;

  const ExpenseForm({super.key, this.expense});

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'سوخت';
  final List<String> _categories = [
    'سوخت',
    'تعمیرات',
    'لاستیک',
    'عوارض',
    'جریمه',
    'غذا',
    'دستمزد',
    'سایر'
  ];
  File? _selectedImage;
  String? _savedImagePath;
  bool _isLoading = false;
  Cargo? _selectedCargo;

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      _titleController.text = widget.expense!.title;
      _amountController.text = widget.expense!.amount.toString();
      _descriptionController.text = widget.expense!.description;
      _selectedDate = widget.expense!.date;
      _selectedCategory = widget.expense!.category;
      _savedImagePath = widget.expense!.imagePath;
      _selectedCargo = widget.expense!.cargo;
    } else {
      _selectMostRecentCargo();
    }
  }

  void _selectMostRecentCargo() {
    final cargosBox = Hive.box<Cargo>('cargos');
    if (cargosBox.isNotEmpty) {
      final cargos = cargosBox.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      
      if (cargos.isNotEmpty) {
        setState(() {
          _selectedCargo = cargos.first;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('fa', 'IR'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _takePhoto() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1800,
      maxHeight: 1800,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      maxHeight: 1800,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _saveImage() async {
    if (_selectedImage == null) {
      return _savedImagePath;
    }

    final directory = await getApplicationDocumentsDirectory();
    final imageName = 'expense_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedImage = await _selectedImage!.copy(
      '${directory.path}/$imageName',
    );
    return savedImage.path;
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        String? imagePath = _savedImagePath;
        
        if (_selectedImage != null) {
          final appDir = await getApplicationDocumentsDirectory();
          final fileName = 'expense_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final savedImage = await _selectedImage!.copy('${appDir.path}/$fileName');
          imagePath = savedImage.path;
        }

        final expense = Expense(
          id: widget.expense?.id,
          title: _titleController.text,
          amount: double.parse(_amountController.text.replaceAll(',', '').replaceAll('.', '')),
          date: _selectedDate,
          category: _selectedCategory,
          description: _descriptionController.text,
          imagePath: imagePath,
          cargo: _selectedCargo,
        );

        final expensesBox = Hive.box<Expense>('expenses');
        
        if (widget.expense != null) {
          await expensesBox.put(widget.expense!.key, expense);
        } else {
          await expensesBox.add(expense);
        }

        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در ذخیره هزینه: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Widget _buildCargoDropdown() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Cargo>('cargos').listenable(),
      builder: (context, Box<Cargo> box, _) {
        final cargos = box.values.toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        
        if (cargos.isEmpty) {
          return const SizedBox();
        }
        
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مرتبط با سرویس بار',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'به صورت پیش‌فرض، هزینه با آخرین سرویس بار مرتبط می‌شود',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<Cargo>(
                  decoration: InputDecoration(
                    labelText: 'انتخاب سرویس بار',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[400]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[400]!),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  value: _selectedCargo,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<Cargo>(
                      value: null,
                      child: Text('بدون ارتباط با سرویس بار'),
                    ),
                    ...cargos.map((cargo) {
                      final date = DateFormat('yyyy/MM/dd').format(cargo.date);
                      return DropdownMenuItem<Cargo>(
                        value: cargo,
                        child: Text(
                          '${cargo.driver.name} - ${cargo.origin} به ${cargo.destination} ($date)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: (Cargo? newValue) {
                    setState(() {
                      _selectedCargo = newValue;
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expense == null ? 'ثبت هزینه جدید' : 'ویرایش هزینه'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
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
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'عنوان هزینه',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'لطفاً عنوان هزینه را وارد کنید';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'مبلغ (تومان)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        ThousandsFormatter(separator: '.'),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'لطفاً مبلغ را وارد کنید';
                        }
                        if (double.tryParse(value.replaceAll(',', '').replaceAll('.', '')) == null) {
                          return 'لطفاً یک عدد معتبر وارد کنید';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'دسته‌بندی',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedCategory,
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'تاریخ',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          DateFormat('yyyy/MM/dd').format(_selectedDate),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'توضیحات',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    const Text('تصویر مربوطه:'),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _takePhoto,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('دوربین'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('گالری'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_selectedImage != null)
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    else if (_savedImagePath != null)
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.file(
                          File(_savedImagePath!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 16),
                    _buildCargoDropdown(),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 50.0),
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
                            widget.expense == null ? 'ثبت هزینه' : 'ذخیره تغییرات',
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
} 