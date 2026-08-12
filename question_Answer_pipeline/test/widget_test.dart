import 'package:flutter_test/flutter_test.dart';

import 'package:qs_ans/main.dart';

void main() {
  testWidgets('App launches with intro screen', (WidgetTester tester) async {
    await tester.pumpWidget(const QsAnsApp());

    // Verify that the intro screen is shown with a START button.
    expect(find.text('Video Learning'), findsOneWidget);
    expect(find.text('START'), findsOneWidget);
  });
}
