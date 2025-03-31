import 'package:hive/hive.dart';
import 'package:khatooniiii/models/driver_payment.dart';
import 'package:khatooniiii/models/driver_salary.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class HiveMigration {
  // Migrate data to handle type changes
  static Future<void> migrateData() async {
    print("Starting Hive data migration...");
    
    try {
      // Get directory path
      final appDocDir = await getApplicationDocumentsDirectory();
      final hivePath = '${appDocDir.path}/hive';
      
      // Check if we need to run migration (by checking if a marker file exists)
      final migrationMarkerFile = File('$hivePath/migration_v1_complete');
      if (await migrationMarkerFile.exists()) {
        print("Migration already completed. Skipping.");
        return;
      }
      
      // Backup existing data
      await _backupHiveData();
      
      // Delete existing boxes to recreate with new schema
      await _clearDriverPaymentsBox();
      await _clearDriverSalariesBox();
      
      // Create migration marker file
      await migrationMarkerFile.create(recursive: true);
      
      print("Hive data migration completed successfully.");
    } catch (e) {
      print("Error during migration: $e");
    }
  }
  
  // Backup Hive data before migration
  static Future<void> _backupHiveData() async {
    print("Backing up Hive data...");
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final hivePath = '${appDocDir.path}/hive';
      final backupPath = '${appDocDir.path}/hive_backup_${DateTime.now().millisecondsSinceEpoch}';
      
      // Create backup directory
      final backupDir = Directory(backupPath);
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      
      // Copy all files from Hive directory to backup
      final hiveDir = Directory(hivePath);
      if (await hiveDir.exists()) {
        await for (var entity in hiveDir.list(recursive: false, followLinks: false)) {
          if (entity is File) {
            final fileName = entity.path.split('/').last;
            final backupFile = File('$backupPath/$fileName');
            await entity.copy(backupFile.path);
          }
        }
      }
      
      print("Backup completed at: $backupPath");
    } catch (e) {
      print("Error during backup: $e");
    }
  }
  
  // Clear the driver payments box to recreate with new schema
  static Future<void> _clearDriverPaymentsBox() async {
    print("Clearing driverPayments box...");
    try {
      final box = await Hive.openBox<DriverPayment>('driverPayments');
      await box.clear();
      await box.close();
      
      // Delete the box file to ensure clean recreation
      final appDocDir = await getApplicationDocumentsDirectory();
      final boxFile = File('${appDocDir.path}/hive/driverPayments.hive');
      if (await boxFile.exists()) {
        await boxFile.delete();
      }
      
      print("driverPayments box cleared successfully.");
    } catch (e) {
      print("Error clearing driverPayments box: $e");
    }
  }
  
  // Clear the driver salaries box to recreate with new schema
  static Future<void> _clearDriverSalariesBox() async {
    print("Clearing driverSalaries box...");
    try {
      final box = await Hive.openBox<DriverSalary>('driverSalaries');
      await box.clear();
      await box.close();
      
      // Delete the box file to ensure clean recreation
      final appDocDir = await getApplicationDocumentsDirectory();
      final boxFile = File('${appDocDir.path}/hive/driverSalaries.hive');
      if (await boxFile.exists()) {
        await boxFile.delete();
      }
      
      print("driverSalaries box cleared successfully.");
    } catch (e) {
      print("Error clearing driverSalaries box: $e");
    }
  }
} 