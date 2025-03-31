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
  String? _selectedValue;

  @override
  void initState() {
    super.initState();
    print('DEBUG: AddressSelector initState for ${widget.title}');
    
    // Initialize with empty state first, then load data
    _addresses = [];
    _isLoading = true;
    
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      widget.controller.text = widget.initialValue!;
      _selectedValue = widget.initialValue;
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
          
          // Try to find the initial address in the loaded addresses
          if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
            for (final address in _addresses) {
              if (address.getFullAddress() == widget.initialValue) {
                _selectedAddress = address;
                break;
              }
            }
          }
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
              _selectedValue = address.getFullAddress();
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

  void _showCustomAddressDialog() {
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
  
  // Simplified address field that won't overflow
  Widget _buildAddressField() {
    // Just use a simple text field if there are no addresses
    if (_addresses.isEmpty) {
      return _buildTextFieldFallback();
    }
    
    // Use a simplified custom dropdown implementation
    return GestureDetector(
      onTap: _showAddressOptions,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(widget.icon, color: Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedValue ?? widget.hint,
                style: TextStyle(
                  color: _selectedValue == null ? Colors.grey : Colors.black,
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 1,
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
  
  // Show address options in a modal bottom sheet to avoid overflow issues
  void _showAddressOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            if (_addresses.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text("هیچ آدرسی یافت نشد. از گزینه 'وارد کردن آدرس جدید' استفاده کنید."),
              ),
            ...List.generate(_addresses.length, (index) {
              final address = _addresses[index];
              return ListTile(
                leading: Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary),
                title: Text(address.title),
                subtitle: Text(
                  address.getFullAddress(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  setState(() {
                    _selectedAddress = address;
                    _selectedValue = address.getFullAddress();
                    widget.controller.text = address.getFullAddress();
                    widget.onChanged(address.getFullAddress());
                  });
                  Navigator.pop(context);
                },
              );
            }),
            const Divider(),
            ListTile(
              leading: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
              title: const Text('وارد کردن آدرس جدید'),
              onTap: () {
                Navigator.pop(context);
                _showCustomAddressDialog();
              },
            ),
          ],
        ),
      ),
    );
  }
  
  // Fallback to a simple TextField when no addresses are available
  Widget _buildTextFieldFallback() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextFormField(
        controller: widget.controller,
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: Icon(widget.icon),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        onChanged: (value) {
          widget.onChanged(value);
        },
      ),
    );
  }
} 