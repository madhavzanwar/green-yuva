import 'package:flutter_test/flutter_test.dart';
import 'package:greenyuva/main.dart';

void main() {
  testWidgets('Green Yuva smoke test', (WidgetTester tester) async {
    // Build GreenYuvaApp widget and trigger a frame.
    await tester.pumpWidget(const GreenYuvaApp());

    // Verify GreenYuvaApp starts successfully.
    expect(find.byType(GreenYuvaApp), findsOneWidget);
  });
}
