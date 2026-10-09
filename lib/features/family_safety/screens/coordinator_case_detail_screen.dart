import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../coordinator/coordinator_case_scope.dart';
import '../../coordinator/coordinator_case_ui.dart';
import '../../coordinator/models/case_outcome.dart';
import '../../coordinator/models/elder_consent_context.dart';
import '../../coordinator/models/safety_case.dart';
import '../../coordinator/services/coordinator_case_repository.dart';

typedef _CaseView = ({SafetyCase safetyCase, ElderConsentContext consent});

/// Detail view for one coordinator safety case, opened with its case id as
/// the route argument.
class CoordinatorCaseDetailScreen extends StatefulWidget {
  const CoordinatorCaseDetailScreen({super.key, this.caseId});

  /// Case to show; when null the route argument is used.
  final String? caseId;

  static const _teal = Color(0xFF00776F);
  static const _darkTeal = Color(0xFF073F42);
  static const _mint = Color(0xFFF5FBF9);
  static const _lightTeal = Color(0xFFE7F6F1);
  static const _secondary = Color(0xFF708486);
  static const _line = Color(0xFFD1EBE7);
  static const _orange = Color(0xFFF59E0B);
  static const _muted = Color(0xFF9AABAC);

  @override
  State<CoordinatorCaseDetailScreen> createState() =>
      _CoordinatorCaseDetailScreenState();
}

class _CoordinatorCaseDetailScreenState
    extends State<CoordinatorCaseDetailScreen> {
  late CoordinatorCaseRepository _repository;
  String? _caseId;
  Future<_CaseView?>? _view;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_view != null) return;
    _repository = CoordinatorCaseScope.of(context);
    _caseId = widget.caseId ?? caseIdFromRoute(context);
    _view = _load();
  }

  Future<_CaseView?> _load() async {
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

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _record(
    CaseAction action, {
    String note = '',
    required String success,
  }) async {
    setState(() => _busy = true);
    try {
      await _repository.recordCaseAction(
        caseId: _caseId!,
        action: action,
        note: note,
      );
      _showMessage(success);
    } catch (error) {
      _showMessage('Could not record action: ${describeCaseError(error)}');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _view = _load();
        });
      }
    }
  }

  Future<void> _retry(SafetyCase safetyCase) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retry check-in?'),
        content: Text(
          "This records a retry request for ${safetyCase.elderDisplayName}'s "
          'missed check-in. It does not change their check-in schedule.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Request retry'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _record(
      CaseAction.retryCheckIn,
      success: 'Check-in retry requested.',
    );
  }

  Future<void> _reschedule() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: today.add(const Duration(days: 1)),
      firstDate: today,
      lastDate: today.add(const Duration(days: 60)),
      helpText: 'Reschedule check-in',
    );
    if (picked == null) return;
    final date = formatCaseDate(picked);
    // Only the request is recorded; Elder Check-in schedules are not changed.
    await _record(
      CaseAction.rescheduleCheckIn,
      note: 'Requested new check-in date: $date',
      success: 'Reschedule request recorded for $date.',
    );
  }

  Future<void> _open(String route) async {
    await Navigator.pushNamed(context, route, arguments: _caseId);
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoordinatorCaseDetailScreen._mint,
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
                child: FutureBuilder<_CaseView?>(
                  future: _view,
                  builder: (context, snapshot) => SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
                    child: _buildContent(snapshot),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AsyncSnapshot<_CaseView?> snapshot) {
    if (snapshot.hasError) {
      return CoordinatorCaseMessage(
        icon: Icons.error_outline_rounded,
        title: 'Could not load this case.',
        message: describeCaseError(snapshot.error!),
        actionLabel: 'Try again',
        onAction: _reload,
      );
    }
    final view = snapshot.data;
    if (view == null) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const CoordinatorCaseMessage.loading();
      }
      return CoordinatorCaseMessage(
        icon: Icons.search_off_rounded,
        title: _caseId == null ? 'No case selected.' : 'Case not found.',
        message: 'Open a case from the Safety Cases list.',
      );
    }

    final safetyCase = view.safetyCase;
    final consent = view.consent;
    final status = caseStatusColors(safetyCase.status);
    final isOpen = !safetyCase.isClosed && !_busy;
    final canContact = consent.canContactApprovedPerson;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                safetyCase.caseLabel,
                style: const TextStyle(
                  color: CoordinatorCaseDetailScreen._darkTeal,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: status.background,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                safetyCase.status.label,
                style: TextStyle(
                  color: status.foreground,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ProfileCard(safetyCase: safetyCase),
        const SizedBox(height: 10),
        _CaseDetailsCard(safetyCase: safetyCase, consent: consent),
        const SizedBox(height: 16),
        const _SectionTitle('Actions'),
        const SizedBox(height: 8),
        _ActionRow(
          icon: Icons.phone_outlined,
          label: 'Retry',
          subtitle: safetyCase.isClosed ? 'Case is closed' : null,
          onTap: isOpen ? () => _retry(safetyCase) : null,
        ),
        const SizedBox(height: 7),
        _ActionRow(
          icon: Icons.calendar_month_outlined,
          label: 'Reschedule',
          subtitle: safetyCase.isClosed ? 'Case is closed' : null,
          onTap: isOpen ? _reschedule : null,
        ),
        const SizedBox(height: 7),
        _ActionRow(
          icon: Icons.shield_outlined,
          label: 'Review Consent',
          onTap: _busy ? null : () => _open(AppRoutes.consentContextReview),
        ),
        const SizedBox(height: 7),
        _ActionRow(
          icon: Icons.person_outline,
          label: 'Contact Approved Person',
          subtitle: safetyCase.isClosed
              ? 'Case is closed'
              : canContact
              ? consent.approvedContact!.displayLabel
              : 'No approved consent and contact on record',
          onTap: isOpen && canContact
              ? () => _open(AppRoutes.approvedContactAction)
              : null,
        ),
        const SizedBox(height: 7),
        if (safetyCase.isClosed)
          _ActionRow(
            icon: Icons.history_rounded,
            label: 'View Audit Timeline',
            onTap: () => _open(AppRoutes.caseClosed),
          )
        else
          _ActionRow(
            icon: Icons.assignment_turned_in_outlined,
            label: 'Record Outcome & Close',
            onTap: isOpen ? () => _open(AppRoutes.auditOutcomeCloseCase) : null,
          ),
        if (_repository.usesMockData) ...[
          const SizedBox(height: 12),
          const CoordinatorMockDataNote(
            'Showing mock case data. Not connected to live sessions.',
          ),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: CoordinatorCaseDetailScreen._darkTeal,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      );
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.safetyCase});

  final SafetyCase safetyCase;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 26,
              backgroundColor: CoordinatorCaseDetailScreen._lightTeal,
              child: Icon(Icons.person_rounded,
                  size: 30, color: CoordinatorCaseDetailScreen._teal),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(safetyCase.elderDisplayName,
                      style: const TextStyle(
                        color: CoordinatorCaseDetailScreen._darkTeal,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      )),
                  if (safetyCase.elderRelationship != null) ...[
                    const SizedBox(height: 2),
                    Text(safetyCase.elderRelationship!,
                        style: const TextStyle(
                            color: CoordinatorCaseDetailScreen._secondary,
                            fontSize: 12)),
                  ],
                  const SizedBox(height: 2),
                  Text('Elder ID: ${safetyCase.elderReference}',
                      style: const TextStyle(
                          color: CoordinatorCaseDetailScreen._muted,
                          fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      );
}

