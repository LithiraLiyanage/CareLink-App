import 'package:flutter/material.dart';

import 'services/student_verification_review_service.dart';

/// Resolves whether the signed-in user may open Coordinator screens.
typedef CoordinatorAccessCheck = Future<bool> Function();

/// Supplies the [CoordinatorAccessCheck] used by [CoordinatorAccessGuard].
///
/// Without a scope above them, guards use the same check as the student
/// verification review: Coordinator/Admin custom claims provisioned by a
/// trusted Admin SDK process. The Firestore `role` field is client-writable
/// and is never treated as Coordinator authority (see `firestore.rules`).
class CoordinatorAccessScope extends InheritedWidget {
  const CoordinatorAccessScope({
    super.key,
    required this.check,
    required super.child,
  });

  final CoordinatorAccessCheck check;

  // Async so a Firebase setup error fails closed instead of throwing in build.
  static Future<bool> _defaultCheck() async =>
      StudentVerificationReviewService().isAuthorizedReviewer();

  static CoordinatorAccessCheck of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<CoordinatorAccessScope>()
          ?.check ??
      _defaultCheck;

  @override
  bool updateShouldNotify(CoordinatorAccessScope oldWidget) =>
      check != oldWidget.check;
}

/// Builds [child] only after the Coordinator/Admin check passes, so a
/// Coordinator screen never reads case data for an unauthorized user.
class CoordinatorAccessGuard extends StatefulWidget {
  const CoordinatorAccessGuard({super.key, required this.child});

  final Widget child;

  @override
  State<CoordinatorAccessGuard> createState() => _CoordinatorAccessGuardState();
}

class _CoordinatorAccessGuardState extends State<CoordinatorAccessGuard> {
  Future<bool>? _authorization;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _authorization ??= CoordinatorAccessScope.of(context)();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: _authorization,
    builder: (context, snapshot) {
      if (snapshot.data == true) return widget.child;
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      return Scaffold(
        appBar: AppBar(title: const Text('Restricted')),
        body: Center(
          child: Text(
            snapshot.hasError
                ? 'Could not verify coordinator access.'
                : 'Coordinator or Admin access is required.',
          ),
        ),
      );
    },
  );
}
