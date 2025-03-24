import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:khatooniiii/models/vehicle.dart';
import 'package:khatooniiii/screens/vehicle_form.dart';
import 'package:khatooniiii/widgets/float_button_style.dart';

class VehicleList extends StatelessWidget {
  const VehicleList({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatButtonScaffold.withFloatButton(
      label: 'افزودن وسیله نقلیه',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const VehicleForm()),
        );
      },
      icon: Icons.add,
      tooltip: 'ثبت وسیله نقلیه جدید',
      appBar: AppBar(
        title: const Text('لیست وسایل نقلیه'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Vehicle>('vehicles').listenable(),
        builder: (context, Box<Vehicle> box, _) {
          if (box.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'هیچ وسیله نقلیه‌ای ثبت نشده است',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            );
          }

          final vehicles = box.values.toList();
          
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = vehicles[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: const Icon(Icons.directions_car, color: Colors.blue),
                  ),
                  title: Text(vehicle.vehicleName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('کد: ${vehicle.id ?? "نامشخص"}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VehicleForm(vehicle: vehicle),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 