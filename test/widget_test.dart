import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carelink_app/app/app.dart';

void main() {
  testWidgets('CareLink splash screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(const CareLinkApp());

    // Check the temporary CareLink logo icon.
    expect(
      find.byIcon(Icons.volunteer_activism_rounded),
      findsOneWidget,
    );

    // Check the CareLink tagline.
    expect(
      find.text('CONNECT  •  CARE  •  COMFORT'),
      findsOneWidget,
    );

    // Check the splash slogan.
    expect(
      find.text('Small Conversations,\nBrighter Days.'),
      findsOneWidget,
    );
  });
}