import 'package:flutter_test/flutter_test.dart';
import 'package:peppa_p/main.dart';
import 'package:peppa_p/screens/onboarding_screen.dart';

void main() {
  testWidgets('NIMO onboarding screen renders properly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NimoApp());
    await tester.pumpAndSettle();

    // Verify that NIMO onboarding screen renders properly.
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });
}
