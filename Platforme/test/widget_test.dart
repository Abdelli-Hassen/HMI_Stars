import 'package:flutter_test/flutter_test.dart';
import 'package:hmi_stars/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const HmiStarsApp());
    // Verify that the app builds without errors.
    expect(find.byType(HmiStarsApp), findsOneWidget);
  });
}
