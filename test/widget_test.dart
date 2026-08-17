import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('NIMO basic smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('NIMO: The Warrior'),
          ),
        ),
      ),
    );
    expect(find.text('NIMO: The Warrior'), findsOneWidget);
  });
}
