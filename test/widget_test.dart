import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carelink_app/app/app.dart';

void main() {
  testWidgets('CareLink splash screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(const CareLinkApp());

    // Check that the splash screen is rendered.
    expect(find.byType(Scaffold), findsOneWidget);

    // Check the CareLink logo image.
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/carelink_logo.png',
      ),
      findsOneWidget,
    );

    // Check the bottom splash artwork.
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/splash_bottom.png',
      ),
      findsOneWidget,
    );

    // Check the CareLink tagline.
    expect(
      find.text('CONNECT  •  CARE  •  COMFORT'),
      findsOneWidget,
    );
  });
}