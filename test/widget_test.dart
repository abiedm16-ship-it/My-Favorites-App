import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_favorites_app/main.dart';
import 'package:my_favorites_app/screens/login_screen.dart';

void main() {
  testWidgets('App compiles and runs successfully, showing login screen first', (WidgetTester tester) async {
    // Mock SharedPreferences values before building the widget
    SharedPreferences.setMockInitialValues({});

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyFavoritesApp());
    
    // Wait for asynchronous actions (like loading preferences) to complete and trigger build
    await tester.pumpAndSettle();

    // Verify that the LoginScreen is present.
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
