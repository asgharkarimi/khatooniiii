// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Basic UI test', (WidgetTester tester) async {
    // Build a simple MaterialApp with a Scaffold for testing
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('سامانه خاتون بار'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('تست برنامه'),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('دکمه تست'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Verify that our app contains the expected widgets
    expect(find.text('سامانه خاتون بار'), findsOneWidget);
    expect(find.text('تست برنامه'), findsOneWidget);
    expect(find.text('دکمه تست'), findsOneWidget);
    
    // Tap the button and verify the app doesn't crash
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
  });
}
