import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:khatooniiii/models/driver.dart';
import 'package:khatooniiii/models/vehicle.dart';
import 'package:khatooniiii/models/cargo_type.dart';
import 'package:khatooniiii/models/customer.dart';
import 'package:khatooniiii/models/cargo.dart';
import 'package:khatooniiii/models/payment.dart';
import 'package:khatooniiii/models/expense.dart';
import 'package:khatooniiii/screens/home_screen.dart';
import 'package:khatooniiii/theme/app_theme.dart';
import 'package:khatooniiii/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Reset Hive database if schema has changed
  await _resetHiveIfNeeded();
  
  await Hive.initFlutter();
  
  // Register Hive adapters
  Hive.registerAdapter(DriverAdapter());
  Hive.registerAdapter(VehicleAdapter());
  Hive.registerAdapter(CargoTypeAdapter());
  Hive.registerAdapter(CustomerAdapter());
  Hive.registerAdapter(CargoAdapter());
  Hive.registerAdapter(PaymentAdapter());
  Hive.registerAdapter(ExpenseAdapter());

  // Open Hive boxes
  await Hive.openBox<Driver>('drivers');
  await Hive.openBox<Vehicle>('vehicles');
  await Hive.openBox<CargoType>('cargoTypes');
  await Hive.openBox<Customer>('customers');
  await Hive.openBox<Cargo>('cargos');
  await Hive.openBox<Payment>('payments');
  await Hive.openBox<Expense>('expenses');

  // Run migration to ensure all Cargo objects have transportCostPerTon set
  await _migrateCargoObjects();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

// مهاجرت داده‌های قدیمی برای اطمینان از اینکه همه اشیاء Cargo دارای مقدار پیش‌فرض برای transportCostPerTon هستند
Future<void> _migrateCargoObjects() async {
  final cargosBox = Hive.box<Cargo>('cargos');
  
  for (int i = 0; i < cargosBox.length; i++) {
    final cargo = cargosBox.getAt(i);
    
    // If cargo exists, ensure transportCostPerTon is not null
    if (cargo != null) {
      try {
        // Access the field to check if it causes an error
        cargo.transportCostPerTon;
      } catch (e) {
        // If there's an error, the field was null or didn't exist
        // We need to replace the cargo object with a new one that includes the field
        final updatedCargo = Cargo(
          id: cargo.id,
          vehicle: cargo.vehicle,
          driver: cargo.driver,
          cargoType: cargo.cargoType,
          origin: cargo.origin,
          destination: cargo.destination,
          date: cargo.date,
          weight: cargo.weight,
          pricePerTon: cargo.pricePerTon,
          paymentStatus: cargo.paymentStatus,
          transportCostPerTon: 0, // Set default value
        );
        
        // Put the updated object back in the same position
        cargosBox.putAt(i, updatedCargo);
      }
    }
  }
}

// Check if we need to reset the Hive database
Future<void> _resetHiveIfNeeded() async {
  final appDocDir = await getApplicationDocumentsDirectory();
  final appDbDir = Directory('${appDocDir.path}/database_version.txt');
  
  // Current database version - increment this when schema changes
  const currentVersion = '1.1';
  
  try {
    if (await appDbDir.exists()) {
      final versionFile = File('${appDocDir.path}/database_version.txt');
      final savedVersion = await versionFile.readAsString();
      
      if (savedVersion != currentVersion) {
        // Version mismatch - delete database
        await _deleteHiveFiles();
        await versionFile.writeAsString(currentVersion);
      }
    } else {
      // First run - create version file
      final versionFile = File('${appDocDir.path}/database_version.txt');
      await versionFile.create(recursive: true);
      await versionFile.writeAsString(currentVersion);
    }
  } catch (e) {
    print('Error checking database version: $e');
    // On error, recreate database to be safe
    await _deleteHiveFiles();
    
    final versionFile = File('${appDocDir.path}/database_version.txt');
    await versionFile.create(recursive: true);
    await versionFile.writeAsString(currentVersion);
  }
}

// Delete all Hive database files
Future<void> _deleteHiveFiles() async {
  final appDocDir = await getApplicationDocumentsDirectory();
  final appHiveDir = Directory('${appDocDir.path}/hive');
  
  if (await appHiveDir.exists()) {
    await appHiveDir.delete(recursive: true);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'سامانه خاتون بار',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          locale: const Locale('fa', 'IR'),
          builder: (context, child) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            );
          },
          home: const HomeScreen(),
        );
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: const Text('Home Page'),
      ),
      body: const Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Text('Hello, World!'),
      ),
    );
  }
}



// echo "# khatooniiii" >> README.md
// git init
// git add README.md
// git commit -m "first commit"
// git branch -M main
// git remote add origin https://github.com/asgharkarimi/khatooniiii.git
// git push -u origin main