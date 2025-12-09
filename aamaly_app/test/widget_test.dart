// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:aamaly/main.dart';

void main() {
  testWidgets('Task list page smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AamalyApp());

    // Verify that the app bar title is displayed
    expect(find.text('My Tasks'), findsOneWidget);

    // Verify that search bar hint is present
    expect(find.text('Search tasks...'), findsOneWidget);
  });
}
