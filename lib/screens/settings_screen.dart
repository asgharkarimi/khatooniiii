import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:khatooniiii/providers/theme_provider.dart';
import 'package:khatooniiii/utils/db_exporter.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('تنظیمات'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // تنظیمات ظاهری
          _buildSectionHeader(context, 'ظاهر برنامه'),
          _buildThemeSelector(context, themeProvider),
          const Divider(),
          
          // تنظیمات پایگاه داده
          _buildSectionHeader(context, 'پایگاه داده'),
          ListTile(
            title: const Text('نمایش ساختار پایگاه داده'),
            subtitle: const Text('مشاهده جداول و روابط پایگاه داده'),
            leading: const Icon(Icons.storage),
            onTap: () => DbExporter.showDbStructure(context),
          ),
          
          // اطلاعات برنامه
          const Divider(),
          _buildSectionHeader(context, 'درباره برنامه'),
          const ListTile(
            title: Text('نسخه'),
            subtitle: Text('1.0.0'),
            leading: Icon(Icons.info_outline),
          ),
          ListTile(
            title: const Text('توسعه دهنده'),
            subtitle: const Text('خاتونی - سیستم مدیریت بار'),
            leading: const Icon(Icons.code),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('خاتونی - سیستم مدیریت بار و حمل و نقل')),
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8, right: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
  
  Widget _buildThemeSelector(BuildContext context, ThemeProvider themeProvider) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          RadioListTile<ThemeMode>(
            title: const Text('حالت روشن'),
            value: ThemeMode.light,
            groupValue: themeProvider.themeMode,
            secondary: const Icon(Icons.light_mode),
            onChanged: (mode) => themeProvider.setThemeMode(mode!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('حالت تاریک'),
            value: ThemeMode.dark,
            groupValue: themeProvider.themeMode,
            secondary: const Icon(Icons.dark_mode),
            onChanged: (mode) => themeProvider.setThemeMode(mode!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('حالت سیستم'),
            subtitle: const Text('استفاده از تنظیمات سیستم'),
            value: ThemeMode.system,
            groupValue: themeProvider.themeMode,
            secondary: const Icon(Icons.brightness_auto),
            onChanged: (mode) => themeProvider.setThemeMode(mode!),
          ),
        ],
      ),
    );
  }
} 