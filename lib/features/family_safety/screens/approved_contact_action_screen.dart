import 'package:flutter/material.dart';

import '../../coordinator/coordinator_case_scope.dart';
import '../../coordinator/coordinator_case_ui.dart';
import '../../coordinator/models/elder_consent_context.dart';
import '../../coordinator/models/safety_case.dart';
import '../../coordinator/services/coordinator_case_repository.dart';

typedef _ContactView = ({SafetyCase safetyCase, ElderConsentContext consent});

/// Coordinator view for following up with the elder's approved person after
/// a missed check-in, opened with the case id as the route argument.
///
/// Shows the approved contact and the reason for contact. CareLink does not
/// place calls or send messages.
class ApprovedContactActionScreen extends StatefulWidget {
  const ApprovedContactActionScreen({super.key, this.caseId});

  /// Case to show; when null the route argument is used.
  final String? caseId;

  static const _teal = Color(0xFF00776F);
  static const _darkTeal = Color(0xFF073F42);
  static const _mint = Color(0xFFF5FBF9);
  static const _lightTeal = Color(0xFFE7F6F1);
  static const _secondary = Color(0xFF708486);
  static const _line = Color(0xFFD1EBE7);
  static const _success = Color(0xFF00A878);
  static const _lightSuccess = Color(0xFFDFF5ED);
  static const _warning = Color(0xFFF59E0B);
  static const _lightWarning = Color(0xFFFFF4DF);
  static const _info = Color(0xFF2196F3);
  static const _lightInfo = Color(0xFFE8F3FF);
  static const _infoText = Color(0xFF345B70);

  @override
  State<ApprovedContactActionScreen> createState() =>
      _ApprovedContactActionScreenState();
}

class _ApprovedContactActionScreenState
    extends State<ApprovedContactActionScreen> {
  late CoordinatorCaseRepository _repository;
  String? _caseId;
  Future<_ContactView?>? _view;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_view != null) return;
    _repository = CoordinatorCaseScope.of(context);
    _caseId = widget.caseId ?? caseIdFromRoute(context);
    _view = _load();
  }

  Future<_ContactView?> _load() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApprovedContactActionScreen._mint,
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
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: FutureBuilder<_ContactView?>(
                  future: _view,
                  builder: (context, snapshot) => SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Approved Contact',
                          style: TextStyle(
                            color: ApprovedContactActionScreen._darkTeal,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Contact the approved person for follow-up.',
                          style: TextStyle(
                            color: ApprovedContactActionScreen._secondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
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

  List<Widget> _content(AsyncSnapshot<_ContactView?> snapshot) {
    if (snapshot.hasError) {
      return [
        CoordinatorCaseMessage(
          icon: Icons.error_outline_rounded,
          title: 'Could not load the approved contact.',
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

    final contact = view.consent.approvedContact;
    if (!view.consent.canContactApprovedPerson || contact == null) {
      return const [
        CoordinatorCaseMessage(
          icon: Icons.lock_outline_rounded,
          title: 'Contact unavailable.',
          message:
              'No approved consent and contact are recorded for this elder. '
              'Review consent before contacting anyone.',
        ),
      ];
    }

    return [
      _ContactCard(contact: contact),
      const SizedBox(height: 16),
      _ReasonCard(safetyCase: view.safetyCase),
      const SizedBox(height: 16),
      const _InfoNote(
        'Only contact the person approved by the older adult. CareLink '
        'records these actions but does not place calls or send messages.',
      ),
    ];
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.contact});

  final ApprovedContact contact;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 23,
              backgroundColor: ApprovedContactActionScreen._lightTeal,
              child: Icon(Icons.person_rounded,
                  size: 27, color: ApprovedContactActionScreen._teal),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ApprovedContactActionScreen._darkTeal,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    contact.relationship,
                    style: const TextStyle(
                      color: ApprovedContactActionScreen._secondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const _ApprovedChip(),
          ],
        ),
      );
}

class _ApprovedChip extends StatelessWidget {
  const _ApprovedChip();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: ApprovedContactActionScreen._lightSuccess,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle,
                size: 12, color: ApprovedContactActionScreen._success),
            SizedBox(width: 4),
            Text(
              'Approved',
              style: TextStyle(
                color: ApprovedContactActionScreen._success,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}

class _ReasonCard extends StatelessWidget {
  const _ReasonCard({required this.safetyCase});

  final SafetyCase safetyCase;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Reason for Contact',
              style: TextStyle(
                color: ApprovedContactActionScreen._darkTeal,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ApprovedContactActionScreen._lightWarning,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline,
                      size: 20, color: ApprovedContactActionScreen._warning),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          safetyCase.reason.label,
                          style: const TextStyle(
                            color: ApprovedContactActionScreen._darkTeal,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "${safetyCase.elderDisplayName}'s check-in scheduled "
                          'for ${formatCaseDateTime(safetyCase.scheduledAt)} '
                          'was not completed.',
                          style: const TextStyle(
                            color: ApprovedContactActionScreen._secondary,
                            fontSize: 10.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _InfoNote extends StatelessWidget {
  const _InfoNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: ApprovedContactActionScreen._lightInfo,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline,
                size: 18, color: ApprovedContactActionScreen._info),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: ApprovedContactActionScreen._infoText,
                  fontSize: 10.5,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
}

BoxDecoration _cardDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: ApprovedContactActionScreen._line),
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
