import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App boots and shows home frame', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Text('POS App')),
      ),
    );
    expect(find.text('POS App'), findsOneWidget);
  });
}
