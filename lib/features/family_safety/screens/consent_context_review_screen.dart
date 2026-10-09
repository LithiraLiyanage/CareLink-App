import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../coordinator/coordinator_case_scope.dart';
import '../../coordinator/coordinator_case_ui.dart';
import '../../coordinator/models/elder_consent_context.dart';
import '../../coordinator/models/safety_case.dart';
import '../../coordinator/services/coordinator_case_repository.dart';

typedef _ConsentView = ({SafetyCase safetyCase, ElderConsentContext consent});

/// Coordinator view of an older adult's consent and shared context, opened
/// with the case id as the route argument.
///
/// Only what the repository records is shown; nothing is assumed when consent
/// is not recorded.
class ConsentContextReviewScreen extends StatefulWidget {
  const ConsentContextReviewScreen({super.key, this.caseId});

  /// Case to show; when null the route argument is used.
  final String? caseId;

  static const _teal = Color(0xFF00776F);
  static const _darkTeal = Color(0xFF073F42);
  static const _mint = Color(0xFFF5FBF9);
  static const _lightTeal = Color(0xFFE7F6F1);
  static const _primaryText = Color(0xFF073F42);
  static const _secondary = Color(0xFF708486);
  static const _muted = Color(0xFF9AABAC);
  static const _line = Color(0xFFD1EBE7);
  static const _success = Color(0xFF00A878);
  static const _lightSuccess = Color(0xFFDFF5ED);
  static const _restricted = Color(0xFFE53935);
  static const _lightRed = Color(0xFFFFF0F0);
  static const _warning = Color(0xFFF59E0B);
  static const _lightWarning = Color(0xFFFFF4DF);

  @override
  State<ConsentContextReviewScreen> createState() =>
      _ConsentContextReviewScreenState();
}

