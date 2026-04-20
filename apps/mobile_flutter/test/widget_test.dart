import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('smoke test renders material app', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('ALITAPTAP')),
        ),
      ),
    );

    expect(find.text('ALITAPTAP'), findsOneWidget);
  });
}
