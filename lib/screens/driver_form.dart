import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:khatooniiii/models/driver.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DriverForm extends StatefulWidget {
  final Driver? driver;

  const DriverForm({super.key, this.driver});

  @override
  State<DriverForm> createState() => _DriverFormState();
}

class _DriverFormState extends State<DriverForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _salaryPercentageController = TextEditingController();
  final _bankAccountNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  
  File? _selectedNationalCardImage;
  File? _selectedLicenseImage;
  File? _selectedSmartCardImage;
  String? _savedNationalCardImagePath;
  String? _savedLicenseImagePath;
  String? _savedSmartCardImagePath;
  bool _isLoading = false;
  final bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    if (widget.driver != null) {
      _firstNameController.text = widget.driver!.firstName;
      _lastNameController.text = widget.driver!.lastName;
      _nationalIdController.text = widget.driver!.nationalId;
      _phoneNumberController.text = widget.driver!.mobile;
      _savedNationalCardImagePath = widget.driver!.imagePath;
      _savedLicenseImagePath = widget.driver!.licenseImagePath;
      _savedSmartCardImagePath = widget.driver!.smartCardImagePath;
      _salaryPercentageController.text = widget.driver!.salaryPercentage.toString();
      _bankAccountNumberController.text = widget.driver!.bankAccountNumber ?? '';
      _bankNameController.text = widget.driver!.bankName ?? '';
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nationalIdController.dispose();
    _phoneNumberController.dispose();
    _passwordController.dispose();
    _salaryPercentageController.dispose();
    _bankAccountNumberController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  Future<void> _takePicture(bool isNationalCard, [bool isSmartCard = false]) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1800,
        maxHeight: 1800,
      );
      if (pickedFile != null) {
        setState(() {
          if (isNationalCard) {
            _selectedNationalCardImage = File(pickedFile.path);
          } else if (isSmartCard) {
            _selectedSmartCardImage = File(pickedFile.path);
          } else {
            _selectedLicenseImage = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در دسترسی به دوربین: ${e.toString()}')),
      );
    }
  }

  Future<void> _pickImage(bool isNationalCard, [bool isSmartCard = false]) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
      );
      if (pickedFile != null) {
        setState(() {
          if (isNationalCard) {
            _selectedNationalCardImage = File(pickedFile.path);
          } else if (isSmartCard) {
            _selectedSmartCardImage = File(pickedFile.path);
          } else {
            _selectedLicenseImage = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در دسترسی به گالری: ${e.toString()}')),
      );
    }
  }

  Future<String?> _saveImage(File? imageFile, String? savedPath, String prefix) async {
    if (imageFile == null) {
      return savedPath;
    }

    final directory = await getApplicationDocumentsDirectory();
    final imageName = '${prefix}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedImage = await imageFile.copy(
      '${directory.path}/$imageName',
    );
    return savedImage.path;
  }

  Future<void> _saveDriver() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final nationalCardImagePath = await _saveImage(
          _selectedNationalCardImage, 
          _savedNationalCardImagePath, 
          'national_card'
        );
        
        final licenseImagePath = await _saveImage(
          _selectedLicenseImage, 
          _savedLicenseImagePath, 
          'license'
        );
        
        final smartCardImagePath = await _saveImage(
          _selectedSmartCardImage, 
          _savedSmartCardImagePath, 
          'smart_card'
        );

        final driversBox = Hive.box<Driver>('drivers');
        final driver = Driver(
          id: widget.driver?.id,
          name: '${_firstNameController.text} ${_lastNameController.text}',
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          nationalId: _nationalIdController.text,
          mobile: _phoneNumberController.text,
          licenseNumber: '',
          imagePath: nationalCardImagePath,
          licenseImagePath: licenseImagePath,
          smartCardImagePath: smartCardImagePath,
          password: _passwordController.text,
          salaryPercentage: double.tryParse(_salaryPercentageController.text) ?? 0,
          bankAccountNumber: _bankAccountNumberController.text.isEmpty ? null : _bankAccountNumberController.text,
          bankName: _bankNameController.text.isEmpty ? null : _bankNameController.text,
        );

        if (widget.driver != null) {
          await driversBox.put(widget.driver!.key, driver);
        } else {
          await driversBox.add(driver);
        }

        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: $e')),
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

  Widget _buildImageSection(bool isNationalCard) {
    final imageFile = isNationalCard ? _selectedNationalCardImage : _selectedLicenseImage;
    final savedPath = isNationalCard ? _savedNationalCardImagePath : _savedLicenseImagePath;
    final title = isNationalCard ? 'تصویر کارت ملی' : 'تصویر گواهینامه';
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[100],
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: imageFile != null || savedPath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image(
                          image: imageFile != null
                              ? FileImage(imageFile) as ImageProvider
                              : FileImage(File(savedPath!)),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isNationalCard ? Icons.credit_card : Icons.drive_eta,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'افزودن تصویر',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _takePicture(isNationalCard),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('دوربین'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(isNationalCard),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('گالری'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartCardImageSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تصویر کارت هوشمند راننده',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[100],
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: _selectedSmartCardImage != null || _savedSmartCardImagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image(
                          image: _selectedSmartCardImage != null
                              ? FileImage(_selectedSmartCardImage!) as ImageProvider
                              : FileImage(File(_savedSmartCardImagePath!)),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.credit_card,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'افزودن تصویر',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _takePicture(false, true),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('دوربین'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(false, true),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('گالری'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.driver == null ? 'ثبت راننده جدید' : 'ویرایش اطلاعات راننده'),
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
                            TextFormField(
                              controller: _firstNameController,
                              decoration: InputDecoration(
                                labelText: 'نام',
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
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'لطفاً نام را وارد کنید';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _lastNameController,
                              decoration: InputDecoration(
                                labelText: 'نام خانوادگی',
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
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'لطفاً نام خانوادگی را وارد کنید';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nationalIdController,
                              decoration: InputDecoration(
                                labelText: 'کد ملی',
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
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'لطفاً کد ملی را وارد کنید';
                                }
                                if (value.length != 10 || int.tryParse(value) == null) {
                                  return 'کد ملی باید 10 رقم باشد';
                                }
                                return null;
                              },
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneNumberController,
                              decoration: InputDecoration(
                                labelText: 'شماره موبایل',
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
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'لطفاً شماره موبایل را وارد کنید';
                                }
                                if (value.length != 11 || !value.startsWith('09')) {
                                  return 'شماره موبایل باید 11 رقم و با ۰۹ شروع شود';
                                }
                                return null;
                              },
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'رمز عبور',
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
                              validator: (value) {
                                if (widget.driver == null && (value == null || value.isEmpty)) {
                                  return 'لطفاً رمز عبور را وارد کنید';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'درصد حقوق',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _salaryPercentageController,
                              decoration: const InputDecoration(
                                labelText: 'درصد حقوق (بین 0 تا 100)',
                                border: OutlineInputBorder(),
                                suffixText: '%',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'لطفا درصد حقوق را وارد کنید';
                                }
                                final number = double.tryParse(value);
                                if (number == null || number < 0 || number > 100) {
                                  return 'لطفا یک عدد بین 0 تا 100 وارد کنید';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'اطلاعات بانکی',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _bankAccountNumberController,
                              decoration: const InputDecoration(
                                labelText: 'شماره کارت یا شماره شبا',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'لطفا شماره حساب را وارد کنید';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _bankNameController,
                              decoration: const InputDecoration(
                                labelText: 'نام بانک',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'لطفا نام بانک را وارد کنید';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildImageSection(true),
                            _buildImageSection(false),
                            _buildSmartCardImageSection(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 50.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saveDriver,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[800],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            widget.driver == null ? 'ثبت راننده' : 'ذخیره تغییرات',
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