import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:saferide_mobile/app/safe_ride_app.dart';
import 'package:saferide_mobile/services/api_client.dart';
import 'package:saferide_mobile/services/auth_service.dart';

void main() {
  testWidgets('shows login screen when not authenticated', (tester) async {
    // Mock storage so no real device storage is touched.
    SharedPreferences.setMockInitialValues({});

    final auth = AuthService();
    await auth.initialize();
    final api = ApiClient(authService: auth);

    await tester.pumpWidget(SafeRideApp(authService: auth, apiClient: api));
    await tester.pump();

    // Login screen title and its login button should be present.
    expect(find.text('SafeRide Guardian'), findsOneWidget);
    expect(find.text('Login'), findsWidgets);
    expect(find.text('New user? Create an account'), findsOneWidget);
  });
}
