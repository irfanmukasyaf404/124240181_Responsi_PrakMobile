import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:responsi_prakmobile/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App renders login screen initially', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const SpaceNewsApp(
      initialIsLoggedIn: false,
    ));
    await tester.pump();

    expect(find.text('SpaceNews Explorer'), findsOneWidget);
    expect(find.text('MASUK'), findsOneWidget);
  });
}