class _ConsentContextReviewScreenState
    extends State<ConsentContextReviewScreen> {
  late CoordinatorCaseRepository _repository;
  String? _caseId;
  Future<_ConsentView?>? _view;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_view != null) return;
    _repository = CoordinatorCaseScope.of(context);
    _caseId = widget.caseId ?? caseIdFromRoute(context);
    _view = _load();
  }

  Future<_ConsentView?> _load() async {
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
      backgroundColor: ConsentContextReviewScreen._mint,
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
          const Positioned(top: -72, right: -70, child: _SoftCircle(size: 176)),
          SafeArea(
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: FutureBuilder<_ConsentView?>(
                  future: _view,
                  builder: (context, snapshot) => SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Consent & Context',
                          style: TextStyle(
                            color: ConsentContextReviewScreen._darkTeal,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          "Review the elder's consent preferences.",
                          style: TextStyle(
                            color: ConsentContextReviewScreen._secondary,
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

  List<Widget> _content(AsyncSnapshot<_ConsentView?> snapshot) {
    if (snapshot.hasError) {
      return [
        CoordinatorCaseMessage(
          icon: Icons.error_outline_rounded,
          title: 'Could not load consent.',
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

    final consent = view.consent;
    final isApproved = consent.familySharing == ConsentSharingStatus.approved;
    final canContact =
        consent.canContactApprovedPerson && !view.safetyCase.isClosed;
    void openContact() => Navigator.of(context).pushNamed(
      AppRoutes.approvedContactAction,
      arguments: view.safetyCase.id,
    );

    return [
      _ProfileCard(
        safetyCase: view.safetyCase,
        onTap: canContact ? openContact : null,
      ),
      if (consent.isMock) ...[
        const SizedBox(height: 8),
        const CoordinatorMockDataNote(
          'Mock consent record for development. Not real consent.',
        ),
      ],
      const SizedBox(height: 16),
      const _SectionHeading('Consent Status'),
      const SizedBox(height: 7),
      _ConsentStatusCard(consent: consent),
      const SizedBox(height: 16),
      const _SectionHeading('Allowed Information'),
      const SizedBox(height: 7),
      _AllowedInformationCard(
        items: isApproved ? consent.allowedInformation : const [],
      ),
      const SizedBox(height: 16),
      const _SectionHeading('Restricted Information'),
      const SizedBox(height: 7),
      _RestrictedInformationCard(
        items: consent.restrictedInformation,
        everythingRestricted: !isApproved,
      ),
      const SizedBox(height: 16),
      if (consent.canContactApprovedPerson)
        _ContactButton(
          label: 'Contact ${consent.approvedContact!.name}',
          onPressed: canContact ? openContact : null,
        )
      else
        _ConsentWarning(status: consent.familySharing),
    ];
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: ConsentContextReviewScreen._darkTeal,
      fontSize: 15,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.safetyCase, this.onTap});

  final SafetyCase safetyCase;

  /// Opens the approved-contact screen; null when contact is not permitted.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 23,
              backgroundColor: ConsentContextReviewScreen._lightTeal,
              child: Icon(
                Icons.person_rounded,
                size: 27,
                color: ConsentContextReviewScreen._teal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    safetyCase.elderDisplayName,
                    style: const TextStyle(
                      color: ConsentContextReviewScreen._darkTeal,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (safetyCase.elderRelationship != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      safetyCase.elderRelationship!,
                      style: const TextStyle(
                        color: ConsentContextReviewScreen._secondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    'Elder ID: ${safetyCase.elderReference}',
                    style: const TextStyle(
                      color: ConsentContextReviewScreen._muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: ConsentContextReviewScreen._secondary,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _ConsentStatusCard extends StatelessWidget {
  const _ConsentStatusCard({required this.consent});

  final ElderConsentContext consent;

  @override
  Widget build(BuildContext context) {
    final contact = consent.approvedContact;
    final validFrom = consent.validFrom;
    final lastUpdated = consent.lastUpdatedAt;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _StatusRow(
            icon: Icons.groups_outlined,
            label: 'Family sharing',
            trailing: _SharingChip(consent.familySharing),
          ),
          _StatusRow(
            icon: Icons.person_outline,
            label: 'Approved Contact',
            trailing: contact == null
                ? const _StatusValue('None recorded')
                : _StatusValue(
                    contact.displayLabel,
                    color: ConsentContextReviewScreen._primaryText,
                    weight: FontWeight.w600,
                  ),
          ),
          _StatusRow(
            icon: Icons.calendar_today_outlined,
            label: 'Valid from',
            trailing: _StatusValue(
              validFrom == null ? 'Not recorded' : formatCaseDate(validFrom),
            ),
          ),
          _StatusRow(
            icon: Icons.update,
            label: 'Last updated',
            trailing: _StatusValue(
              lastUpdated == null ? 'Not recorded' : formatCaseDate(lastUpdated),
            ),
            last: true,
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.label,
    required this.trailing,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final Widget trailing;
  final bool last;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 42),
    padding: const EdgeInsets.symmetric(vertical: 7),
    decoration: BoxDecoration(
      border: last
          ? null
          : const Border(bottom: BorderSide(color: Color(0xFFE7F6F1))),
    ),
    child: Row(
      children: [
        Icon(icon, size: 18, color: ConsentContextReviewScreen._teal),
        const SizedBox(width: 9),
        Expanded(
          flex: 5,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ConsentContextReviewScreen._secondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 7,
          child: Align(alignment: Alignment.centerRight, child: trailing),
        ),
      ],
    ),
  );
}

class _StatusValue extends StatelessWidget {
  const _StatusValue(
    this.text, {
    this.color = ConsentContextReviewScreen._secondary,
    this.weight = FontWeight.w500,
  });

  final String text;
  final Color color;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    textAlign: TextAlign.right,
    style: TextStyle(color: color, fontSize: 11, fontWeight: weight),
  );
}

class _SharingChip extends StatelessWidget {
  const _SharingChip(this.status);

  final ConsentSharingStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = consentStatusColors(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: colors.foreground,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AllowedInformationCard extends StatelessWidget {
  const _AllowedInformationCard({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: _cardDecoration(),
    child: items.isEmpty
        ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No information sharing is recorded.',
              style: TextStyle(
                color: ConsentContextReviewScreen._secondary,
                fontSize: 12,
              ),
            ),
          )
        : Column(
            children: [
              for (var i = 0; i < items.length; i++)
                _AllowedRow(items[i], last: i == items.length - 1),
            ],
          ),
  );
}

class _AllowedRow extends StatelessWidget {
  const _AllowedRow(this.label, {this.last = false});

  final String label;
  final bool last;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 36),
    padding: const EdgeInsets.symmetric(vertical: 5),
    decoration: BoxDecoration(
      border: last
          ? null
          : const Border(bottom: BorderSide(color: Color(0xFFE7F6F1))),
    ),
    child: Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: ConsentContextReviewScreen._lightSuccess,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 15,
            color: ConsentContextReviewScreen._success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: ConsentContextReviewScreen._primaryText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

class _RestrictedInformationCard extends StatelessWidget {
  const _RestrictedInformationCard({
    required this.items,
    required this.everythingRestricted,
  });

  final List<String> items;

  /// True when sharing is not approved, so nothing may be shared.
  final bool everythingRestricted;

  @override
  Widget build(BuildContext context) {
    final rows = [
      if (everythingRestricted)
        ('All case information', 'Not shared without recorded consent')
      else if (items.isEmpty)
        ('No restrictions recorded', 'Share only the allowed information'),
      for (final item in items)
        if (!everythingRestricted) (item, 'Not accessible'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: _RestrictedRow(title: row.$1, detail: row.$2),
            ),
        ],
      ),
    );
  }
}

class _RestrictedRow extends StatelessWidget {
  const _RestrictedRow({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: ConsentContextReviewScreen._lightRed,
          borderRadius: BorderRadius.circular(9),
        ),
        child: const Icon(
          Icons.do_not_disturb_alt,
          size: 18,
          color: ConsentContextReviewScreen._restricted,
        ),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: ConsentContextReviewScreen._primaryText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              detail,
              style: const TextStyle(
                color: ConsentContextReviewScreen._restricted,
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 46,
    child: OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.person_outline, size: 19),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: ConsentContextReviewScreen._teal,
        side: const BorderSide(color: ConsentContextReviewScreen._line),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

class _ConsentWarning extends StatelessWidget {
  const _ConsentWarning({required this.status});

  final ConsentSharingStatus status;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: ConsentContextReviewScreen._lightWarning,
      borderRadius: BorderRadius.circular(11),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline,
          size: 18,
          color: ConsentContextReviewScreen._warning,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            switch (status) {
              ConsentSharingStatus.approved =>
                'No approved contact is named. Do not contact family '
                    'members on behalf of this elder.',
              ConsentSharingStatus.notRecorded =>
                'Consent is not recorded. Do not contact family members or '
                    'share case information on behalf of this elder.',
              ConsentSharingStatus.withdrawn =>
                'Consent was withdrawn. Do not contact family members or '
                    'share case information on behalf of this elder.',
            },
            style: const TextStyle(
              color: ConsentContextReviewScreen._primaryText,
              fontSize: 11,
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
  border: Border.all(color: ConsentContextReviewScreen._line),
  boxShadow: const [
    BoxShadow(color: Color(0x0A073F42), blurRadius: 10, offset: Offset(0, 2)),
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
