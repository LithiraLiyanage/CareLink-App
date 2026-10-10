import 'package:carelink_app/app/app.dart';
import 'package:carelink_app/app/routes.dart';
import 'package:carelink_app/features/coordinator/coordinator_access_guard.dart';
import 'package:carelink_app/features/coordinator/coordinator_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _coordinatorRoutes = [
  AppRoutes.coordinatorCaseList,
  AppRoutes.coordinatorCaseDetail,
  AppRoutes.consentContextReview,
  AppRoutes.approvedContactAction,
  AppRoutes.auditOutcomeCloseCase,
  AppRoutes.caseClosed,
  AppRoutes.coordinatorVerifications,
];

Future<void> _openRoute(WidgetTester tester, String route) async {
  tester.state<NavigatorState>(find.byType(Navigator).first).pushNamed(route);
  await tester.pumpAndSettle();
}

void main() {
  group('Family Caregiver (no Coordinator/Admin claim)', () {
    for (final route in _coordinatorRoutes) {
      testWidgets('is blocked from $route', (tester) async {
        await tester.pumpWidget(
          CoordinatorAccessScope(
            check: () async => false,
            child: const CareLinkApp(),
          ),
        );

        await _openRoute(tester, route);

        expect(
          find.text('Coordinator or Admin access is required.'),
          findsOneWidget,
        );
        expect(find.text('Safety Cases'), findsNothing);
        expect(find.byType(CoordinatorCaseListScreen), findsNothing);
        expect(find.byType(CoordinatorCaseDetailScreen), findsNothing);
        expect(find.byType(StudentVerificationReviewScreen), findsNothing);
      });
    }

    testWidgets('case list is not built while access is being checked', (
      tester,
    ) async {
      var checked = false;
      await tester.pumpWidget(
        CoordinatorAccessScope(
          check: () async {
            await Future<void>.delayed(const Duration(seconds: 1));
            checked = true;
            return false;
          },
          child: const CareLinkApp(),
        ),
      );

      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .pushNamed(AppRoutes.coordinatorCaseList);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(checked, isFalse);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(CoordinatorCaseListScreen), findsNothing);

      await tester.pumpAndSettle();
      expect(find.byType(CoordinatorCaseListScreen), findsNothing);
    });

    testWidgets('restricted screen lets the user go back', (tester) async {
      await tester.pumpWidget(
        CoordinatorAccessScope(
          check: () async => false,
          child: const CareLinkApp(),
        ),
      );

      await _openRoute(tester, AppRoutes.coordinatorCaseList);
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Coordinator or Admin access is required.'), findsNothing);
    });
  });

  testWidgets('failed access check fails closed', (tester) async {
    await tester.pumpWidget(
      CoordinatorAccessScope(
        check: () async => throw StateError('claims unavailable'),
        child: const CareLinkApp(),
      ),
    );

    await _openRoute(tester, AppRoutes.coordinatorCaseList);

    expect(find.text('Could not verify coordinator access.'), findsOneWidget);
    expect(find.byType(CoordinatorCaseListScreen), findsNothing);
  });

  testWidgets('default check without a signed-in Firebase user fails closed', (
    tester,
  ) async {
    // No scope: the real claims-based check runs. Firebase is not initialised
    // in tests, so it errors and the case list must stay hidden.
    await tester.pumpWidget(const CareLinkApp());

    await _openRoute(tester, AppRoutes.coordinatorCaseList);

    expect(find.byType(CoordinatorCaseListScreen), findsNothing);
    expect(find.text('Safety Cases'), findsNothing);
  });

  testWidgets('Coordinator/Admin can open the case list', (
    tester,
  ) async {
    await tester.pumpWidget(
      CoordinatorAccessScope(
        check: () async => true,
        child: const CareLinkApp(),
      ),
    );

    await _openRoute(tester, AppRoutes.coordinatorCaseList);

    expect(find.byType(CoordinatorCaseListScreen), findsOneWidget);
    expect(find.text('Safety Cases'), findsOneWidget);
    expect(find.text('Coordinator or Admin access is required.'), findsNothing);
  });
}
