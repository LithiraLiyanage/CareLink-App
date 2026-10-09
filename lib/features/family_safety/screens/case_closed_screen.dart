import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../coordinator/coordinator_case_scope.dart';
import '../../coordinator/coordinator_case_ui.dart';
import '../../coordinator/models/case_audit_event.dart';
import '../../coordinator/models/safety_case.dart';

/// Coordinator view confirming a safety case has been closed, with the audit
/// timeline from the repository. Opened with the case id as route argument.
class CaseClosedScreen extends StatefulWidget {
  const CaseClosedScreen({super.key, this.caseId});

  /// Case to show; when null the route argument is used.
  final String? caseId;

  static const _teal = Color(0xFF00776F);
  static const _darkTeal = Color(0xFF073F42);
  static const _coral = Color(0xFFFF5369);
  static const _darkCoral = Color(0xFFE63E55);
  static const _mint = Color(0xFFF5FBF9);
  static const _lightTeal = Color(0xFFE7F6F1);
  static const _secondary = Color(0xFF708486);
  static const _muted = Color(0xFF9AABAC);
  static const _line = Color(0xFFD1EBE7);
  static const _success = Color(0xFF00A878);
  static const _lightSuccess = Color(0xFFDFF5ED);
  static const _timelineLine = Color(0xFFB5DFD2);
  static const _warning = Color(0xFFF59E0B);
  static const _darkWarning = Color(0xFFB26A00);
  static const _lightWarning = Color(0xFFFFF4DF);

  @override
  State<CaseClosedScreen> createState() => _CaseClosedScreenState();
}

class _CaseClosedScreenState extends State<CaseClosedScreen> {
  String? _caseId;
  Future<SafetyCase?>? _case;
  Stream<List<CaseAuditEvent>>? _events;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_case != null) return;
    _caseId = widget.caseId ?? caseIdFromRoute(context);
    _load();
  }

  void _load() {
    final repository = CoordinatorCaseScope.of(context);
    final caseId = _caseId;
    _case = caseId == null ? Future.value() : repository.getCase(caseId);
    _events = caseId == null ? null : repository.watchAuditEvents(caseId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CaseClosedScreen._mint,
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FutureBuilder<SafetyCase?>(
                        future: _case,
                        builder: (context, snapshot) => _buildHeader(snapshot),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Audit Timeline',
                        style: TextStyle(
                          color: CaseClosedScreen._darkTeal,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<List<CaseAuditEvent>>(
                        stream: _events,
                        builder: (context, snapshot) => _buildTimeline(snapshot),
                      ),
                      const SizedBox(height: 22),
                      const _BackToListButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AsyncSnapshot<SafetyCase?> snapshot) {
    if (snapshot.hasError) {
      return CoordinatorCaseMessage(
        icon: Icons.error_outline_rounded,
        title: 'Could not load this case.',
        message: describeCaseError(snapshot.error!),
      );
    }
    if (snapshot.connectionState != ConnectionState.done) {
      return const CoordinatorCaseMessage.loading();
    }
    final safetyCase = snapshot.data;
    if (safetyCase == null) {
      return CoordinatorCaseMessage(
        icon: Icons.search_off_rounded,
        title: _caseId == null ? 'No case selected.' : 'Case not found.',
        message: 'Open a case from the Safety Cases list.',
      );
    }
    final closed = safetyCase.isClosed;
    // A case closed without an outcome is not presented as resolved.
    final resolved = safetyCase.outcome?.isResolved ?? false;
    final String subtitle;
    if (!closed) {
      subtitle = 'This safety case is still open.';
    } else if (resolved) {
      subtitle = 'This safety case has been closed as resolved.';
    } else {
      subtitle =
          "This safety case was closed as unresolved. The elder's safety "
          'was not confirmed.';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (closed) Center(child: _ClosedBadge(resolved: resolved)),
        if (closed) const SizedBox(height: 14),
        Text(
          closed ? 'Case Closed' : 'Case Open',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: CaseClosedScreen._darkTeal,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: closed && !resolved
                ? CaseClosedScreen._darkWarning
                : CaseClosedScreen._secondary,
            fontSize: 12,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 18),
        _CaseCard(safetyCase: safetyCase),
      ],
    );
  }

  Widget _buildTimeline(AsyncSnapshot<List<CaseAuditEvent>> snapshot) {
    if (_events == null) return const SizedBox.shrink();
    if (snapshot.hasError) {
      return CoordinatorCaseMessage(
        icon: Icons.error_outline_rounded,
        title: 'Could not load the audit timeline.',
        message: describeCaseError(snapshot.error!),
        actionLabel: 'Try again',
        onAction: () => setState(_load),
      );
    }
    final events = snapshot.data;
    if (events == null) return const CoordinatorCaseMessage.loading();
    if (events.isEmpty) {
      return const CoordinatorCaseMessage(
        icon: Icons.history_rounded,
        title: 'No audit events recorded.',
      );
    }
    return Column(
      children: [
        for (var i = 0; i < events.length; i++)
          _TimelineEntry(
            event: events[i],
            isFirst: i == 0,
            isLast: i == events.length - 1,
          ),
      ],
    );
  }
}

/// A check mark for a resolved closure, a warning mark for an unresolved one.
class _ClosedBadge extends StatelessWidget {
  const _ClosedBadge({required this.resolved});

  final bool resolved;

  @override
  Widget build(BuildContext context) => Container(
        width: 74,
        height: 74,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: resolved
              ? CaseClosedScreen._lightSuccess
              : CaseClosedScreen._lightWarning,
          shape: BoxShape.circle,
        ),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: resolved
                ? CaseClosedScreen._success
                : CaseClosedScreen._warning,
            shape: BoxShape.circle,
          ),
          child: Icon(
            resolved ? Icons.check_rounded : Icons.priority_high_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
      );
}

