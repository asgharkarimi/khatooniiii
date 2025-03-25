import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColorLight = Color(0xFF1565C0); // Material Blue 800
  static const Color primaryColorDark = Color(0xFF1976D2);  // Material Blue 700
  
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: primaryColorLight,
      secondary: Colors.blue[300]!,
      surface: Colors.white,
      error: Colors.red[700]!,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColorLight,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColorLight,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColorLight,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColorLight,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFEEEEEE),
      thickness: 1,
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontFamily: 'Vazir',
        fontWeight: FontWeight.bold,
        color: Color(0xFF212121),
        fontSize: 18,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Vazir',
        fontWeight: FontWeight.bold,
        color: Color(0xFF212121),
        fontSize: 16,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Vazir',
        color: Color(0xFF424242),
        fontSize: 14,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Vazir',
        color: Color(0xFF616161),
        fontSize: 13,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Vazir',
        color: Color(0xFF616161),
        fontSize: 12,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Vazir',
        color: Color(0xFF212121),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primaryColorLight, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.red[300]!, width: 1),
      ),
    ),
    fontFamily: 'Vazir',
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
  );
  
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: primaryColorDark,
      secondary: Colors.blue[200]!,
      surface: const Color(0xFF303030),
      error: Colors.red[300]!,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF212121),
      foregroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.blue[200]),
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF303030),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColorDark,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.blue[200],
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColorDark,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF424242),
      thickness: 1,
    ),
    textTheme: TextTheme(
      headlineMedium: const TextStyle(
        fontFamily: 'Vazir',
        fontWeight: FontWeight.bold,
        color: Color(0xFFEEEEEE),
        fontSize: 18,
      ),
      titleLarge: const TextStyle(
        fontFamily: 'Vazir',
        fontWeight: FontWeight.bold,
        color: Color(0xFFEEEEEE),
        fontSize: 16,
      ),
      bodyLarge: const TextStyle(
        fontFamily: 'Vazir',
        color: Color(0xFFE0E0E0),
        fontSize: 14,
      ),
      bodyMedium: const TextStyle(
        fontFamily: 'Vazir',
        color: Color(0xFFBDBDBD),
        fontSize: 13,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Vazir',
        color: Colors.grey[400],
        fontSize: 12,
      ),
      labelLarge: const TextStyle(
        fontFamily: 'Vazir',
        color: Color(0xFFEEEEEE),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF424242),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF616161)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF616161)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.blue[200]!, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.red[300]!, width: 1),
      ),
      hintStyle: TextStyle(color: Colors.grey[400]),
      labelStyle: TextStyle(color: Colors.grey[400]),
    ),
    iconTheme: IconThemeData(
      color: Colors.grey[200],
    ),
    fontFamily: 'Vazir',
    scaffoldBackgroundColor: const Color(0xFF212121),
  );
} 