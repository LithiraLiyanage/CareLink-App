import 'package:flutter/material.dart';

import 'models/elder_consent_context.dart';
import 'models/safety_case.dart';

/// Formatting and small shared widgets for the Coordinator case screens.

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// e.g. "30 Sep".
String formatCaseDayMonth(DateTime value) =>
    '${value.day} ${_months[value.month - 1]}';

/// e.g. "30 Sep 2026".
String formatCaseDate(DateTime value) =>
    '${formatCaseDayMonth(value)} ${value.year}';

/// e.g. "2:00 PM".
String formatCaseTime(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${value.hour < 12 ? 'AM' : 'PM'}';
}

/// e.g. "30 Sep 2026, 2:00 PM".
String formatCaseDateTime(DateTime value) =>
    '${formatCaseDate(value)}, ${formatCaseTime(value)}';

/// A readable message for a failed repository call.
String describeCaseError(Object error) =>
    error is StateError ? error.message : error.toString();

const _warning = Color(0xFFF59E0B);
const _lightWarning = Color(0xFFFFF4DF);
const _info = Color(0xFF2196F3);
const _lightInfo = Color(0xFFE8F3FF);
const _success = Color(0xFF00A878);
const _lightSuccess = Color(0xFFDFF5ED);
const _danger = Color(0xFFE53935);
const _lightDanger = Color(0xFFFFF0F0);
const _neutral = Color(0xFF708486);
const _lightNeutral = Color(0xFFE7F6F1);

typedef CaseColors = ({Color foreground, Color background});

/// Pill colours for a case status, matching the original case list.
CaseColors caseStatusColors(SafetyCaseStatus status) => switch (status) {
  SafetyCaseStatus.pendingReview => (
    foreground: _warning,
    background: _lightWarning,
  ),
  SafetyCaseStatus.retryRequested || SafetyCaseStatus.rescheduled => (
    foreground: _info,
    background: _lightInfo,
  ),
  SafetyCaseStatus.contactFollowUp => (
    foreground: _success,
    background: _lightSuccess,
  ),
  SafetyCaseStatus.closed => (
    foreground: _neutral,
    background: _lightNeutral,
  ),
};

/// Colours for a consent sharing status; only [ConsentSharingStatus.approved]
/// is shown as positive.
CaseColors consentStatusColors(ConsentSharingStatus status) => switch (status) {
  ConsentSharingStatus.approved => (
    foreground: _success,
    background: _lightSuccess,
  ),
  ConsentSharingStatus.notRecorded => (
    foreground: _warning,
    background: _lightWarning,
  ),
  ConsentSharingStatus.withdrawn => (
    foreground: _danger,
    background: _lightDanger,
  ),
};

/// One-line consent summary used on the case detail screen.
({String label, Color color}) consentSummary(ElderConsentContext consent) {
  if (consent.canContactApprovedPerson) {
    return (label: 'Approved family contact', color: _success);
  }
  return switch (consent.familySharing) {
    ConsentSharingStatus.approved => (
      label: 'Approved, no contact named',
      color: _warning,
    ),
    ConsentSharingStatus.notRecorded => (
      label: 'Consent not recorded',
      color: _warning,
    ),
    ConsentSharingStatus.withdrawn => (
      label: 'Consent withdrawn',
      color: _danger,
    ),
  };
}

/// Centered loading, empty or error message for a case screen.
class CoordinatorCaseMessage extends StatelessWidget {
  const CoordinatorCaseMessage({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  const CoordinatorCaseMessage.loading({super.key})
    : icon = null,
      title = 'Loading...',
      message = null,
      actionLabel = null,
      onAction = null;

  final IconData? icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  static const _teal = Color(0xFF00776F);
  static const _darkTeal = Color(0xFF073F42);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 12),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon == null)
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: _teal),
          )
        else
          Icon(icon, size: 36, color: _teal),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _darkTeal,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 4),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _neutral, fontSize: 12, height: 1.4),
          ),
        ],
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onAction,
            style: OutlinedButton.styleFrom(foregroundColor: _teal),
            child: Text(actionLabel!),
          ),
        ],
      ],
    ),
  );
}

/// Small notice that the screen shows mock data, not live records.
class CoordinatorMockDataNote extends StatelessWidget {
  const CoordinatorMockDataNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(Icons.science_outlined, size: 14, color: _neutral),
      const SizedBox(width: 5),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(color: _neutral, fontSize: 10.5),
        ),
      ),
    ],
  );
}
