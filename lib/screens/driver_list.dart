import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:khatooniiii/models/driver.dart';
import 'package:khatooniiii/screens/driver_form.dart';
import 'dart:io';

class DriverList extends StatelessWidget {
  const DriverList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لیست رانندگان'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Driver>('drivers').listenable(),
        builder: (context, driversBox, _) {
          if (driversBox.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'هنوز هیچ راننده‌ای ثبت نشده است',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const DriverForm()),
                      );
                    },
                    child: const Text('ثبت راننده جدید'),
                  ),
                ],
              ),
            );
          }

          final drivers = driversBox.values.toList();

          return Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 80),
                itemCount: drivers.length,
                itemBuilder: (context, index) {
                  final driver = drivers[index];
                  final hasImage = driver.imagePath != null;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    child: InkWell(
                      onTap: () => _showDriverDetails(context, driver),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            // Driver image or placeholder
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: hasImage ? null : Colors.grey[200],
                                image: hasImage
                                    ? DecorationImage(
                                        image: FileImage(File(driver.imagePath!)),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: hasImage
                                  ? null
                                  : Icon(Icons.person, size: 30, color: Colors.grey[400]),
                            ),
                            const SizedBox(width: 16),
                            // Driver info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    driver.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'شماره موبایل: ${driver.mobile}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  Text(
                                    'کد ملی: ${driver.nationalId}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                            // Action buttons
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DriverForm(driver: driver),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _confirmDelete(context, driver),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              // Center Add Driver Button
              Positioned(
                left: 0,
                right: 0,
                bottom: 16,
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const DriverForm()),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('افزودن راننده'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDriverDetails(BuildContext context, Driver driver) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اطلاعات راننده'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // National card image
              if (driver.imagePath != null) ...[
                const Text('تصویر کارت ملی:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    height: 120,
                    width: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      image: DecorationImage(
                        image: FileImage(File(driver.imagePath!)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // License image
              if (driver.licenseImagePath != null) ...[
                const Text('تصویر گواهینامه:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    height: 120,
                    width: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      image: DecorationImage(
                        image: FileImage(File(driver.licenseImagePath!)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              _buildDetailRow('نام:', driver.firstName),
              _buildDetailRow('نام خانوادگی:', driver.lastName),
              _buildDetailRow('کد ملی:', driver.nationalId),
              _buildDetailRow('شماره موبایل:', driver.mobile),
              _buildDetailRow('شماره گواهینامه:', driver.licenseNumber),
              if (driver.address.isNotEmpty)
                _buildDetailRow('آدرس:', driver.address),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('بستن'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Driver driver) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف راننده'),
        content: const Text('آیا از حذف این راننده اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () {
              driver.delete();
              Navigator.of(context).pop();
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
} 