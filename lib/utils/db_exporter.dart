import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:khatooniiii/models/cargo.dart';
import 'package:khatooniiii/models/driver.dart';
import 'package:khatooniiii/models/vehicle.dart';
import 'package:khatooniiii/models/customer.dart';
import 'package:khatooniiii/models/payment.dart';
import 'package:khatooniiii/models/cargo_type.dart';
import 'package:khatooniiii/models/expense.dart';

class DbExporter {
  
  /// Export Hive database structure as a JSON file
  static Future<String> exportDbStructure() async {
    final Map<String, dynamic> dbStructure = {
      'boxes': [],
      'typeIds': {},
      'relationships': [],
    };
    
    // Add boxes structure
    final boxNames = ['cargos', 'drivers', 'vehicles', 'customers', 'payments', 'cargoTypes', 'expenses'];
    
    for (var boxName in boxNames) {
      Map<String, dynamic> boxStructure = {'name': boxName, 'fields': []};
      
      if (boxName == 'cargos') {
        final cargoTypeId = getHiveTypeId(Cargo);
        dbStructure['typeIds']['Cargo'] = cargoTypeId;
        boxStructure['typeId'] = cargoTypeId;
        boxStructure['fields'] = [
          {'name': 'id', 'type': 'int?', 'hiveFieldId': 0},
          {'name': 'vehicle', 'type': 'Vehicle', 'hiveFieldId': 1, 'relationship': 'vehicles'},
          {'name': 'driver', 'type': 'Driver', 'hiveFieldId': 2, 'relationship': 'drivers'},
          {'name': 'cargoType', 'type': 'CargoType', 'hiveFieldId': 3, 'relationship': 'cargoTypes'},
          {'name': 'origin', 'type': 'String', 'hiveFieldId': 4},
          {'name': 'destination', 'type': 'String', 'hiveFieldId': 5},
          {'name': 'date', 'type': 'DateTime', 'hiveFieldId': 6},
          {'name': 'weight', 'type': 'double', 'hiveFieldId': 7},
          {'name': 'pricePerTon', 'type': 'double', 'hiveFieldId': 8},
          {'name': 'paymentStatus', 'type': 'int', 'hiveFieldId': 9},
          {'name': 'transportCostPerTon', 'type': 'double', 'hiveFieldId': 10},
        ];
        
        // Add relationships
        dbStructure['relationships'].add({
          'from': 'cargos',
          'to': 'vehicles',
          'type': 'many-to-one',
          'field': 'vehicle'
        });
        
        dbStructure['relationships'].add({
          'from': 'cargos',
          'to': 'drivers',
          'type': 'many-to-one',
          'field': 'driver'
        });
        
        dbStructure['relationships'].add({
          'from': 'cargos',
          'to': 'cargoTypes',
          'type': 'many-to-one',
          'field': 'cargoType'
        });
      }
      
      else if (boxName == 'drivers') {
        final driverTypeId = getHiveTypeId(Driver);
        dbStructure['typeIds']['Driver'] = driverTypeId;
        boxStructure['typeId'] = driverTypeId;
        boxStructure['fields'] = [
          {'name': 'id', 'type': 'int?', 'hiveFieldId': 0},
          {'name': 'name', 'type': 'String', 'hiveFieldId': 1},
          {'name': 'mobile', 'type': 'String', 'hiveFieldId': 2},
        ];
      }
      
      else if (boxName == 'vehicles') {
        final vehicleTypeId = getHiveTypeId(Vehicle);
        dbStructure['typeIds']['Vehicle'] = vehicleTypeId;
        boxStructure['typeId'] = vehicleTypeId;
        boxStructure['fields'] = [
          {'name': 'id', 'type': 'int?', 'hiveFieldId': 0},
          {'name': 'vehicleName', 'type': 'String', 'hiveFieldId': 1},
        ];
      }
      
      else if (boxName == 'customers') {
        final customerTypeId = getHiveTypeId(Customer);
        dbStructure['typeIds']['Customer'] = customerTypeId;
        boxStructure['typeId'] = customerTypeId;
        boxStructure['fields'] = [
          {'name': 'id', 'type': 'int?', 'hiveFieldId': 0},
          {'name': 'firstName', 'type': 'String', 'hiveFieldId': 1},
          {'name': 'lastName', 'type': 'String', 'hiveFieldId': 2},
          {'name': 'phone', 'type': 'String', 'hiveFieldId': 3},
        ];
      }
      
      else if (boxName == 'payments') {
        final paymentTypeId = getHiveTypeId(Payment);
        dbStructure['typeIds']['Payment'] = paymentTypeId;
        boxStructure['typeId'] = paymentTypeId;
        boxStructure['fields'] = [
          {'name': 'id', 'type': 'int?', 'hiveFieldId': 0},
          {'name': 'paymentType', 'type': 'int', 'hiveFieldId': 1},
          {'name': 'payerType', 'type': 'int', 'hiveFieldId': 2},
          {'name': 'customer', 'type': 'Customer', 'hiveFieldId': 3, 'relationship': 'customers'},
          {'name': 'cargo', 'type': 'Cargo', 'hiveFieldId': 4, 'relationship': 'cargos'},
          {'name': 'amount', 'type': 'double', 'hiveFieldId': 5},
          {'name': 'cardToCardReceiptImagePath', 'type': 'String?', 'hiveFieldId': 6},
          {'name': 'checkImagePath', 'type': 'String?', 'hiveFieldId': 7},
          {'name': 'checkDueDate', 'type': 'DateTime?', 'hiveFieldId': 8},
          {'name': 'paymentDate', 'type': 'DateTime', 'hiveFieldId': 9},
        ];
        
        // Add relationships
        dbStructure['relationships'].add({
          'from': 'payments',
          'to': 'customers',
          'type': 'many-to-one',
          'field': 'customer'
        });
        
        dbStructure['relationships'].add({
          'from': 'payments',
          'to': 'cargos',
          'type': 'many-to-one',
          'field': 'cargo'
        });
      }
      
      else if (boxName == 'cargoTypes') {
        final cargoTypeTypeId = getHiveTypeId(CargoType);
        dbStructure['typeIds']['CargoType'] = cargoTypeTypeId;
        boxStructure['typeId'] = cargoTypeTypeId;
        boxStructure['fields'] = [
          {'name': 'id', 'type': 'int?', 'hiveFieldId': 0},
          {'name': 'cargoName', 'type': 'String', 'hiveFieldId': 1},
        ];
      }
      
      else if (boxName == 'expenses') {
        final expenseTypeId = getHiveTypeId(Expense);
        dbStructure['typeIds']['Expense'] = expenseTypeId;
        boxStructure['typeId'] = expenseTypeId;
        boxStructure['fields'] = [
          {'name': 'id', 'type': 'int?', 'hiveFieldId': 0},
          {'name': 'title', 'type': 'String', 'hiveFieldId': 1},
          {'name': 'amount', 'type': 'double', 'hiveFieldId': 2},
          {'name': 'date', 'type': 'DateTime', 'hiveFieldId': 3},
          {'name': 'description', 'type': 'String?', 'hiveFieldId': 4},
        ];
      }
      
      dbStructure['boxes'].add(boxStructure);
    }
    
    // Add additional Hive type IDs
    dbStructure['typeIds']['PaymentType'] = 6;
    dbStructure['typeIds']['PayerType'] = 7;
    
    // Export to JSON file
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/hive_db_structure.json';
    final jsonString = jsonEncode(dbStructure);
    final file = File(filePath);
    await file.writeAsString(jsonString, flush: true);
    
    return filePath;
  }
  
  /// Display Hive database structure in a dialog
  static void showDbStructure(BuildContext context) async {
    try {
      final filePath = await exportDbStructure();
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final dbStructure = jsonDecode(jsonString);
      
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Container(
            width: double.maxFinite,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Hive Database Structure',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Boxes:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        for (var box in dbStructure['boxes'])
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('- ${box['name']} (typeId: ${box['typeId']})', 
                                style: const TextStyle(fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (var field in box['fields'])
                                      Text('${field['name']}: ${field['type']} (field: ${field['hiveFieldId']})'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        const SizedBox(height: 16),
                        const Text('Relationships:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        for (var rel in dbStructure['relationships'])
                          Text('- ${rel['from']} -> ${rel['to']} (${rel['type']})'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Export path: $filePath', 
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
  
  // Helper method to get type ID from Hive annotations (in a real app, you might need reflection capabilities)
  static int getHiveTypeId(Type type) {
    switch (type) {
      case Cargo: return 0;
      case Driver: return 2;
      case Vehicle: return 1;
      case Customer: return 3;
      case Payment: return 8;
      case CargoType: return 4;
      case Expense: return 5;
      default: return -1;
    }
  }
} 