import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:khatooniiii/models/cargo.dart';
import 'package:intl/intl.dart';

class CargoList extends StatelessWidget {
  const CargoList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لیست سرویس‌ها'),
      ),
      body: ValueListenableBuilder(
      valueListenable: Hive.box<Cargo>('cargos').listenable(),
      builder: (context, Box<Cargo> box, _) {
          final cargos = box.values.toList();
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cargos.length,
            itemBuilder: (context, index) {
              final cargo = cargos[index];
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                                        'راننده: ${cargo.driver.name}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('مبدأ: ${cargo.origin}'),
                      Text('مقصد: ${cargo.destination}'),
                      Text('وزن: ${cargo.weight} کیلوگرم'),
                      Text('هزینه حمل هر تن: ${NumberFormat('#,###').format(cargo.transportCostPerTon)} تومان'),
                      if (cargo.waybillAmount != null)
                        Text('مبلغ بارنامه: ${NumberFormat('#,###').format(cargo.waybillAmount)} تومان'),
              ],
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