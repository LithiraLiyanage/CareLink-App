import 'package:carelink_app/features/auth/services/accessibility_controller.dart';
import 'package:carelink_app/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('saved accessibility preferences affect the application', (
    tester,
  ) async {
    final controller = AccessibilityController.instance;
    addTearDown(controller.reset);
    controller.apply(largerText: true, highContrast: true, reduceMotion: true);
    await tester.pumpWidget(const CareLinkApp());
    final context = tester.element(find.byType(Scaffold));
    expect(MediaQuery.textScalerOf(context).scale(16), closeTo(19.2, 0.001));
    expect(MediaQuery.disableAnimationsOf(context), isTrue);
    expect(find.byType(ColorFiltered), findsOneWidget);
    expect(
      Theme.of(context)
          .pageTransitionsTheme
          .builders[TargetPlatform.android]!
          .transitionDuration,
      Duration.zero,
    );
  });

  testWidgets('larger text preserves a larger system text setting', (
    tester,
  ) async {
    final controller = AccessibilityController.instance;
    addTearDown(controller.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    controller.apply(
      largerText: true,
      highContrast: false,
      reduceMotion: false,
    );
    await tester.pumpWidget(const CareLinkApp());
    final context = tester.element(find.byType(Scaffold));
    expect(MediaQuery.textScalerOf(context).scale(16), closeTo(28.8, 0.001));
  });

  test('AccessibilityController applies and resets stored preferences', () {
    final controller = AccessibilityController.instance;
    addTearDown(controller.reset);

    controller.applyFromMap({
      'largerText': true,
      'highContrast': true,
      'reduceMotion': true,
    });

    expect(controller.value.largerText, isTrue);
    expect(controller.value.highContrast, isTrue);
    expect(controller.value.reduceMotion, isTrue);

    controller.reset();
    expect(controller.value.largerText, isFalse);
    expect(controller.value.highContrast, isFalse);
    expect(controller.value.reduceMotion, isFalse);
  });
}
