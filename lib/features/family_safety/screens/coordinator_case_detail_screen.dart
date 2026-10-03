import 'package:flutter/material.dart';

/// Static detail view for a coordinator safety case.
class CoordinatorCaseDetailScreen extends StatelessWidget {
  const CoordinatorCaseDetailScreen({super.key});

  static const _teal = Color(0xFF00695C);
  static const _darkTeal = Color(0xFF004D40);
  static const _mint = Color(0xFFF2F9F7);
  static const _lightTeal = Color(0xFFE0F2EF);
  static const _secondary = Color(0xFF55706E);
  static const _line = Color(0xFFD5E5E2);
  static const _orange = Color(0xFFF59E0B);
  static const _lightWarning = Color(0xFFFFF4DF);
  static const _success = Color(0xFF00A878);
  static const _lightSuccess = Color(0xFFDFF5ED);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _mint,
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: _mint,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new, color: _teal, size: 21),
        ),
        title: const Text(
          'CareLink',
          style: TextStyle(
            color: _teal,
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
              backgroundColor: _lightTeal,
              child: Icon(Icons.person_rounded, color: _teal, size: 19),
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
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Case #001',
                              style: TextStyle(
                                color: _darkTeal,
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _lightWarning,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Text(
                              'Pending Review',
                              style: TextStyle(
                                color: _orange,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const _ProfileCard(),
                      const SizedBox(height: 12),
                      const _CaseInformationCard(),
                      const SizedBox(height: 17),
                      const Text(
                        'Actions',
                        style: TextStyle(
                          color: _darkTeal,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const _ActionRow(icon: Icons.phone_outlined, label: 'Retry'),
                      const SizedBox(height: 7),
                      const _ActionRow(
                          icon: Icons.calendar_month_outlined, label: 'Reschedule'),
                      const SizedBox(height: 7),
                      const _ActionRow(
                          icon: Icons.shield_outlined, label: 'Review Consent'),
                      const SizedBox(height: 7),
                      _ActionRow(
                        icon: Icons.person_outline,
                        label: 'Contact Approved Person',
                        onTap: () =>
                            Navigator.of(context).pushNamed('/consent-context'),
                      ),
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

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: _cardDecoration(),
        child: const Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: CoordinatorCaseDetailScreen._lightTeal,
              child: Icon(Icons.person_rounded,
                  size: 30, color: CoordinatorCaseDetailScreen._teal),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mrs. Silva',
                      style: TextStyle(
                        color: CoordinatorCaseDetailScreen._darkTeal,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      )),
                  SizedBox(height: 2),
                  Text('Mother',
                      style: TextStyle(
                          color: CoordinatorCaseDetailScreen._secondary,
                          fontSize: 12)),
                  SizedBox(height: 2),
                  Text('Elder ID: EL001',
                      style: TextStyle(
                          color: Color(0xFF829390), fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _CaseInformationCard extends StatelessWidget {
  const _CaseInformationCard();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: _cardDecoration(),
        child: const Column(
          children: [
            _InformationRow(
              icon: Icons.calendar_today_outlined,
              label: 'Scheduled Time',
              value: '30 Sep 2026, 10:30 AM',
            ),
            _InformationRow(
              icon: Icons.error_outline_rounded,
              label: 'Status',
              value: 'Missed Check-in',
              valueColor: CoordinatorCaseDetailScreen._orange,
              indicatorColor: CoordinatorCaseDetailScreen._orange,
            ),
            _InformationRow(
              icon: Icons.phone_outlined,
              label: 'Previous Attempts',
              value: '1 attempt',
            ),
            _InformationRow(
              icon: Icons.shield_outlined,
              label: 'Consent',
              value: 'Approved family contact',
              valueColor: CoordinatorCaseDetailScreen._success,
              indicatorColor: CoordinatorCaseDetailScreen._success,
              last: true,
            ),
          ],
        ),
      );
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
        constraints: const BoxConstraints(minHeight: 47),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(
                  bottom: BorderSide(color: Color(0xFFEAF1EF)),
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
  const _ActionRow({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: CoordinatorCaseDetailScreen._line),
        ),
        child: Row(
          children: [
            Icon(icon, size: 21, color: CoordinatorCaseDetailScreen._teal),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: CoordinatorCaseDetailScreen._darkTeal,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              tooltip: onTap == null ? null : 'Open',
              onPressed: onTap,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              icon: const Icon(Icons.chevron_right_rounded, size: 20),
              color: CoordinatorCaseDetailScreen._teal,
              disabledColor: CoordinatorCaseDetailScreen._teal,
            ),
          ],
        ),
      );
}

BoxDecoration _cardDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: CoordinatorCaseDetailScreen._line),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0800695C),
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
          color: Color(0xFFDFF1ED),
          shape: BoxShape.circle,
        ),
      );
}
