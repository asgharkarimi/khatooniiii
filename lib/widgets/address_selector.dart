import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:khatooniiii/models/address.dart';
import 'package:khatooniiii/screens/address_screen.dart';

class AddressSelector extends StatefulWidget {
  final String title;
  final String hint;
  final TextEditingController controller;
  final String? initialValue;
  final Function(String) onChanged;
  final bool showAddButton;
  final IconData icon;

  const AddressSelector({
    super.key,
    required this.title,
    required this.hint,
    required this.controller,
    required this.onChanged,
    this.initialValue,
    this.showAddButton = true,
    this.icon = Icons.location_on,
  });

  @override
  State<AddressSelector> createState() => _AddressSelectorState();
}

class _AddressSelectorState extends State<AddressSelector> {
  List<Address> _addresses = [];
  bool _isLoading = true;
  Address? _selectedAddress;

  @override
  void initState() {
    super.initState();
    print('DEBUG: AddressSelector initState for ${widget.title}');
    
    // Initialize with empty state first, then load data
    _addresses = [];
    _isLoading = true;
    
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      widget.controller.text = widget.initialValue!;
    }
    
    // Use a delayed load to prevent UI blocking
    Future.delayed(Duration.zero, _loadAddresses);
  }

  Future<void> _loadAddresses() async {
    print('DEBUG: Loading addresses for ${widget.title}');
    
    // Load addresses with timeout protection to prevent hanging
    try {
      final result = await Future<List<Address>>(() {
        try {
          final box = Hive.box<Address>('addresses');
          return box.values.toList();
        } catch (e) {
          print('Error accessing address box: $e');
          return <Address>[];
        }
      }).timeout(
        const Duration(seconds: 1),
        onTimeout: () {
          print('DEBUG: Address loading timed out for ${widget.title}');
          return <Address>[];
        }
      );
      
      if (mounted) {
        setState(() {
          _addresses = result;
          _isLoading = false;
        });
        print('DEBUG: Loaded ${_addresses.length} addresses for ${widget.title}');
      }
    } catch (e) {
      print('Error loading addresses: $e');
      if (mounted) {
        setState(() {
          _addresses = [];
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToAddressScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddressScreen(
          onAddressSelected: (address) {
            setState(() {
              _selectedAddress = address;
              widget.controller.text = address.getFullAddress();
              widget.onChanged(address.getFullAddress());
            });
          },
        ),
      ),
    );

    // Reload addresses after returning from the address screen
    _loadAddresses();
  }

  @override
  Widget build(BuildContext context) {
    // Use a lightweight design that doesn't rely too much on complex state
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (widget.showAddButton)
              TextButton.icon(
                onPressed: _navigateToAddressScreen,
                icon: const Icon(Icons.add_location_alt, size: 18),
                label: const Text('مدیریت آدرس‌ها'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _isLoading
            ? Container(
                height: 56,
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : _buildAddressField(),
      ],
    );
  }
  
  // Separate method to build the address field based on state
  Widget _buildAddressField() {
    // Just use a simple text field if there are no addresses
    if (_addresses.isEmpty) {
      return _buildTextFieldFallback();
    }
    
    // Otherwise use the dropdown
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonFormField<String>(
        value: _getValidDropdownValue(),
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: Icon(widget.icon),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          border: InputBorder.none,
        ),
        items: [
          // آدرس‌های ذخیره شده
          ..._addresses.map((address) {
            return DropdownMenuItem<String>(
              value: address.getFullAddress(),
              child: Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          address.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          address.getFullAddress(),
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          
          // گزینه وارد کردن آدرس جدید
          DropdownMenuItem<String>(
            value: 'custom',
            child: Row(
              children: [
                Icon(Icons.edit, size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text('وارد کردن آدرس جدید'),
              ],
            ),
          ),
        ],
        onChanged: (String? value) {
          if (value == 'custom') {
            // نمایش دیالوگ برای ورود آدرس جدید
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(widget.title),
                content: TextField(
                  controller: widget.controller,
                  decoration: InputDecoration(
                    hintText: widget.hint,
                  ),
                  onChanged: (text) {
                    widget.onChanged(text);
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('تایید'),
                  ),
                ],
              ),
            );
          } else if (value != null) {
            setState(() {
              if (_addresses.isNotEmpty) {
                try {
                  _selectedAddress = _addresses.firstWhere(
                    (address) => address.getFullAddress() == value,
                    orElse: () => _addresses.first,
                  );
                } catch (e) {
                  print('Error selecting address: $e');
                }
              }
              widget.controller.text = value;
              widget.onChanged(value);
            });
          }
        },
      ),
    );
  }
  
  // Fallback to a simple TextField when no addresses are available
  Widget _buildTextFieldFallback() {
    return TextFormField(
      controller: widget.controller,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: Icon(widget.icon),
        border: InputBorder.none,
      ),
      onChanged: (value) {
        widget.onChanged(value);
      },
    );
  }
  
  // Method to get a valid dropdown value
  String? _getValidDropdownValue() {
    // Get the current value
    String? currentValue = _selectedAddress?.getFullAddress() ?? widget.initialValue;
    
    // If no value, return null
    if (currentValue == null || _addresses.isEmpty) return null;
    
    // If the value is 'custom', return it (it's already in the items list)
    if (currentValue == 'custom') return currentValue;
    
    // Check if the value exists in the addresses list
    bool valueExists = _addresses.any((address) => address.getFullAddress() == currentValue);
    
    // Return the value if it exists, otherwise null
    return valueExists ? currentValue : null;
  }
} 