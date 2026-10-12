import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../coordinator/coordinator_case_scope.dart';
import '../../coordinator/coordinator_case_ui.dart';
import '../../coordinator/models/case_outcome.dart';
import '../../coordinator/models/elder_consent_context.dart';
import '../../coordinator/models/safety_case.dart';
import '../../coordinator/services/coordinator_case_repository.dart';

typedef _OutcomeView = ({SafetyCase safetyCase, ElderConsentContext consent});

/// Coordinator form for recording a safety case outcome and closing the case,
/// opened with the case id as the route argument.
class AuditOutcomeCloseCaseScreen extends StatefulWidget {
  const AuditOutcomeCloseCaseScreen({super.key, this.caseId});

  /// Case to close; when null the route argument is used.
  final String? caseId;

  static const _teal = Color(0xFF00776F);
  static const _darkTeal = Color(0xFF073F42);
  static const _coral = Color(0xFFFF5369);
  static const _darkCoral = Color(0xFFE63E55);
  static const _mint = Color(0xFFF5FBF9);
  static const _lightTeal = Color(0xFFE7F6F1);
  static const _primaryText = Color(0xFF073F42);
  static const _secondary = Color(0xFF708486);
  static const _muted = Color(0xFF9AABAC);
  static const _line = Color(0xFFD1EBE7);
  static const _warning = Color(0xFFB26A00);
  static const _lightWarning = Color(0xFFFFF4DF);

  static const notesMaxLength = 500;

  @override
  State<AuditOutcomeCloseCaseScreen> createState() =>
      _AuditOutcomeCloseCaseScreenState();
}

