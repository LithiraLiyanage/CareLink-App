import 'case_outcome.dart';

/// Why a safety case was opened. Only missed check-ins exist today.
enum SafetyCaseReason {
  missedCheckIn('Missed Check-in');

  const SafetyCaseReason(this.label);

  final String label;
}

/// Workflow state of a safety case, using the labels shown on the case list.
enum SafetyCaseStatus {
  pendingReview('Pending Review'),
  retryRequested('Retry Requested'),
  rescheduled('Rescheduled'),
  contactFollowUp('Contact Follow-up'),
  closed('Closed');

  const SafetyCaseStatus(this.label);

  final String label;

  bool get isClosed => this == SafetyCaseStatus.closed;
}

/// Case list filter chips. "Pending" covers every case that is not closed.
enum SafetyCaseFilter {
  all('All'),
  pending('Pending'),
  closed('Closed');

  const SafetyCaseFilter(this.label);

  final String label;

  bool matches(SafetyCase safetyCase) => switch (this) {
    SafetyCaseFilter.all => true,
    SafetyCaseFilter.pending => !safetyCase.status.isClosed,
    SafetyCaseFilter.closed => safetyCase.status.isClosed,
  };

  List<SafetyCase> apply(Iterable<SafetyCase> cases) =>
      List.unmodifiable(cases.where(matches));
}

/// Filter counts derived from a list of cases rather than hard-coded.
class SafetyCaseCounts {
  final int all;
  final int pending;
  final int closed;

  const SafetyCaseCounts({
    required this.all,
    required this.pending,
    required this.closed,
  });

  factory SafetyCaseCounts.fromCases(Iterable<SafetyCase> cases) {
    var pending = 0;
    var closed = 0;
    for (final safetyCase in cases) {
      safetyCase.status.isClosed ? closed++ : pending++;
    }
    return SafetyCaseCounts(
      all: pending + closed,
      pending: pending,
      closed: closed,
    );
  }

  int countFor(SafetyCaseFilter filter) => switch (filter) {
    SafetyCaseFilter.all => all,
    SafetyCaseFilter.pending => pending,
    SafetyCaseFilter.closed => closed,
  };
}

/// A coordinator safety case raised for an elder.
class SafetyCase {
  final String id;
  final int caseNumber;
  final String elderId;

  /// Short elder reference shown as "Elder ID" on the case screens.
  final String elderReference;
  final String elderDisplayName;

  /// Relationship to the linked family member (e.g. "Mother"), if known.
  final String? elderRelationship;
  final SafetyCaseReason reason;
  final SafetyCaseStatus status;
  final DateTime scheduledAt;
  final int previousAttempts;
  final DateTime openedAt;
  final DateTime? closedAt;
  final CaseOutcome? outcome;

  const SafetyCase({
    required this.id,
    required this.caseNumber,
    required this.elderId,
    required this.elderReference,
    required this.elderDisplayName,
    this.elderRelationship,
    this.reason = SafetyCaseReason.missedCheckIn,
    required this.status,
    required this.scheduledAt,
    this.previousAttempts = 0,
    required this.openedAt,
    this.closedAt,
    this.outcome,
  });

  /// Display reference such as "Case #001".
  String get caseLabel => 'Case #${caseNumber.toString().padLeft(3, '0')}';

  bool get isClosed => status.isClosed;

  SafetyCase copyWith({
    SafetyCaseStatus? status,
    int? previousAttempts,
    DateTime? closedAt,
    CaseOutcome? outcome,
  }) => SafetyCase(
    id: id,
    caseNumber: caseNumber,
    elderId: elderId,
    elderReference: elderReference,
    elderDisplayName: elderDisplayName,
    elderRelationship: elderRelationship,
    reason: reason,
    status: status ?? this.status,
    scheduledAt: scheduledAt,
    previousAttempts: previousAttempts ?? this.previousAttempts,
    openedAt: openedAt,
    closedAt: closedAt ?? this.closedAt,
    outcome: outcome ?? this.outcome,
  );
}
