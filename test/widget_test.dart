import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_hospital_nurse/app.dart';

void main() {
  testWidgets('SmartHospitalNurseApp boots into Nurse Care System splash', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(const SmartHospitalNurseApp());
    expect(find.text('Nurse Care System'), findsOneWidget);
  });
}
