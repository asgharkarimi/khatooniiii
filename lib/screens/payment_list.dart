import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:khatooniiii/models/payment.dart';
import 'package:khatooniiii/models/cargo.dart';
import 'package:khatooniiii/screens/payment_form.dart';
import 'package:khatooniiii/utils/number_formatter.dart';
import 'package:intl/intl.dart';
import 'package:khatooniiii/widgets/float_button_style.dart';
import 'package:khatooniiii/utils/date_utils.dart' as date_utils;

class PaymentList extends StatefulWidget {
  const PaymentList({super.key});

  @override
  State<PaymentList> createState() => _PaymentListState();
}

class _PaymentListState extends State<PaymentList> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isGroupedByCargo = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _debugPrintPaymentData(); // Debug function to print payment data
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لیست پرداخت‌ها'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'بروزرسانی',
              onPressed: () {
                setState(() {
                  // Force UI refresh
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('لیست پرداخت‌ها بروزرسانی شد'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'ثبت پرداخت جدید',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PaymentForm()),
                );
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'بر اساس سرویس', icon: Icon(Icons.local_shipping)),
              Tab(text: 'همه پرداخت‌ها', icon: Icon(Icons.payments)),
            ],
            labelColor: Colors.white,
            indicatorColor: Colors.white,
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Grouped by cargo
            FutureBuilder<List<Cargo>>(
              future: _loadCargos(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('در حال بارگذاری سرویس‌ها...'),
                      ],
                    ),
                  );
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red),
                        SizedBox(height: 16),
                        Text('خطا در بارگذاری: ${snapshot.error}'),
                      ],
                    ),
                  );
                }
                
                return _buildGroupedPaymentsList(Hive.box<Payment>('payments'));
              },
            ),
            
            // Tab 2: All payments chronologically
            _buildAllPaymentsList(Hive.box<Payment>('payments')),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PaymentForm()),
            );
          },
          label: const Text('ثبت پرداخت جدید'),
          icon: const Icon(Icons.add),
          backgroundColor: Colors.blue[800],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Future<List<Cargo>> _loadCargos() async {
    try {
      final box = await Hive.openBox<Cargo>('cargos');
      return box.values.toList();
    } catch (e) {
      throw Exception('خطا در بارگذاری سرویس‌ها: $e');
    }
  }

  Widget _buildGroupedPaymentsList(Box<Payment> box) {
    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, Box<Payment> box, _) {
        final payments = box.values.toList();
        
        if (payments.isEmpty) {
          return const Center(
            child: Text('هیچ پرداختی ثبت نشده است'),
          );
        }
        
        // Group payments by cargo
        final Map<dynamic, List<Payment>> paymentsByCargo = {};
        for (var payment in payments) {
          final cargoKey = payment.cargo.key;
          if (!paymentsByCargo.containsKey(cargoKey)) {
            paymentsByCargo[cargoKey] = [];
          }
          paymentsByCargo[cargoKey]!.add(payment);
        }
        
        // Sort cargo keys by the most recent payment
        final sortedCargoKeys = paymentsByCargo.keys.toList()
          ..sort((a, b) {
            final aDate = paymentsByCargo[a]!
                .reduce((curr, next) => 
                    curr.paymentDate.isAfter(next.paymentDate) ? curr : next)
                .paymentDate;
            final bDate = paymentsByCargo[b]!
                .reduce((curr, next) => 
                    curr.paymentDate.isAfter(next.paymentDate) ? curr : next)
                .paymentDate;
            return bDate.compareTo(aDate); // newest first
          });

        return ListView.builder(
          itemCount: sortedCargoKeys.length,
          itemBuilder: (context, index) {
            final cargoKey = sortedCargoKeys[index];
            final cargoPayments = paymentsByCargo[cargoKey]!;
            
            // Sort payments by date (newest first)
            cargoPayments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
            
            final cargo = cargoPayments.first.cargo;
            final totalPaid = cargoPayments.fold<double>(0, (sum, payment) => sum + payment.amount);
            
            return Card(
              margin: const EdgeInsets.all(8),
              elevation: 3,
              child: ExpansionTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'سرویس: ${cargo.cargoType.cargoName}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (cargo.totalPrice - totalPaid) <= 0 
                          ? Colors.green[100] 
                          : (totalPaid > 0 ? Colors.orange[100] : Colors.red[100]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(totalPaid / cargo.totalPrice * 100).toInt()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: (cargo.totalPrice - totalPaid) <= 0 
                            ? Colors.green[700] 
                            : (totalPaid > 0 ? Colors.orange[700] : Colors.red[700]),
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مسیر: ${cargo.origin} به ${cargo.destination}'),
                    Text('راننده: ${cargo.driver.firstName} ${cargo.driver.lastName}'),
                    Text('شناسه سرویس: ${cargo.id ?? cargo.key}', 
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'مجموع پرداختی: ${NumberFormat('#,###', 'fa_IR').format(totalPaid)} تومان',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                        Text(
                          'قیمت کل: ${NumberFormat('#,###', 'fa_IR').format(cargo.totalPrice)} تومان',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.payments, color: Colors.green),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'مجموع پرداختی به این سرویس:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${NumberFormat('#,###', 'fa_IR').format(totalPaid)} تومان',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                  color: Colors.green[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'از',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${NumberFormat('#,###', 'fa_IR').format(cargo.totalPrice)} تومان',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (totalPaid >= cargo.totalPrice)
                                          ? Colors.green[100]
                                          : (totalPaid > 0 ? Colors.orange[100] : Colors.red[100]),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${(totalPaid / cargo.totalPrice * 100).toInt()}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: (totalPaid >= cargo.totalPrice)
                                            ? Colors.green[700]
                                            : (totalPaid > 0 ? Colors.orange[700] : Colors.red[700]),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        ...cargoPayments.map((payment) => Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _getPaymentTypeColor(payment.paymentType).withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getPaymentTypeIcon(payment.paymentType),
                                    color: _getPaymentTypeColor(payment.paymentType),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${formatNumber(payment.amount)} تومان',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            'تاریخ: ${date_utils.AppDateUtils.toPersianDate(payment.paymentDate)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'شناسه سرویس: ${payment.cargo.id ?? payment.cargo.key}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getPaymentTypeColor(payment.paymentType).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _getPaymentTypeText(payment.paymentType),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _getPaymentTypeColor(payment.paymentType),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.more_vert, size: 18),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(8),
                                  onPressed: () => _showPaymentDetails(payment, box),
                                ),
                              ],
                            ),
                          ),
                        )),
                        const Divider(),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.receipt_long, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  'لیست پرداخت‌ها',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${cargoPayments.length} پرداخت',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'مبلغ کل سرویس:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${NumberFormat('#,###', 'fa_IR').format(cargo.totalPrice)} تومان',
                                    style: TextStyle(
                                      color: Colors.blue[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'پرداخت شده:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${NumberFormat('#,###', 'fa_IR').format(totalPaid)} تومان',
                                    style: TextStyle(
                                      color: totalPaid > 0 ? Colors.green[700] : Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'مانده:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${NumberFormat('#,###', 'fa_IR').format(cargo.totalPrice - totalPaid)} تومان',
                                    style: TextStyle(
                                      color: (cargo.totalPrice - totalPaid) <= 0
                                          ? Colors.green[700]
                                          : Colors.red[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'وضعیت پرداخت:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (cargo.totalPrice - totalPaid) <= 0
                                          ? Colors.green[100]
                                          : (totalPaid > 0 ? Colors.orange[100] : Colors.red[100]),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      (cargo.totalPrice - totalPaid) <= 0
                                          ? 'تسویه شده'
                                          : (totalPaid > 0 ? 'پرداخت ناقص' : 'پرداخت نشده'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: (cargo.totalPrice - totalPaid) <= 0
                                            ? Colors.green[700]
                                            : (totalPaid > 0 ? Colors.orange[700] : Colors.red[700]),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: cargo.totalPrice > 0 ? (totalPaid / cargo.totalPrice).clamp(0.0, 1.0) : 0,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    (cargo.totalPrice - totalPaid) <= 0
                                      ? Colors.green
                                      : (totalPaid / cargo.totalPrice) > 0.5
                                        ? Colors.orange
                                        : Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PaymentForm(cargo: cargo),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('افزودن پرداخت جدید'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[800],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAllPaymentsList(Box<Payment> box) {
    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, Box<Payment> box, _) {
        final payments = box.values.toList();
        
        if (payments.isEmpty) {
          return const Center(
            child: Text('هیچ پرداختی ثبت نشده است'),
          );
        }
        
        // مرتب‌سازی پرداخت‌ها بر اساس تاریخ (جدیدترین اول)
        payments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
        
        // محاسبه جمع کل پرداخت‌ها
        final totalPayments = payments.fold<double>(0, (sum, payment) => sum + payment.amount);
        
        return Column(
          children: [
            // کارت نمایش مجموع کل پرداخت‌ها
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.attach_money, color: Colors.green[700]),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'مجموع کل پرداخت‌ها:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${NumberFormat('#,###', 'fa_IR').format(totalPayments)} تومان',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // لیست پرداخت‌ها
            Expanded(
              child: ListView.builder(
                itemCount: payments.length,
                itemBuilder: (context, index) {
                  final payment = payments[index];
                  return _buildPaymentListItem(payment, box);
                },
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildPaymentListItem(Payment payment, Box<Payment> box) {
    return Dismissible(
      key: Key(payment.key.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) {
        box.delete(payment.key);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('پرداخت با موفقیت حذف شد')),
        );
      },
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('حذف پرداخت'),
              content: const Text('آیا از حذف این پرداخت اطمینان دارید؟'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('انصراف'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('حذف'),
                ),
              ],
            );
          },
        );
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getPaymentTypeColor(payment.paymentType).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getPaymentTypeIcon(payment.paymentType),
              color: _getPaymentTypeColor(payment.paymentType),
              size: 24,
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${formatNumber(payment.amount)} تومان',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getPaymentTypeColor(payment.paymentType).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getPaymentTypeText(payment.paymentType),
                      style: TextStyle(
                        fontSize: 11,
                        color: _getPaymentTypeColor(payment.paymentType),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'سرویس: ${payment.cargo.cargoType.cargoName}',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'شناسه سرویس: ${payment.cargo.id ?? payment.cargo.key}',
                style: TextStyle(fontSize: 12, color: Colors.blue[700], fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          subtitle: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'تاریخ: ${date_utils.AppDateUtils.toPersianDate(payment.paymentDate)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              Text(
                payment.cargo.origin.isNotEmpty && payment.cargo.destination.isNotEmpty
                    ? '${payment.cargo.origin} به ${payment.cargo.destination}'
                    : '',
                style: TextStyle(fontSize: 12, color: Colors.grey[700], fontStyle: FontStyle.italic),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          onTap: () {
            _showPaymentDetails(payment, box);
          },
        ),
      ),
    );
  }
  
  IconData _getPaymentTypeIcon(int paymentType) {
    switch (paymentType) {
      case PaymentType.cash:
        return Icons.money;
      case PaymentType.check:
        return Icons.money_off;
      case PaymentType.bankTransfer:
        return Icons.account_balance;
      case PaymentType.cardToCard:
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }
  
  String _getPaymentTypeText(int paymentType) {
    switch (paymentType) {
      case PaymentType.cash:
        return 'نقدی';
      case PaymentType.check:
        return 'چک';
      case PaymentType.bankTransfer:
        return 'انتقال بانکی';
      case PaymentType.cardToCard:
        return 'کارت به کارت';
      default:
        return 'نامشخص';
    }
  }

  Color _getPaymentTypeColor(int paymentType) {
    switch (paymentType) {
      case PaymentType.cash:
        return Colors.green;
      case PaymentType.cardToCard:
        return Colors.blue;
      case PaymentType.check:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _showPaymentDetails(Payment payment, Box<Payment> box) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('جزئیات پرداخت', style: TextStyle(fontSize: 18)),
              Icon(Icons.payment, color: Colors.blue),
            ],
          ),
          content: SingleChildScrollView(
            child: Container(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('مبلغ', '${formatNumber(payment.amount)} تومان', 
                    icon: Icons.money, iconColor: Colors.green),
                  const Divider(),
                  _buildDetailRow('تاریخ پرداخت', date_utils.AppDateUtils.toPersianDate(payment.paymentDate), 
                    icon: Icons.calendar_today, iconColor: Colors.orange),
                  const Divider(),
                  _buildDetailRow('نوع پرداخت', _getPaymentTypeText(payment.paymentType), 
                    icon: _getPaymentTypeIcon(payment.paymentType), 
                    iconColor: _getPaymentTypeColor(payment.paymentType)),
                  const Divider(),
                  if (payment.customer != null) ...[
                    _buildDetailRow('پرداخت کننده', '${payment.customer.firstName} ${payment.customer.lastName}', 
                      icon: Icons.person, iconColor: Colors.blue),
                    const Divider(),
                  ],
                  _buildDetailRow('سرویس', 
                    '${payment.cargo.cargoType.cargoName} - ${payment.cargo.origin} به ${payment.cargo.destination}', 
                    icon: Icons.local_shipping, iconColor: Colors.purple),
                  const Divider(),
                  _buildDetailRow('شناسه سرویس', 
                    '${payment.cargo.id ?? payment.cargo.key}', 
                    icon: Icons.numbers, iconColor: Colors.blue),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('بستن'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _editPayment(payment, box);
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, size: 16),
                  SizedBox(width: 4),
                  Text('ویرایش'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String title, String value, {required IconData icon, required Color iconColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editPayment(Payment payment, Box<Payment> box) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentForm(payment: payment),
      ),
    );
  }

  // Debug function to print payment data to console
  void _debugPrintPaymentData() async {
    final paymentsBox = await Hive.openBox<Payment>('payments');
    final payments = paymentsBox.values.toList();
    
    print('\n=== DEBUG: PAYMENT LIST DATA ===');
    print('Total payments: ${payments.length}');
    
    if (payments.isEmpty) {
      print('No payments found in database.');
      return;
    }
    
    // Group payments by cargo
    Map<int, List<Payment>> paymentsByCargo = {};
    for (var payment in payments) {
      if (payment.cargo != null) {
        final cargoKey = payment.cargo.key;
        if (!paymentsByCargo.containsKey(cargoKey)) {
          paymentsByCargo[cargoKey] = [];
        }
        paymentsByCargo[cargoKey]!.add(payment);
      }
    }
    
    // Print payments grouped by cargo
    print('\n--- PAYMENTS BY CARGO ---');
    
    paymentsByCargo.forEach((cargoKey, cargoPayments) {
      final cargo = cargoPayments.first.cargo;
      final totalPaid = cargoPayments.fold<double>(0, (sum, payment) => sum + payment.amount);
      final remaining = cargo.totalPrice - totalPaid;
      
      print('\nCargo #$cargoKey: ${cargo.cargoType.cargoName}');
      print('  Cargo ID: ${cargo.id ?? "Not set"}');
      print('  Route: ${cargo.origin} to ${cargo.destination}');
      print('  Driver: ${cargo.driver.firstName} ${cargo.driver.lastName}');
      print('  Driver ID: ${cargo.driver.id}');
      print('  Total price: ${cargo.totalPrice} (Paid: $totalPaid, Remaining: $remaining)');
      print('  Payments:');
      
      for (var i = 0; i < cargoPayments.length; i++) {
        final payment = cargoPayments[i];
        final type = _getPaymentTypeText(payment.paymentType);
        final date = payment.paymentDate.toString();
        print('    ${i+1}. Amount: ${payment.amount} - Type: $type - Date: $date');
      }
    });
    
    // Print driver salaries information
    print('\n--- DRIVER SALARIES ---');
    try {
      // Import and use correctly typed box
      final driverSalariesBox = await Hive.openBox<dynamic>('driverSalaries');
      final driverSalaries = driverSalariesBox.values.toList();
      
      print('Total driver salaries records: ${driverSalaries.length}');
      
      for (var i = 0; i < driverSalaries.length; i++) {
        final salary = driverSalaries[i];
        print('\nDriver Salary #${i+1}:');
        try {
          // Access fields with careful null handling
          print('  Payment ID: ${salary.id}');
          print('  Driver Name: ${_tryGetValue(() => "${salary.driver?.firstName ?? ""} ${salary.driver?.lastName ?? ""}", "Unknown")}');
          print('  Amount: ${_tryGetValue(() => salary.amount, "Unknown")}');
          print('  Payment Date: ${_tryGetValue(() => salary.paymentDate, "Unknown")}');
          print('  Payment Method: ${_tryGetValue(() => salary.paymentMethod, "Unknown")}');
          
          // Try to print cargo information
          if (salary.cargo != null) {
            print('  Associated Cargo Info:');
            print('    Cargo ID: ${_tryGetValue(() => salary.cargo?.id, "Unknown")}');
            print('    Cargo Key: ${_tryGetValue(() => salary.cargo?.key, "Unknown")}');
            print('    Cargo Type: ${_tryGetValue(() => salary.cargo?.cargoType?.cargoName, "Unknown")}');
            print('    Origin-Destination: ${_tryGetValue(() => "${salary.cargo?.origin} to ${salary.cargo?.destination}", "Unknown")}');
          } else {
            print('  No cargo associated with this payment');
          }
          
          // Print financial information
          print('  Calculated Salary: ${_tryGetValue(() => salary.calculatedSalary, "Not set")}');
          print('  Total Paid Amount: ${_tryGetValue(() => salary.totalPaidAmount, "Not set")}');
          print('  Remaining Amount: ${_tryGetValue(() => salary.remainingAmount, "Not set")}');
        } catch (e) {
          print('  Error accessing salary details: $e');
        }
      }
    } catch (e) {
      print('Error fetching driver salaries: $e');
    }
    
    // Print all payments chronologically
    print('\n--- ALL PAYMENTS CHRONOLOGICALLY ---');
    payments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    
    for (var i = 0; i < payments.length; i++) {
      final payment = payments[i];
      final type = _getPaymentTypeText(payment.paymentType);
      final date = payment.paymentDate.toString();
      print('${i+1}. Amount: ${payment.amount} - Type: $type - Date: $date - Cargo: ${payment.cargo.cargoType.cargoName}');
    }
    
    print('\n=== END DEBUG DATA ===\n');
  }
  
  // Helper function for safe access to potentially missing properties
  T _tryGetValue<T>(T Function() getValue, T defaultValue) {
    try {
      return getValue();
    } catch (e) {
      return defaultValue;
    }
  }
} 