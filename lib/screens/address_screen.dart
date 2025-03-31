import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:khatooniiii/models/address.dart';

class AddressScreen extends StatefulWidget {
  final Address? selectedAddress;
  final Function(Address)? onAddressSelected;

  const AddressScreen({
    super.key,
    this.selectedAddress,
    this.onAddressSelected,
  });

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _provinceController = TextEditingController();
  final _cityController = TextEditingController();
  final _detailsController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();

  List<Address> _addresses = [];
  bool _isLoading = false;
  Address? _selectedAddress;
  
  // برای مدیریت تب‌ها
  late final TabController _tabController = TabController(length: 2, vsync: this);

  @override
  void initState() {
    super.initState();
    _selectedAddress = widget.selectedAddress;
    _loadAddresses();
    
    // وقتی آدرسی در تب لیست انتخاب شود، به تب فرم سوییچ می‌کنیم
    _tabController.addListener(() {
      // اگر در تب لیست هستیم و آدرسی از قبل انتخاب شده، به تب فرم برویم
      if (!_tabController.indexIsChanging && 
          _tabController.index == 0 && 
          _selectedAddress != null) {
        _tabController.animateTo(1);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _provinceController.dispose();
    _cityController.dispose();
    _detailsController.dispose();
    _postalCodeController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final box = Hive.box<Address>('addresses');
      setState(() {
        _addresses = box.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading addresses: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resetForm() {
    _titleController.clear();
    _provinceController.clear();
    _cityController.clear();
    _detailsController.clear();
    _postalCodeController.clear();
    _contactNameController.clear();
    _contactPhoneController.clear();
    setState(() {
      _selectedAddress = null;
    });
  }

  void _selectAddress(Address address) {
    if (widget.onAddressSelected != null) {
      widget.onAddressSelected!(address);
      Navigator.pop(context);
    } else {
      setState(() {
        _selectedAddress = address;
        _titleController.text = address.title;
        _provinceController.text = address.province;
        _cityController.text = address.city;
        _detailsController.text = address.details ?? '';
        _postalCodeController.text = address.postalCode ?? '';
        _contactNameController.text = address.contactName ?? '';
        _contactPhoneController.text = address.contactPhone ?? '';
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final box = Hive.box<Address>('addresses');

        // Find max ID for new address
        int maxId = 0;
        for (final address in box.values) {
          if (address.id != null && address.id! > maxId) {
            maxId = address.id!;
          }
        }

        final address = Address(
          id: _selectedAddress?.id ?? maxId + 1,
          title: _titleController.text.trim(),
          province: _provinceController.text.trim(),
          city: _cityController.text.trim(),
          details: _detailsController.text.trim(),
          postalCode: _postalCodeController.text.trim(),
          contactName: _contactNameController.text.trim(),
          contactPhone: _contactPhoneController.text.trim(),
        );

        if (_selectedAddress != null) {
          // Update existing address
          await _selectedAddress!.delete();
        }
        
        await box.add(address);
        
        // Reset form and reload addresses
        _resetForm();
        await _loadAddresses();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('آدرس با موفقیت ذخیره شد')),
          );
        }
      } catch (e) {
        print('Error saving address: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطا در ذخیره آدرس: $e')),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteAddress(Address address) async {
    try {
      await address.delete();
      await _loadAddresses();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('آدرس با موفقیت حذف شد')),
        );
      }
      
      if (_selectedAddress?.key == address.key) {
        _resetForm();
      }
    } catch (e) {
      print('Error deleting address: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در حذف آدرس: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت آدرس‌ها'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAddresses,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.list),
              text: 'لیست آدرس‌ها',
            ),
            Tab(
              icon: Icon(Icons.add_location_alt),
              text: 'افزودن آدرس',
            ),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
        ),
      ),
      resizeToAvoidBottomInset: true,
      body: TabBarView(
        controller: _tabController,
        children: [
          // تب لیست آدرس‌ها
          _buildAddressList(),
          
          // تب فرم افزودن/ویرایش آدرس
          _buildAddressForm(),
        ],
      ),
      floatingActionButton: _tabController.index == 0 
          ? FloatingActionButton(
              onPressed: () {
                _resetForm();
                _tabController.animateTo(1);
              },
              tooltip: 'افزودن آدرس جدید',
              child: const Icon(Icons.add_location_alt),
            )
          : null,
    );
  }
  
