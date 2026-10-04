import 'package:flutter/material.dart';

/// Static coordinator view for contacting the elder's approved person
/// after a missed check-in.
class ApprovedContactActionScreen extends StatelessWidget {
  const ApprovedContactActionScreen({super.key});

  static const _teal = Color(0xFF00695C);
  static const _darkTeal = Color(0xFF004D40);
  static const _mint = Color(0xFFF2F9F7);
  static const _lightTeal = Color(0xFFE0F2EF);
  static const _primaryText = Color(0xFF123B3A);
  static const _secondary = Color(0xFF55706E);
  static const _muted = Color(0xFF829390);
  static const _line = Color(0xFFD5E5E2);
  static const _success = Color(0xFF00A878);
  static const _lightSuccess = Color(0xFFDFF5ED);
  static const _warning = Color(0xFFF59E0B);
  static const _lightWarning = Color(0xFFFFF4DF);
  static const _info = Color(0xFF2196F3);
  static const _lightInfo = Color(0xFFE8F3FF);
  static const _infoText = Color(0xFF345B70);

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
                child: const SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(18, 6, 18, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Approved Contact',
                        style: TextStyle(
                          color: _darkTeal,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Contact the approved person for follow-up.',
                        style: TextStyle(color: _secondary, fontSize: 12),
                      ),
                      SizedBox(height: 12),
                      _ContactCard(),
                      SizedBox(height: 16),
                      _ReasonCard(),
                      SizedBox(height: 16),
                      _ActionRow(
                        icon: Icons.phone_outlined,
                        label: 'Call Contact',
                      ),
                      SizedBox(height: 7),
                      _ActionRow(
                        icon: Icons.chat_bubble_outline,
                        label: 'Send Message',
                      ),
                      SizedBox(height: 7),
                      _ActionRow(
                        icon: Icons.check_circle_outline,
                        label: 'Mark Follow-up Complete',
                      ),
                      SizedBox(height: 16),
                      _InfoNote(),
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

class _ContactCard extends StatelessWidget {
  const _ContactCard();

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => Navigator.of(context).pushNamed('/case-outcome'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: _cardDecoration(),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: ApprovedContactActionScreen._lightTeal,
                child: Icon(Icons.person_rounded,
                    size: 27, color: ApprovedContactActionScreen._teal),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jane Silva',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ApprovedContactActionScreen._darkTeal,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Daughter',
                      style: TextStyle(
                        color: ApprovedContactActionScreen._secondary,
                        fontSize: 11,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '+94 77 123 4567',
                      style: TextStyle(
                        color: ApprovedContactActionScreen._muted,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              _ApprovedChip(),
            ],
          ),
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
  const _ReasonCard();

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
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline,
                      size: 20, color: ApprovedContactActionScreen._warning),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Missed Check-in',
                          style: TextStyle(
                            color: ApprovedContactActionScreen._darkTeal,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          "Mrs. Silva's scheduled check-in\nwas not completed.",
                          style: TextStyle(
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

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: ApprovedContactActionScreen._line),
        ),
        child: Row(
          children: [
            Icon(icon, size: 21, color: ApprovedContactActionScreen._teal),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ApprovedContactActionScreen._primaryText,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right,
                size: 19, color: ApprovedContactActionScreen._secondary),
          ],
        ),
      );
}

class _InfoNote extends StatelessWidget {
  const _InfoNote();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: ApprovedContactActionScreen._lightInfo,
          borderRadius: BorderRadius.circular(11),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline,
                size: 18, color: ApprovedContactActionScreen._info),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                'Only contact the person approved by the\nolder adult.',
                style: TextStyle(
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
