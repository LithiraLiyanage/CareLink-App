import 'package:carelink_app/app/app.dart';
import 'package:carelink_app/app/routes.dart';
import 'package:carelink_app/features/auth/screens/splash_screen.dart';
import 'package:carelink_app/features/coordinator/coordinator_access_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('restricted screen leads back to the start route', (
    tester,
  ) async {
    await tester.pumpWidget(
      CoordinatorAccessScope(
        check: () async => false,
        child: const CareLinkApp(),
      ),
    );
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .pushNamed(AppRoutes.coordinatorCaseList);
    await tester.pumpAndSettle();
    expect(find.text('Coordinator or Admin access is required.'), findsOneWidget);

    await tester.tap(find.text('Back to start'));
    await tester.pumpAndSettle();

    expect(find.text('Coordinator or Admin access is required.'), findsNothing);
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
