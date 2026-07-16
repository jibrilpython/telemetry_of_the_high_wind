import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telemetry_of_the_high_wind/main.dart';

void main() {
  testWidgets('first launch opens upper-air onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: TelemetryApp()));
    await tester.pump();

    expect(find.text('Telemetry\nof the\nHigh Wind'), findsOneWidget);
    expect(find.text('OPEN THE UPPER-AIR REGISTER'), findsOneWidget);
  });
}
