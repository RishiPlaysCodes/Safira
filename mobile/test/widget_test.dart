import 'package:flutter_test/flutter_test.dart';
import 'package:saferide_mobile/app/safe_ride_app.dart';

void main() {
  testWidgets('SafeRide home screen loads', (tester) async {
    await tester.pumpWidget(const SafeRideApp());
    expect(find.text('SafeRide Guardian'), findsOneWidget);
  });
}