/// Compact summary of the missed check-in and the elder's consent. Only
/// fields stored on the case and consent record are shown; full consent
/// details are on the Consent Context Review screen.
class _CaseDetailsCard extends StatelessWidget {
  const _CaseDetailsCard({required this.safetyCase, required this.consent});

  final SafetyCase safetyCase;
  final ElderConsentContext consent;

  @override
  Widget build(BuildContext context) {
    final attempts = safetyCase.previousAttempts;
    final summary = consentSummary(consent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _InformationRow(
            icon: Icons.calendar_today_outlined,
            label: 'Scheduled Time',
            value: formatCaseDateTime(safetyCase.scheduledAt),
          ),
          _InformationRow(
            icon: Icons.error_outline_rounded,
            label: 'Status',
            value: safetyCase.reason.label,
            valueColor: CoordinatorCaseDetailScreen._orange,
            indicatorColor: CoordinatorCaseDetailScreen._orange,
          ),
          _InformationRow(
            icon: Icons.phone_outlined,
            label: 'Previous Attempts',
            value: '$attempts attempt${attempts == 1 ? '' : 's'}',
          ),
          _InformationRow(
            icon: Icons.shield_outlined,
            label: 'Consent',
            value: summary.label,
            valueColor: summary.color,
            indicatorColor: summary.color,
            last: true,
          ),
        ],
      ),
    );
  }
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = CoordinatorCaseDetailScreen._darkTeal,
    this.indicatorColor,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;
  final Color? indicatorColor;
  final bool last;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 42),
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(
                  bottom: BorderSide(color: Color(0xFFE7F6F1)),
                ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: CoordinatorCaseDetailScreen._teal),
            const SizedBox(width: 9),
            Expanded(
              flex: 5,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: CoordinatorCaseDetailScreen._secondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 7,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (indicatorColor != null) ...[
                    Icon(Icons.circle, size: 7, color: indicatorColor),
                    const SizedBox(width: 5),
                  ],
                  Flexible(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: valueColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = enabled
        ? CoordinatorCaseDetailScreen._teal
        : CoordinatorCaseDetailScreen._muted;
    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(11),
          side: const BorderSide(color: CoordinatorCaseDetailScreen._line),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 50),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            child: Row(
              children: [
                Icon(icon, size: 21, color: color),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: enabled
                              ? CoordinatorCaseDetailScreen._darkTeal
                              : CoordinatorCaseDetailScreen._muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: CoordinatorCaseDetailScreen._secondary,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 20, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: CoordinatorCaseDetailScreen._line),
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
