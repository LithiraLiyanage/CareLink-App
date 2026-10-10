import 'package:flutter/material.dart';

import '../../../app/routes.dart';

/// Static success state shown after an older adult approves a family request.
class FamilyApprovedScreen extends StatelessWidget {
  const FamilyApprovedScreen({super.key});

  static const _ink = Color(0xFF00695C);
  static const _titleInk = Color(0xFF004D40);
  static const _muted = Color(0xFF55706E);
  static const _mint = Color(0xFFF2F9F7);
  static const _line = Color(0xFFD5E5E2);
  static const _coral = Color(0xFFF26F6A);
  static const _success = Color(0xFF00A878);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _mint,
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: _mint,
        surfaceTintColor: Colors.transparent,
        leadingWidth: 64,
        leading: IconButton(
          tooltip: 'Back to pending request',
          onPressed: () => Navigator.of(context).pushReplacementNamed(
            AppRoutes.familyPending,
          ),
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _ink, size: 21),
        ),
        title: const Text(
          'CareLink',
          style: TextStyle(
            color: _ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: Color(0xFFE0F2EF),
              child: Icon(Icons.person_rounded, color: _ink, size: 20),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned(
            top: -48,
            left: -54,
            child: _SoftCircle(size: 172, color: Color(0xFFDFF1ED)),
          ),
          const Positioned(
            top: 50,
            left: 56,
            child: _SoftCircle(size: 38, color: Color(0xFFDFF1ED)),
          ),
          SafeArea(
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: _SuccessMark()),
                      const SizedBox(height: 12),
                      const Text(
                        'Connection Approved!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _titleInk,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'You can now view the information\napproved by the older adult.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _muted,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 19),
                      const _OlderAdultCard(),
                      const SizedBox(height: 13),
                      const _ApprovedInformationCard(),
                      const SizedBox(height: 20),
                      Semantics(
                        button: true,
                        label: 'Go to Dashboard',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => Navigator.of(context)
                                .pushNamed(AppRoutes.familyDashboard),
                            child: Container(
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _coral,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x20E85D5A),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Go to Dashboard',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
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

class _SuccessMark extends StatelessWidget {
  const _SuccessMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        color: Color(0xFFDFF5ED),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 54,
          height: 54,
          decoration: const BoxDecoration(
            color: FamilyApprovedScreen._success,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 33),
        ),
      ),
    );
  }
}

class _OlderAdultCard extends StatelessWidget {
  const _OlderAdultCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FamilyApprovedScreen._line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A00695C),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 27,
            backgroundColor: Color(0xFFE0F2EF),
            child: Icon(Icons.person_rounded,
                size: 31, color: FamilyApprovedScreen._ink),
          ),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mrs. Silva',
                  style: TextStyle(
                    color: FamilyApprovedScreen._titleInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Daughter',
                  style: TextStyle(
                    color: FamilyApprovedScreen._muted,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Connected on 30 Sep 2026',
                  style: TextStyle(color: Color(0xFF829390), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovedInformationCard extends StatelessWidget {
  const _ApprovedInformationCard();

  static const _rows = <(IconData, String)>[
    (Icons.calendar_today_rounded, 'Check-in status'),
    (Icons.access_time_rounded, 'Schedule information'),
    (Icons.favorite_border_rounded, 'General wellbeing status'),
    (Icons.shield_outlined, 'Consent preferences'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FamilyApprovedScreen._line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A00695C),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < _rows.length; i++) ...[
            SizedBox(
              height: 48,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  children: [
                    Icon(_rows[i].$1,
                        color: FamilyApprovedScreen._ink, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _rows[i].$2,
                        style: const TextStyle(
                          color: FamilyApprovedScreen._titleInk,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: FamilyApprovedScreen._muted, size: 22),
                  ],
                ),
              ),
            ),
            if (i < _rows.length - 1)
              const Padding(
                padding: EdgeInsets.only(left: 47),
                child: Divider(height: 1, thickness: 1, color: Color(0xFFEAF1EF)),
              ),
          ],
        ],
      ),
    );
  }
}

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
