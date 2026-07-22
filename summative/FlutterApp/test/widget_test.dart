import 'package:flutter_test/flutter_test.dart';
import 'package:solar_power_prediction_app/main.dart';

void main() {
  testWidgets('Solar Power App Smoke Test', (WidgetTester tester) async {
    await tester.pumpWidget(const SolarPowerApp());
    expect(find.text('Solar Power Prediction System'), findsOneWidget);
  });
}