  // ساخت تب لیست آدرس‌ها
  Widget _buildAddressList() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // فیلتر و جستجو
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'تعداد آدرس‌های ثبت شده: ${_addresses.length}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // لیست آدرس‌ها
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _addresses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.location_off,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'هیچ آدرسی یافت نشد',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'لطفاً یک آدرس جدید اضافه کنید',
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  _resetForm();
                                  _tabController.animateTo(1);
                                },
                                icon: const Icon(Icons.add_location_alt),
                                label: const Text('افزودن آدرس جدید'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _addresses.length,
                          itemBuilder: (context, index) {
                            final address = _addresses[index];
                            final isSelected = _selectedAddress?.key == address.key;
                            
                            return Dismissible(
                              key: Key(address.key.toString()),
                              background: Container(
                                color: Colors.red.shade100,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                              ),
                              secondaryBackground: Container(
                                color: Colors.blue.shade100,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 20),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                              ),
                              confirmDismiss: (direction) async {
                                if (direction == DismissDirection.startToEnd) {
                                  // حذف آدرس
                                  return await showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('حذف آدرس'),
                                        content: Text('آیا از حذف آدرس "${address.title}" اطمینان دارید؟'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(false),
                                            child: const Text('خیر'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(true),
                                            child: const Text('بله، حذف شود'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                } else {
                                  // ویرایش آدرس
                                  _selectAddress(address);
                                  return false;
                                }
                              },
                              onDismissed: (direction) {
                                if (direction == DismissDirection.startToEnd) {
                                  _deleteAddress(address);
                                }
                              },
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: isSelected
                                      ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
                                      : BorderSide.none,
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                  title: Row(
                                    children: [
                                      Icon(
                                        Icons.location_on, 
                                        color: Theme.of(context).colorScheme.primary,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          address.title,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4, right: 24),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${address.province}، ${address.city}'),
                                        if (address.details != null && address.details!.isNotEmpty)
                                          Text(
                                            address.details!,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        if (address.contactName != null && address.contactName!.isNotEmpty)
                                          Row(
                                            children: [
                                              const Icon(Icons.person, size: 12, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                'تماس: ${address.contactName}${address.contactPhone != null ? ' - ${address.contactPhone}' : ''}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _selectAddress(address),
                                        tooltip: 'ویرایش',
                                        iconSize: 20,
                                        constraints: const BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 32,
                                        ),
                                        padding: EdgeInsets.zero,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _showDeleteDialog(address),
                                        tooltip: 'حذف',
                                        iconSize: 20,
                                        constraints: const BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 32,
                                        ),
                                        padding: EdgeInsets.zero,
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    if (widget.onAddressSelected != null) {
                                      widget.onAddressSelected!(address);
                                      Navigator.pop(context);
                                    } else {
                                      _selectAddress(address);
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
  
  // دیالوگ تأیید حذف آدرس
  void _showDeleteDialog(Address address) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('حذف آدرس'),
          content: Text('آیا از حذف آدرس "${address.title}" اطمینان دارید؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('خیر'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAddress(address);
              },
              child: const Text('بله، حذف شود'),
            ),
          ],
        );
      },
    );
  }
  
  // ساخت تب فرم افزودن آدرس
  Widget _buildAddressForm() {
    return SafeArea(
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.05),
                Colors.white,
              ],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // عنوان فرم
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          Theme.of(context).colorScheme.primary.withOpacity(0.7),
                          Theme.of(context).colorScheme.primary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _selectedAddress == null ? Icons.add_location_alt : Icons.edit_location_alt,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _selectedAddress == null ? 'افزودن آدرس جدید' : 'ویرایش آدرس',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // مشخصات اصلی
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
                          const Padding(
                            padding: EdgeInsets.only(bottom: 16.0),
                            child: Text(
                              'مشخصات اصلی',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          
                          // عنوان آدرس
                          TextFormField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              labelText: 'عنوان آدرس',
                              hintText: 'مثال: دفتر مرکزی، انبار شماره ۱',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.label),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'لطفاً عنوان آدرس را وارد کنید';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // استان و شهر در یک ردیف
                          Row(
                            children: [
                              // استان
                              Expanded(
                                child: TextFormField(
                                  controller: _provinceController,
                                  decoration: InputDecoration(
                                    labelText: 'استان',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.location_city),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'لطفاً استان را وارد کنید';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              // شهر
                              Expanded(
                                child: TextFormField(
                                  controller: _cityController,
                                  decoration: InputDecoration(
                                    labelText: 'شهر',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.location_on),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'لطفاً شهر را وارد کنید';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // جزئیات آدرس
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
                          const Padding(
                            padding: EdgeInsets.only(bottom: 16.0),
                            child: Text(
                              'جزئیات آدرس',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          
                          // جزئیات آدرس
                          TextFormField(
                            controller: _detailsController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'جزئیات آدرس',
                              hintText: 'خیابان، کوچه، پلاک و ...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(bottom: 32),
                                child: Icon(Icons.home),
                              ),
                              alignLabelWithHint: true,
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // کد پستی
                          TextFormField(
                            controller: _postalCodeController,
                            decoration: InputDecoration(
                              labelText: 'کد پستی',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.markunread_mailbox),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // اطلاعات تماس
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
                          const Padding(
                            padding: EdgeInsets.only(bottom: 16.0),
                            child: Text(
                              'اطلاعات تماس',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          
                          // اطلاعات تماس
                          Row(
                            children: [
                              // نام تماس گیرنده
                              Expanded(
                                child: TextFormField(
                                  controller: _contactNameController,
                                  decoration: InputDecoration(
                                    labelText: 'نام تماس گیرنده',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.person),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // شماره تماس
                              Expanded(
                                child: TextFormField(
                                  controller: _contactPhoneController,
                                  decoration: InputDecoration(
                                    labelText: 'شماره تماس',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.phone),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                  keyboardType: TextInputType.phone,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // دکمه‌های عملیات
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _submitForm,
                                  icon: _isLoading 
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.save),
                                  label: Text(_selectedAddress == null ? 'ثبت آدرس' : 'بروزرسانی آدرس'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: () {
                                  _resetForm();
                                  if (_selectedAddress != null) {
                                    setState(() {
                                      _selectedAddress = null;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.refresh),
                                label: Text(_selectedAddress == null ? 'پاک کردن فرم' : 'فرم جدید'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          if (_addresses.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () => _tabController.animateTo(0),
                              icon: const Icon(Icons.list),
                              label: const Text('مشاهده لیست آدرس‌ها'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                minimumSize: const Size(double.infinity, 50),
                                foregroundColor: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 