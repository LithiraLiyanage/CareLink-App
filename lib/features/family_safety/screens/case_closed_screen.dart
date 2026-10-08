import 'package:flutter/material.dart';

import '../../../app/routes.dart';

/// Static coordinator view confirming a safety case has been closed, with
/// the audit timeline of actions taken.
class CaseClosedScreen extends StatelessWidget {
  const CaseClosedScreen({super.key});

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

  static const _events = [
    ('10:30 AM', 'Check-in missed'),
    ('10:35 AM', 'Coordinator reviewed case'),
    ('10:40 AM', 'Consent checked'),
    ('10:45 AM', 'Approved contact contacted'),
    ('10:55 AM', 'Case closed'),
  ];

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
                      const Center(child: _SuccessBadge()),
                      const SizedBox(height: 14),
                      const Text(
                        'Case Closed',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _darkTeal,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'This safety case has been successfully closed.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _secondary,
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const _CaseCard(),
                      const SizedBox(height: 20),
                      const Text(
                        'Audit Timeline',
                        style: TextStyle(
                          color: _darkTeal,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (var i = 0; i < _events.length; i++)
                        _TimelineEntry(
                          time: _events[i].$1,
                          event: _events[i].$2,
                          isFirst: i == 0,
                          isLast: i == _events.length - 1,
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
}

class _SuccessBadge extends StatelessWidget {
  const _SuccessBadge();

  @override
  Widget build(BuildContext context) => Container(
        width: 74,
        height: 74,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: CaseClosedScreen._lightSuccess,
          shape: BoxShape.circle,
        ),
        child: Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: CaseClosedScreen._success,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 30),
        ),
      );
}

class _CaseCard extends StatelessWidget {
  const _CaseCard();

  @override
  Widget build(BuildContext context) => Container(
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
        child: const Row(
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: CaseClosedScreen._lightTeal,
              child: Icon(Icons.person_rounded,
                  size: 27, color: CaseClosedScreen._teal),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mrs. Silva',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: CaseClosedScreen._darkTeal,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Mother',
                    style: TextStyle(
                      color: CaseClosedScreen._secondary,
                      fontSize: 11,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Case #001',
                    style: TextStyle(
                      color: CaseClosedScreen._muted,
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

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.time,
    required this.event,
    required this.isFirst,
    required this.isLast,
  });

  final String time;
  final String event;
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
            width: 58,
            child: Padding(
              padding: const EdgeInsets.only(top: 1.5),
              child: Text(
                time,
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
              child: Text(
                event,
                style: TextStyle(
                  color: CaseClosedScreen._darkTeal,
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: isLast ? FontWeight.w700 : FontWeight.w500,
                ),
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
