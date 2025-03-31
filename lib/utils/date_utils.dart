import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'dart:ui' as ui;

class AppDateUtils {
  /// Convert Gregorian DateTime to Persian formatted string
  static String toPersianDate(DateTime date) {
    try {
      final jDate = Jalali.fromDateTime(date);
      return '${jDate.year}/${jDate.month.toString().padLeft(2, '0')}/${jDate.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'تاریخ نامعتبر';
    }
  }
  
  /// Convert Persian date string to Gregorian DateTime
  static DateTime toGregorian(String persianDate) {
    if (persianDate.isEmpty) return DateTime.now();
    
    final parts = persianDate.split('/');
    if (parts.length != 3) return DateTime.now();
    
    try {
      final jalali = Jalali(
        int.parse(parts[0]), 
        int.parse(parts[1]), 
        int.parse(parts[2])
      );
      
      return jalali.toDateTime();
    } catch (e) {
      return DateTime.now();
    }
  }
  
  /// Format Gregorian DateTime using standard Gregorian format
  static String formatGregorian(DateTime date) {
    return DateFormat('yyyy/MM/dd').format(date);
  }
  
  /// Show Persian date picker
  static Future<DateTime?> showJalaliDatePicker({
    required BuildContext context,
    DateTime? initialDate,
  }) async {
    try {
      initialDate ??= DateTime.now();
      
      final Jalali? picked = await showPersianDatePicker(
        context: context,
        initialDate: Jalali.fromDateTime(initialDate),
        firstDate: Jalali(1380),
        lastDate: Jalali(1410),
        builder: (context, child) {
          return Theme(
            data: ThemeData(
              fontFamily: 'Vazir',
              colorScheme: ColorScheme.light(
                primary: Theme.of(context).primaryColor,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black87,
              ),
              dialogBackgroundColor: Colors.white,
              textTheme: const TextTheme(
                titleLarge: TextStyle(fontFamily: 'Vazir', fontSize: 18, fontWeight: FontWeight.bold),
                bodyLarge: TextStyle(fontFamily: 'Vazir', fontSize: 16),
                bodyMedium: TextStyle(fontFamily: 'Vazir', fontSize: 14),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Vazir',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: child!,
              ),
            ),
          );
        },
      );
      
      return picked?.toDateTime();
    } catch (e) {
      return null;
    }
  }
  
  /// Show Persian date and time picker
  static Future<DateTime?> showPersianDateTimePicker({
    required BuildContext context,
    DateTime? initialDateTime,
  }) async {
    initialDateTime ??= DateTime.now();
    
    // First pick the date
    final pickedDate = await showJalaliDatePicker(
      context: context,
      initialDate: initialDateTime,
    );
    
    if (pickedDate == null) return null;
    
    // Then pick the time
    TimeOfDay initialTime = TimeOfDay.fromDateTime(initialDateTime);
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData(
            fontFamily: 'Vazir',
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteTextColor: Colors.black87,
              dayPeriodTextColor: Colors.black87,
              dayPeriodColor: Colors.grey.shade200,
              dialHandColor: Theme.of(context).primaryColor,
              dialBackgroundColor: Colors.grey.shade200,
              hourMinuteColor: Colors.grey.shade200,
              hourMinuteTextStyle: const TextStyle(
                fontFamily: 'Vazir',
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              dayPeriodTextStyle: const TextStyle(
                fontFamily: 'Vazir',
                fontSize: 12,
              ),
              helpTextStyle: const TextStyle(
                fontFamily: 'Vazir',
                fontSize: 12,
              ),
            ),
          ),
          child: Directionality(
            textDirection: ui.TextDirection.rtl,
            child: child!,
          ),
        );
      },
    );
    
    if (pickedTime == null) return null;
    
    // Return the combined date and time
    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }
  
  /// Format time to readable Persian format
  static String formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  
  /// Format date and time to Persian format
  static String formatPersianDateTime(DateTime dateTime) {
    final date = toPersianDate(dateTime);
    final time = formatTime(TimeOfDay.fromDateTime(dateTime));
    return '$date $time';
  }
  
  /// Get a beautiful Persian date presentation
  static String getPrettyPersianDate(DateTime date) {
    final jDate = Jalali.fromDateTime(date);
    final month = getPersianMonthName(jDate.month);
    return '${jDate.day} $month ${jDate.year}';
  }
  
  /// Get Persian month name
  static String getPersianMonthName(int month) {
    final List<String> months = [
      'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
      'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'
    ];
    
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return '';
  }
  
  /// Get Persian day of week name
  static String getPersianWeekDay(DateTime date) {
    final jDate = Jalali.fromDateTime(date);
    final List<String> weekDays = [
      'شنبه', 'یکشنبه', 'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنج‌شنبه', 'جمعه'
    ];
    
    // Convert Jalali weekDay to correct index (Saturday = 0)
    int weekDayIndex = (jDate.weekDay + 1) % 7;
    return weekDays[weekDayIndex];
  }

  static String formatJalaliDate(DateTime date) {
    final jDate = Jalali.fromDateTime(date);
    return '${jDate.year}/${jDate.month}/${jDate.day}';
  }
} 