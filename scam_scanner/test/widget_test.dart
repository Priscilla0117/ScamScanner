import 'package:flutter_test/flutter_test.dart';

// Make sure this matches your project name!
import 'package:scam_scanner/main.dart'; 

void main() {
  testWidgets('ScamScanner smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ScamScannerApp());

    // Verify that our app's main title is on the screen.
    expect(find.text('Suspicious Message Checker'), findsOneWidget);
  });
}