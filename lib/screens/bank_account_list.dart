import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:khatooniiii/models/bank_account.dart';
import 'package:khatooniiii/screens/bank_account_form.dart';

class BankAccountList extends StatefulWidget {
  const BankAccountList({super.key});

  @override
  State<BankAccountList> createState() => _BankAccountListState();
}

class _BankAccountListState extends State<BankAccountList> {
  List<BankAccount> _accounts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final box = await Hive.openBox<BankAccount>('bankAccounts');
      setState(() {
        _accounts = box.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در بارگیری اطلاعات: $e')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addAccount() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BankAccountForm()),
    );

    if (result == true) {
      _loadAccounts();
    }
  }

  void _editAccount(BankAccount account) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BankAccountForm(account: account)),
    );

    if (result == true) {
      _loadAccounts();
    }
  }

  Future<void> _deleteAccount(BankAccount account) async {
    try {
      await account.delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حساب بانکی با موفقیت حذف شد')),
        );
      }
      
      await _loadAccounts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در حذف حساب بانکی: $e')),
        );
      }
    }
  }

  void _showDeleteDialog(BankAccount account) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('حذف حساب بانکی'),
          content: Text('آیا از حذف حساب "${account.title}" اطمینان دارید؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('انصراف'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAccount(account);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت حساب‌های بانکی'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAccounts,
            tooltip: 'به‌روزرسانی',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _accounts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'هیچ حساب بانکی ثبت نشده است',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'برای افزودن حساب بانکی جدید روی دکمه زیر کلیک کنید',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _addAccount,
                        icon: const Icon(Icons.add_card),
                        label: const Text('افزودن حساب بانکی جدید'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // هدر لیست
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.account_balance,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'تعداد حساب‌های بانکی: ${_accounts.length}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            OutlinedButton.icon(
                              onPressed: _addAccount,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('جدید'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // لیست حساب‌ها
                      Expanded(
                        child: ListView.builder(
                          itemCount: _accounts.length,
                          itemBuilder: (context, index) {
                            final account = _accounts[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: account.isDefault
                                    ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
                                    : BorderSide.none,
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                title: Row(
                                  children: [
                                    Icon(
                                      Icons.credit_card,
                                      color: Theme.of(context).colorScheme.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      account.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    if (account.isDefault) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          'پیش‌فرض',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.account_balance, size: 16, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(account.bankName),
                                        const SizedBox(width: 12),
                                        const Icon(Icons.person, size: 16, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(account.ownerName),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    if (account.cardNumber != null && account.cardNumber!.isNotEmpty) ...[
                                      Row(
                                        children: [
                                          const Icon(Icons.credit_card, size: 16, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatCardNumber(account.cardNumber!),
                                            style: const TextStyle(
                                              fontFamily: 'monospace',
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                    ],
                                    if (account.sheba != null && account.sheba!.isNotEmpty) ...[
                                      Row(
                                        children: [
                                          const Icon(Icons.confirmation_number, size: 16, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatSheba(account.sheba!),
                                            style: const TextStyle(
                                              fontFamily: 'monospace',
                                              letterSpacing: 1,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _editAccount(account),
                                      tooltip: 'ویرایش',
                                      iconSize: 22,
                                      constraints: const BoxConstraints(
                                        minWidth: 36,
                                        minHeight: 36,
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _showDeleteDialog(account),
                                      tooltip: 'حذف',
                                      iconSize: 22,
                                      constraints: const BoxConstraints(
                                        minWidth: 36,
                                        minHeight: 36,
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                                onTap: () => _editAccount(account),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: _accounts.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: _addAccount,
              tooltip: 'افزودن حساب بانکی',
              child: const Icon(Icons.add_card),
            ),
    );
  }
  
  String _formatCardNumber(String cardNumber) {
    // اگر شماره کارت از قبل فرمت‌دهی شده باشد، همان را برگردان
    if (cardNumber.contains('-')) {
      return cardNumber;
    }
    
    // فرمت‌دهی به صورت XXXX-XXXX-XXXX-XXXX
    String formatted = '';
    for (int i = 0; i < cardNumber.length; i++) {
      if (i > 0 && i % 4 == 0 && i < 16) {
        formatted += '-';
      }
      formatted += cardNumber[i];
    }
    return formatted;
  }
  
  String _formatSheba(String sheba) {
    if (!sheba.toUpperCase().startsWith('IR')) {
      return 'IR$sheba';
    }
    return sheba;
  }
} 