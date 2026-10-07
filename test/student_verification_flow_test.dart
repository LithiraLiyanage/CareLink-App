import 'package:carelink_app/features/auth/screens/student_verification_screen.dart';
import 'package:carelink_app/features/auth/screens/verification_status_screen.dart';
import 'package:carelink_app/features/auth/services/student_verification_service.dart';
import 'package:carelink_app/features/coordinator/screens/student_verification_review_screen.dart';
import 'package:carelink_app/features/coordinator/services/student_verification_review_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeVerificationRepository implements StudentVerificationRepository {
  String? status;
  Map<String, String>? submitted;

  @override
  Future<void> submitVerification({
    required String selectedRole,
    required String university,
    required String studentId,
    required String universityEmail,
  }) async {
    submitted = {
      'role': selectedRole,
      'university': university,
      'studentId': studentId,
      'universityEmail': universityEmail,
    };
    status = 'pending';
  }

  @override
  Stream<String?> watchVerificationStatus() => Stream.value(status);
}

class _FakeReviewRepository implements StudentVerificationReviewRepository {
  _FakeReviewRepository({this.authorized = true});

  final bool authorized;
  final reviewed = <({String userId, String status, String? reason})>[];

  @override
  Future<bool> isAuthorizedReviewer() async => authorized;

  @override
  Stream<List<StudentVerificationReviewRequest>> watchPendingRequests() =>
      Stream.value([
        StudentVerificationReviewRequest(
          userId: 'student-uid',
          fullName: 'Student Name',
          university: 'CareLink University',
          studentId: 'S12345',
          universityEmail: 'student@carelink.edu',
          status: 'pending',
          submittedAt: DateTime(2026, 10, 6),
        ),
      ]);

  @override
  Future<void> reviewRequest({
    required String userId,
    required String status,
    String? rejectionReason,
  }) async {
    reviewed.add((userId: userId, status: status, reason: rejectionReason));
  }
}

void main() {
  testWidgets('student submits details without an image or document', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _FakeVerificationRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: StudentVerificationScreen(
          selectedRole: 'Student Companion',
          verificationRepository: repository,
        ),
      ),
    );
    expect(find.textContaining('Upload'), findsNothing);
    expect(find.textContaining('document'), findsNothing);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'CareLink University',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'S12345');
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'student@carelink.edu',
    );
    await tester.ensureVisible(
      find.text('I confirm that the information provided is accurate.'),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('verification-confirmation-checkbox')),
    );
    await tester.pump();
    await tester.ensureVisible(find.text('Submit Verification'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit Verification'));
    await tester.pumpAndSettle();

    expect(repository.submitted?['university'], 'CareLink University');
    expect(repository.submitted?['studentId'], 'S12345');
    expect(repository.submitted?['universityEmail'], 'student@carelink.edu');
    expect(repository.status, 'pending');
    expect(find.text('Your verification is under review.'), findsOneWidget);
  });

  for (final statusCase in [
    (status: 'pending', message: 'Your verification is under review.'),
    (status: 'verified', message: 'Your student account has been verified.'),
    (
      status: 'rejected',
      message: 'Your verification was not approved. Please review your details and submit again.',
    ),
  ]) {
    testWidgets('verification status screen displays ${statusCase.status}', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: VerificationStatusScreen(
            statusStream: Stream.value(statusCase.status),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(statusCase.message), findsOneWidget);
    });
  }

  testWidgets('untrusted account cannot open Coordinator review actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StudentVerificationReviewScreen(
          repository: _FakeReviewRepository(authorized: false),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Coordinator or Admin access is required.'),
      findsOneWidget,
    );
    expect(find.text('Approve'), findsNothing);
  });

  testWidgets('Coordinator can approve a pending student', (tester) async {
    final repository = _FakeReviewRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: StudentVerificationReviewScreen(repository: repository),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Student Name'), findsOneWidget);
    expect(find.textContaining('student@carelink.edu'), findsOneWidget);
    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();
    expect(repository.reviewed.single.status, 'verified');
    expect(repository.reviewed.single.userId, 'student-uid');
  });

  testWidgets('Coordinator can reject with an optional reason', (tester) async {
    final repository = _FakeReviewRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: StudentVerificationReviewScreen(repository: repository),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Reject'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Please check your details');
    await tester.tap(find.widgetWithText(FilledButton, 'Reject'));
    await tester.pumpAndSettle();
    expect(repository.reviewed.single.status, 'rejected');
    expect(repository.reviewed.single.reason, 'Please check your details');
  });
}
