import 'package:carelink_app/app/routes.dart';
import 'package:carelink_app/features/coordinator/coordinator_case_scope.dart';
import 'package:carelink_app/features/coordinator/coordinator_screens.dart';
import 'package:carelink_app/features/coordinator/services/mock_coordinator_case_repository.dart';
import 'package:carelink_app/features/coordinator/services/student_verification_review_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeReviewRepository implements StudentVerificationReviewRepository {
  _FakeReviewRepository({this.authorized = true});

  final bool authorized;

  @override
  Future<bool> isAuthorizedReviewer() async => authorized;

  @override
  Stream<List<StudentVerificationReviewRequest>> watchPendingRequests() =>
      Stream.value(const []);

  @override
  Future<void> reviewRequest({
    required String userId,
    required String status,
    String? rejectionReason,
  }) async {}
}

Widget _app(StudentVerificationReviewRepository repository) =>
    CoordinatorCaseScope(
      repository: MockCoordinatorCaseRepository(),
      child: MaterialApp(
        home: const CoordinatorCaseListScreen(),
        routes: {
          AppRoutes.coordinatorCaseDetail: (_) =>
              const CoordinatorCaseDetailScreen(),
          AppRoutes.coordinatorVerifications: (_) =>
              StudentVerificationReviewScreen(repository: repository),
        },
      ),
    );

void main() {
  testWidgets('Coordinator opens verifications from the case list', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_FakeReviewRepository()));
    expect(find.text('Safety Cases'), findsOneWidget);

    await tester.tap(find.text('Verifications'));
    await tester.pumpAndSettle();

    expect(find.text('Student verification review'), findsOneWidget);
    expect(
      find.text('There are no pending student verifications.'),
      findsOneWidget,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Safety Cases'), findsOneWidget);
  });

  testWidgets('verifications route keeps the reviewer permission check', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_FakeReviewRepository(authorized: false)));

    await tester.tap(find.text('Verifications'));
    await tester.pumpAndSettle();

    expect(
      find.text('Coordinator or Admin access is required.'),
      findsOneWidget,
    );
  });

  testWidgets('case list app bar has no menu or avatar navigation', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_FakeReviewRepository()));

    expect(find.byIcon(Icons.menu_rounded), findsNothing);
    expect(find.byTooltip('Open missed session'), findsNothing);
    expect(find.byTooltip('Open case details'), findsNothing);

    await tester.tap(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.person_rounded),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Safety Cases'), findsOneWidget);
    expect(find.text('No case selected.'), findsNothing);
  });

  for (final label in ['Notifications', 'Profile']) {
    testWidgets('$label tab explains it is unavailable and stays put', (
      tester,
    ) async {
      await tester.pumpWidget(_app(_FakeReviewRepository()));

      await tester.tap(find.text(label));
      await tester.pump();

      expect(find.text('$label is not available yet.'), findsOneWidget);
      expect(find.text('Safety Cases'), findsOneWidget);
    });
  }
}
