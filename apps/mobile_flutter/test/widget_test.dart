import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alitaptap_mobile/features/auth/presentation/sign_in_page.dart';

void main() {
  testWidgets('SignInPage renders and continue is tappable', (
    WidgetTester tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: SignInPage(
          onContinue: () => tapped = true,
        ),
      ),
    );

    expect(find.text('ALITAPTAP'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
