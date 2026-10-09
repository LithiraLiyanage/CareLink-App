import 'package:flutter/widgets.dart';

import 'services/coordinator_case_repository.dart';
import 'services/mock_coordinator_case_repository.dart';

/// Supplies the [CoordinatorCaseRepository] shared by the Coordinator case
/// screens.
///
/// Every case screen must read the same instance so an action recorded on one
/// screen is visible on the next. Without a scope above them, screens fall
/// back to a single app-wide [MockCoordinatorCaseRepository]; there is no
/// Firebase-backed implementation yet.
class CoordinatorCaseScope extends InheritedWidget {
  const CoordinatorCaseScope({
    super.key,
    required this.repository,
    required super.child,
  });

  final CoordinatorCaseRepository repository;

  static final CoordinatorCaseRepository _fallback =
      MockCoordinatorCaseRepository();

  static CoordinatorCaseRepository of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<CoordinatorCaseScope>()
          ?.repository ??
      _fallback;

  @override
  bool updateShouldNotify(CoordinatorCaseScope oldWidget) =>
      repository != oldWidget.repository;
}

/// The case id a case screen was opened with, passed as the route argument.
String? caseIdFromRoute(BuildContext context) {
  final argument = ModalRoute.of(context)?.settings.arguments;
  return argument is String && argument.isNotEmpty ? argument : null;
}
