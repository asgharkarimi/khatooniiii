import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:khatooniiii/models/freight.dart';
import 'package:khatooniiii/screens/cargo_form.dart';

class FreightScreen extends StatefulWidget {
  const FreightScreen({super.key});

  @override
  State<FreightScreen> createState() => _FreightScreenState();
}

class _FreightScreenState extends State<FreightScreen> {
  final _formKey = GlobalKey<FormState>();
  final _freightNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  
  List<Freight> _freightCompanies = [];
  
  @override
  void initState() {
    super.initState();
    _loadFreightCompanies();
  }
  
  Future<void> _loadFreightCompanies() async {
    final box = Hive.box<Freight>('freights');
    setState(() {
      _freightCompanies = box.values.toList();
    });
  }

  @override
  void dispose() {
    _freightNameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Save to Hive
        final box = Hive.box<Freight>('freights');
        
        // Find max ID for new freight
        int maxId = 0;
        for (final freight in box.values) {
          if (freight.id != null && freight.id! > maxId) {
            maxId = freight.id!;
          }
        }
        
        final freight = Freight(
          id: maxId + 1,
          name: _freightNameController.text.trim(),
          phoneNumber: _phoneNumberController.text.trim(),
        );
        
        await box.add(freight);
        
        // Update the list
        await _loadFreightCompanies();
        
        // Reset form
        _freightNameController.clear();
        _phoneNumberController.clear();
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('اطلاعات باربری با موفقیت ثبت شد')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطا در ثبت اطلاعات: $e')),
          );
        }
      }
    }
  }

  void _navigateToCargoForm(Freight? selectedFreight) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CargoForm(
          preSelectedFreight: selectedFreight,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ثبت باربری'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _freightNameController,
                        decoration: InputDecoration(
                          labelText: 'نام باربری',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.business),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'لطفاً نام باربری را وارد کنید';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneNumberController,
                        decoration: InputDecoration(
                          labelText: 'شماره تماس',
                          hintText: 'مثال: 09123456789',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'لطفاً شماره تماس را وارد کنید';
                          }
                          // Add more validation if needed
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
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
                          ),
                          child: const Text(
                            'ثبت اطلاعات',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            if (_freightCompanies.isNotEmpty) ...[
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
                        'انتخاب باربری و ثبت سرویس بار',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'باربری موردنظر خود را انتخاب کنید:',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _freightCompanies.length,
                        itemBuilder: (context, index) {
                          final freight = _freightCompanies[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(freight.name),
                              subtitle: Text('شماره تماس: ${freight.phoneNumber}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.arrow_forward),
                                onPressed: () => _navigateToCargoForm(freight),
                              ),
                              onTap: () => _navigateToCargoForm(freight),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToCargoForm(null),
                icon: const Icon(Icons.add),
                label: const Text('ثبت سرویس بار بدون انتخاب باربری'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}