class _CaseCard extends StatelessWidget {
  const _CaseCard({required this.safetyCase});

  final SafetyCase safetyCase;

  @override
  Widget build(BuildContext context) {
    final outcome = safetyCase.outcome;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CaseClosedScreen._line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A073F42),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 23,
                backgroundColor: CaseClosedScreen._lightTeal,
                child: Icon(Icons.person_rounded,
                    size: 27, color: CaseClosedScreen._teal),
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
                        color: CaseClosedScreen._darkTeal,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (safetyCase.elderRelationship != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        safetyCase.elderRelationship!,
                        style: const TextStyle(
                          color: CaseClosedScreen._secondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      safetyCase.caseLabel,
                      style: const TextStyle(
                        color: CaseClosedScreen._muted,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (outcome != null) ...[
            const Divider(height: 20, color: CaseClosedScreen._lightTeal),
            _OutcomeLine(
              'Resolution',
              outcome.resolutionLabel,
              valueColor: outcome.isResolved
                  ? CaseClosedScreen._darkTeal
                  : CaseClosedScreen._darkWarning,
            ),
            _OutcomeLine('Action taken', outcome.actionTaken.label),
            _OutcomeLine('Outcome', outcome.result.label),
            _OutcomeLine('Closure reason', outcome.closureReason.label),
            _OutcomeLine('Closed', formatCaseDateTime(outcome.recordedAt)),
            if (outcome.notes.isNotEmpty) _OutcomeLine('Notes', outcome.notes),
          ],
        ],
      ),
    );
  }
}

class _OutcomeLine extends StatelessWidget {
  const _OutcomeLine(
    this.label,
    this.value, {
    this.valueColor = CaseClosedScreen._darkTeal,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text.rich(
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              color: CaseClosedScreen._secondary,
              fontWeight: FontWeight.w500,
            ),
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  color: valueColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          style: const TextStyle(fontSize: 11, height: 1.35),
        ),
      );
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.event,
    required this.isFirst,
    required this.isLast,
  });

  final CaseAuditEvent event;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    // The final node is slightly larger with a soft ring to mark completion.
    final nodeSize = isLast ? 12.0 : 9.0;
    final topGap = isLast ? 2.5 : 4.0;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 64,
            child: Padding(
              padding: const EdgeInsets.only(top: 1.5),
              child: Text(
                '${formatCaseDayMonth(event.occurredAt)}\n'
                '${formatCaseTime(event.occurredAt)}',
                style: const TextStyle(
                  color: CaseClosedScreen._muted,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 1.5,
                  height: topGap,
                  color: isFirst
                      ? Colors.transparent
                      : CaseClosedScreen._timelineLine,
                ),
                Container(
                  width: nodeSize,
                  height: nodeSize,
                  decoration: BoxDecoration(
                    color: CaseClosedScreen._success,
                    shape: BoxShape.circle,
                    border: isLast
                        ? Border.all(
                            color: CaseClosedScreen._lightSuccess, width: 2)
                        : null,
                    boxShadow: isLast
                        ? const [
                            BoxShadow(
                              color: Color(0x3300A878),
                              blurRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 1.5,
                    color: isLast
                        ? Colors.transparent
                        : CaseClosedScreen._timelineLine,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.type.label,
                    style: TextStyle(
                      color: CaseClosedScreen._darkTeal,
                      fontSize: 11,
                      height: 1.3,
                      fontWeight: isLast ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  Text(
                    'By ${event.actor.label}',
                    style: const TextStyle(
                      color: CaseClosedScreen._muted,
                      fontSize: 9.5,
                      height: 1.35,
                    ),
                  ),
                  if (event.result.isNotEmpty)
                    Text(
                      event.result,
                      style: const TextStyle(
                        color: CaseClosedScreen._darkTeal,
                        fontSize: 10,
                        height: 1.35,
                      ),
                    ),
                  if (event.note.isNotEmpty)
                    Text(
                      event.note,
                      style: const TextStyle(
                        color: CaseClosedScreen._secondary,
                        fontSize: 10,
                        height: 1.35,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackToListButton extends StatelessWidget {
  const _BackToListButton();

  /// Returns to the case list already in the stack, dropping the case flow
  /// screens; pushes a fresh case list if it was never opened.
  void _backToCaseList(BuildContext context) {
    var found = false;
    Navigator.of(context).popUntil((route) {
      if (route.settings.name == AppRoutes.coordinatorCaseList) found = true;
      return found || route.isFirst;
    });
    if (!found) Navigator.of(context).pushNamed(AppRoutes.coordinatorCaseList);
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 46,
        child: ElevatedButton(
          onPressed: () => _backToCaseList(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: CaseClosedScreen._coral,
            foregroundColor: Colors.white,
            overlayColor: CaseClosedScreen._darkCoral,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Back to Case List',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      );
}

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