class _AuditOutcomeCloseCaseScreenState
    extends State<AuditOutcomeCloseCaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notes = TextEditingController();
  late CoordinatorCaseRepository _repository;
  String? _caseId;
  Future<_OutcomeView?>? _view;
  CaseActionTaken? _actionTaken;
  CaseOutcomeResult? _result;
  CaseClosureReason? _closureReason;
  bool _closing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_view != null) return;
    _repository = CoordinatorCaseScope.of(context);
    _caseId = widget.caseId ?? caseIdFromRoute(context);
    _view = _load();
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<_OutcomeView?> _load() async {
    final caseId = _caseId;
    if (caseId == null) return null;
    final safetyCase = await _repository.getCase(caseId);
    final consent = await _repository.getConsentContext(caseId);
    if (safetyCase == null || consent == null) return null;
    return (safetyCase: safetyCase, consent: consent);
  }

  void _reload() => setState(() {
        _view = _load();
      });

  void _showClosedCase() => Navigator.of(context).pushReplacementNamed(
    AppRoutes.caseClosed,
    arguments: _caseId,
  );

  Future<void> _closeCase() async {
    if (_closing || !_formKey.currentState!.validate()) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close this case?'),
        content: Text(
          _result!.isResolved
              ? 'The outcome will be added to the audit timeline. A closed '
                    'case cannot be reopened.'
              : "The case will be closed as unresolved: the elder's safety "
                    'has not been confirmed. This will be recorded in the '
                    'audit timeline and the case cannot be reopened.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Close case'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _closing = true);
    try {
      await _repository.closeCase(
        caseId: _caseId!,
        actionTaken: _actionTaken!,
        result: _result!,
        closureReason: _closureReason!,
        notes: _notes.text,
      );
      // Replace this form so closing never stacks another closed-case screen.
      if (mounted) _showClosedCase();
    } catch (error) {
      if (!mounted) return;
      setState(() => _closing = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Could not close case: ${describeCaseError(error)}'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuditOutcomeCloseCaseScreen._mint,
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: Color(0xFF073F42),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 21),
        ),
        title: const Text(
          'CareLink',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 18),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: Icon(Icons.person_rounded, color: Color(0xFF073F42), size: 19),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned(
            top: -72,
            right: -70,
            child: _SoftCircle(size: 176),
          ),
          SafeArea(
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: FutureBuilder<_OutcomeView?>(
                  future: _view,
                  builder: (context, snapshot) => SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Case Outcome',
                          style: TextStyle(
                            color: AuditOutcomeCloseCaseScreen._darkTeal,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Record the actions taken and close the case.',
                          style: TextStyle(
                            color: AuditOutcomeCloseCaseScreen._secondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._content(snapshot),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _content(AsyncSnapshot<_OutcomeView?> snapshot) {
    if (snapshot.hasError) {
      return [
        CoordinatorCaseMessage(
          icon: Icons.error_outline_rounded,
          title: 'Could not load this case.',
          message: describeCaseError(snapshot.error!),
          actionLabel: 'Try again',
          onAction: _reload,
        ),
      ];
    }
    final view = snapshot.data;
    if (view == null) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const [CoordinatorCaseMessage.loading()];
      }
      return [
        CoordinatorCaseMessage(
          icon: Icons.search_off_rounded,
          title: _caseId == null ? 'No case selected.' : 'Case not found.',
          message: 'Open a case from the Safety Cases list.',
        ),
      ];
    }

    final safetyCase = view.safetyCase;
    if (safetyCase.isClosed) {
      return [
        _CaseCard(safetyCase: safetyCase),
        CoordinatorCaseMessage(
          icon: Icons.check_circle_outline_rounded,
          title: 'This case is already closed.',
          actionLabel: 'View closed case',
          onAction: _showClosedCase,
        ),
      ];
    }

    // Options that rely on an approved contact are only offered when consent
    // names one.
    final canContact = view.consent.canContactApprovedPerson;
    final actions = [
      for (final action in CaseActionTaken.values)
        if (canContact || action != CaseActionTaken.contactedApprovedPerson)
          action,
    ];
    final results = [
      for (final result in CaseOutcomeResult.values)
        if (canContact || !result.requiresApprovedContact) result,
    ];
    final result = _result;
    final unresolved = result != null && !result.isResolved;
    final reasons = [
      for (final reason in CaseClosureReason.values)
        if (result == null || reason.allows(result)) reason,
    ];

    return [
      _CaseCard(safetyCase: safetyCase),
      const SizedBox(height: 16),
      Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _FieldLabel('Action Taken'),
            const SizedBox(height: 6),
            DropdownButtonFormField<CaseActionTaken>(
              key: const ValueKey('actionTakenField'),
              initialValue: _actionTaken,
              isExpanded: true,
              hint: const Text('Select action taken', style: _hintStyle),
              icon: const Icon(Icons.keyboard_arrow_down,
                  size: 22, color: AuditOutcomeCloseCaseScreen._teal),
              style: _fieldTextStyle,
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(11),
              decoration: _fieldDecoration(),
              items: [
                for (final action in actions)
                  DropdownMenuItem(value: action, child: Text(action.label)),
              ],
              validator: (value) =>
                  value == null ? 'Select the action taken.' : null,
              onChanged: _closing
                  ? null
                  : (value) => setState(() => _actionTaken = value),
            ),
            const SizedBox(height: 13),
            const _FieldLabel('Outcome'),
            const SizedBox(height: 6),
            DropdownButtonFormField<CaseOutcomeResult>(
              key: const ValueKey('outcomeField'),
              initialValue: _result,
              isExpanded: true,
              hint: const Text('Select outcome', style: _hintStyle),
              icon: const Icon(Icons.keyboard_arrow_down,
                  size: 22, color: AuditOutcomeCloseCaseScreen._teal),
              style: _fieldTextStyle,
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(11),
              decoration: _fieldDecoration(),
              items: [
                for (final result in results)
                  DropdownMenuItem(value: result, child: Text(result.label)),
              ],
              validator: (value) => value == null ? 'Select the outcome.' : null,
              onChanged: _closing
                  ? null
                  : (value) => setState(() {
                        _result = value;
                        // Drop a reason the new outcome no longer allows.
                        final reason = _closureReason;
                        if (value != null &&
                            reason != null &&
                            !reason.allows(value)) {
                          _closureReason = null;
                        }
                      }),
            ),
            if (unresolved) ...[
              const SizedBox(height: 8),
              const _UnresolvedNotice(),
            ],
            const SizedBox(height: 13),
            const _FieldLabel('Closure Reason'),
            const SizedBox(height: 6),
            // Rebuilt when the allowed reasons change so a cleared selection
            // is not kept by the field.
            KeyedSubtree(
              key: ValueKey(reasons.length),
              child: DropdownButtonFormField<CaseClosureReason>(
                key: const ValueKey('closureReasonField'),
                initialValue: _closureReason,
                isExpanded: true,
                hint: const Text('Select closure reason', style: _hintStyle),
                icon: const Icon(Icons.keyboard_arrow_down,
                    size: 22, color: AuditOutcomeCloseCaseScreen._teal),
                style: _fieldTextStyle,
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(11),
                decoration: _fieldDecoration(),
                items: [
                  for (final reason in reasons)
                    DropdownMenuItem(value: reason, child: Text(reason.label)),
                ],
                validator: (value) =>
                    value == null ? 'Select the closure reason.' : null,
                onChanged: _closing
                    ? null
                    : (value) => setState(() => _closureReason = value),
              ),
            ),
            const SizedBox(height: 13),
            _FieldLabel(unresolved ? 'Notes (required)' : 'Notes (optional)'),
            const SizedBox(height: 6),
            TextFormField(
              key: const ValueKey('notesField'),
              controller: _notes,
              enabled: !_closing,
              minLines: 3,
              maxLines: 5,
              maxLength: AuditOutcomeCloseCaseScreen.notesMaxLength,
              style: _fieldTextStyle,
              decoration: _fieldDecoration().copyWith(
                hintText: unresolved
                    ? 'Explain why the case is closed without confirming '
                          'safety.'
                    : 'Add details for the audit record.',
                hintStyle: _hintStyle,
              ),
              validator: (value) =>
                  unresolved && (value == null || value.trim().isEmpty)
                  ? 'Add notes explaining the unresolved outcome.'
                  : null,
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 46,
              child: ElevatedButton(
                onPressed: _closing ? null : _closeCase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AuditOutcomeCloseCaseScreen._coral,
                  foregroundColor: Colors.white,
                  overlayColor: AuditOutcomeCloseCaseScreen._darkCoral,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _closing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Close Case',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    ];
  }
}

class _CaseCard extends StatelessWidget {
  const _CaseCard({required this.safetyCase});

  final SafetyCase safetyCase;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 23,
              backgroundColor: AuditOutcomeCloseCaseScreen._lightTeal,
              child: Icon(Icons.person_rounded,
                  size: 27, color: AuditOutcomeCloseCaseScreen._teal),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    safetyCase.elderDisplayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AuditOutcomeCloseCaseScreen._darkTeal,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (safetyCase.elderRelationship != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      safetyCase.elderRelationship!,
                      style: const TextStyle(
                        color: AuditOutcomeCloseCaseScreen._secondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    safetyCase.caseLabel,
                    style: const TextStyle(
                      color: AuditOutcomeCloseCaseScreen._muted,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

/// Warns that the chosen outcome does not confirm the elder is safe.
class _UnresolvedNotice extends StatelessWidget {
  const _UnresolvedNotice();

  @override
  Widget build(BuildContext context) => Container(
        key: const ValueKey('unresolvedOutcomeNotice'),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: AuditOutcomeCloseCaseScreen._lightWarning,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded,
                size: 17, color: AuditOutcomeCloseCaseScreen._warning),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "Unresolved outcome. The elder's safety has not been "
                'confirmed, and the case will be recorded as unresolved.',
                style: TextStyle(
                  color: AuditOutcomeCloseCaseScreen._warning,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: AuditOutcomeCloseCaseScreen._darkTeal,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      );
}

const _fieldTextStyle = TextStyle(
  color: AuditOutcomeCloseCaseScreen._primaryText,
  fontSize: 12.5,
);

const _hintStyle = TextStyle(
  color: AuditOutcomeCloseCaseScreen._muted,
  fontSize: 12.5,
);

InputDecoration _fieldDecoration() {
  OutlineInputBorder border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(color: color),
      );
  return InputDecoration(
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    contentPadding: const EdgeInsets.fromLTRB(13, 12, 10, 12),
    border: border(AuditOutcomeCloseCaseScreen._line),
    enabledBorder: border(AuditOutcomeCloseCaseScreen._line),
    disabledBorder: border(AuditOutcomeCloseCaseScreen._line),
    focusedBorder: border(AuditOutcomeCloseCaseScreen._teal),
    errorBorder: border(AuditOutcomeCloseCaseScreen._coral),
    focusedErrorBorder: border(AuditOutcomeCloseCaseScreen._coral),
  );
}

BoxDecoration _cardDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AuditOutcomeCloseCaseScreen._line),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A073F42),
          blurRadius: 10,
          offset: Offset(0, 2),
        ),
      ],
    );

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFFE7F6F1),
          shape: BoxShape.circle,
        ),
      );
}
