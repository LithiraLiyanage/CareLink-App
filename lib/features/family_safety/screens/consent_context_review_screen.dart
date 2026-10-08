import 'package:flutter/material.dart';

import '../../../app/routes.dart';

/// Static coordinator view of an older adult's consent and shared context.
class ConsentContextReviewScreen extends StatelessWidget {
  const ConsentContextReviewScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _mint,
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
                child: const SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(18, 6, 18, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Consent & Context',
                        style: TextStyle(
                          color: _darkTeal,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        "Review the elder's consent preferences.",
                        style: TextStyle(color: _secondary, fontSize: 12),
                      ),
                      SizedBox(height: 12),
                      _ProfileCard(),
                      SizedBox(height: 16),
                      _SectionHeading('Consent Status'),
                      SizedBox(height: 7),
                      _ConsentStatusCard(),
                      SizedBox(height: 16),
                      _SectionHeading('Allowed Information'),
                      SizedBox(height: 7),
                      _AllowedInformationCard(),
                      SizedBox(height: 16),
                      _SectionHeading('Restricted Information'),
                      SizedBox(height: 7),
                      _RestrictedInformationCard(),
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
  const _ProfileCard();

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.of(context).pushNamed(AppRoutes.approvedContactAction),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: _cardDecoration(),
        child: const Row(
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: ConsentContextReviewScreen._lightTeal,
              child: Icon(
                Icons.person_rounded,
                size: 27,
                color: ConsentContextReviewScreen._teal,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mrs. Silva',
                    style: TextStyle(
                      color: ConsentContextReviewScreen._darkTeal,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Mother',
                    style: TextStyle(
                      color: ConsentContextReviewScreen._secondary,
                      fontSize: 11,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Elder ID: EL001',
                    style: TextStyle(
                      color: ConsentContextReviewScreen._muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: ConsentContextReviewScreen._secondary,
            ),
          ],
        ),
      ),
    ),
  );
}

class _ConsentStatusCard extends StatelessWidget {
  const _ConsentStatusCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: _cardDecoration(),
    child: const Column(
      children: [
        _StatusRow(
          icon: Icons.groups_outlined,
          label: 'Family sharing',
          trailing: _ApprovedChip(),
        ),
        _StatusRow(
          icon: Icons.person_outline,
          label: 'Approved Contact',
          trailing: _StatusValue(
            'Jane Silva (Daughter)',
            color: ConsentContextReviewScreen._primaryText,
            weight: FontWeight.w600,
          ),
        ),
        _StatusRow(
          icon: Icons.calendar_today_outlined,
          label: 'Valid from',
          trailing: _StatusValue('1 Jan 2026'),
        ),
        _StatusRow(
          icon: Icons.update,
          label: 'Last updated',
          trailing: _StatusValue('15 Sep 2026'),
          last: true,
        ),
      ],
    ),
  );
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

class _ApprovedChip extends StatelessWidget {
  const _ApprovedChip();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: ConsentContextReviewScreen._lightSuccess,
      borderRadius: BorderRadius.circular(18),
    ),
    child: const Text(
      'Approved',
      style: TextStyle(
        color: ConsentContextReviewScreen._success,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _AllowedInformationCard extends StatelessWidget {
  const _AllowedInformationCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: _cardDecoration(),
    child: const Column(
      children: [
        _AllowedRow('Check-in status'),
        _AllowedRow('Schedule information'),
        _AllowedRow('General wellbeing status', last: true),
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
  const _RestrictedInformationCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: _cardDecoration(),
    child: Row(
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
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Private conversation content',
                style: TextStyle(
                  color: ConsentContextReviewScreen._primaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Not accessible',
                style: TextStyle(
                  color: ConsentContextReviewScreen._restricted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
