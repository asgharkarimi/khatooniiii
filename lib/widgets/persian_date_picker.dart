import 'package:flutter/material.dart';
import 'package:khatooniiii/utils/date_utils.dart' as date_utils;

class PersianDatePicker extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged;
  final String? labelText;
  final String? hintText;
  final Icon? prefixIcon;
  final Widget? suffix;
  final bool showWeekDay;
  final bool readOnly;
  final String? Function(DateTime?)? validator;
  final InputDecoration? decoration;
  
  const PersianDatePicker({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffix,
    this.showWeekDay = true,
    this.readOnly = false,
    this.validator,
    this.decoration,
  });
  
  Future<void> _selectDate(BuildContext context) async {
    if (readOnly) return;
    
    final DateTime? picked = await date_utils.AppDateUtils.showJalaliDatePicker(
      context: context,
      initialDate: selectedDate,
    );
    
    if (picked != null) {
      onDateChanged(picked);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: decoration ?? InputDecoration(
          labelText: labelText,
          hintText: hintText,
          prefixIcon: prefixIcon ?? const Icon(Icons.calendar_today),
          suffix: suffix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date_utils.AppDateUtils.formatJalaliDate(selectedDate),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (showWeekDay) ...[
                      const SizedBox(height: 4),
                      Text(
                        date_utils.AppDateUtils.getPersianWeekDay(selectedDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// A form field version that integrates with Form validation
class PersianDateFormField extends FormField<DateTime> {
  PersianDateFormField({
    Key? key,
    required DateTime selectedDate,
    required Function(DateTime) onDateChanged,
    String? labelText,
    String? hintText,
    Icon? prefixIcon,
    Widget? suffix,
    bool showWeekDay = true,
    bool readOnly = false,
    String? Function(DateTime?)? validator,
    InputDecoration? decoration,
    AutovalidateMode autovalidateMode = AutovalidateMode.disabled,
  }) : super(
    key: key,
    initialValue: selectedDate,
    validator: validator,
    autovalidateMode: autovalidateMode,
    builder: (FormFieldState<DateTime> state) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PersianDatePicker(
            selectedDate: state.value!,
            onDateChanged: (date) {
              state.didChange(date);
              onDateChanged(date);
            },
            labelText: labelText,
            hintText: hintText,
            prefixIcon: prefixIcon,
            suffix: suffix,
            showWeekDay: showWeekDay,
            readOnly: readOnly,
            decoration: decoration?.copyWith(
              errorText: state.errorText,
            ) ?? InputDecoration(
              labelText: labelText,
              hintText: hintText,
              errorText: state.errorText,
              prefixIcon: prefixIcon ?? const Icon(Icons.calendar_today),
              suffix: suffix,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      );
    },
  );
}

// A beautiful styled date picker widget with card decoration
class StyledPersianDatePicker extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged;
  final String title;
  final bool readOnly;
  
  const StyledPersianDatePicker({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    required this.title,
    this.readOnly = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: readOnly ? null : () async {
              final DateTime? picked = await date_utils.AppDateUtils.showJalaliDatePicker(
                context: context,
                initialDate: selectedDate,
              );
              
              if (picked != null) {
                onDateChanged(picked);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.calendar_today,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            date_utils.AppDateUtils.formatJalaliDate(selectedDate),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            date_utils.AppDateUtils.getPersianWeekDay(selectedDate),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// New classes for Date and Time Picker

class PersianDateTimePicker extends StatelessWidget {
  final DateTime selectedDateTime;
  final Function(DateTime) onDateTimeChanged;
  final String? labelText;
  final String? hintText;
  final Icon? prefixIcon;
  final Widget? suffix;
  final bool showWeekDay;
  final bool readOnly;
  final InputDecoration? decoration;
  
  const PersianDateTimePicker({
    super.key,
    required this.selectedDateTime,
    required this.onDateTimeChanged,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffix,
    this.showWeekDay = true,
    this.readOnly = false,
    this.decoration,
  });
  
  Future<void> _selectDateTime(BuildContext context) async {
    if (readOnly) return;
    
    final DateTime? picked = await date_utils.AppDateUtils.showPersianDateTimePicker(
      context: context,
      initialDateTime: selectedDateTime,
    );
    
    if (picked != null) {
      onDateTimeChanged(picked);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _selectDateTime(context),
      child: InputDecorator(
        decoration: decoration ?? InputDecoration(
          labelText: labelText,
          hintText: hintText,
          prefixIcon: prefixIcon ?? const Icon(Icons.event),
          suffix: suffix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date_utils.AppDateUtils.formatPersianDateTime(selectedDateTime),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (showWeekDay) ...[
                      const SizedBox(height: 4),
                      Text(
                        date_utils.AppDateUtils.getPersianWeekDay(selectedDateTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// A form field version that integrates with Form validation
class PersianDateTimeFormField extends FormField<DateTime> {
  PersianDateTimeFormField({
    Key? key,
    required DateTime selectedDateTime,
    required Function(DateTime) onDateTimeChanged,
    String? labelText,
    String? hintText,
    Icon? prefixIcon,
    Widget? suffix,
    bool showWeekDay = true,
    bool readOnly = false,
    String? Function(DateTime?)? validator,
    InputDecoration? decoration,
    AutovalidateMode autovalidateMode = AutovalidateMode.disabled,
  }) : super(
    key: key,
    initialValue: selectedDateTime,
    validator: validator,
    autovalidateMode: autovalidateMode,
    builder: (FormFieldState<DateTime> state) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PersianDateTimePicker(
            selectedDateTime: state.value!,
            onDateTimeChanged: (dateTime) {
              state.didChange(dateTime);
              onDateTimeChanged(dateTime);
            },
            labelText: labelText,
            hintText: hintText,
            prefixIcon: prefixIcon,
            suffix: suffix,
            showWeekDay: showWeekDay,
            readOnly: readOnly,
            decoration: decoration?.copyWith(
              errorText: state.errorText,
            ) ?? InputDecoration(
              labelText: labelText,
              hintText: hintText,
              errorText: state.errorText,
              prefixIcon: prefixIcon ?? const Icon(Icons.event),
              suffix: suffix,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      );
    },
  );
} 